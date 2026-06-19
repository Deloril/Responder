#!/bin/bash
#
# Install / prepare C2 tooling on the Linux attack server (Metasploit, Sliver,
# Mythic clone + Docker, Havoc clone). Run from repo root after terraform apply.
#
# Note: ansible/attack/install_attack_tools.yml runs the same install during
# `make ansible-<region>`, so this script is normally only needed for re-runs
# or after a manual taint of the attacker box.
#
# Usage: ./scripts/attack_server_install_all_c2_tools.sh <region>
#
# Optional env (on your laptop before running):
#   SKIP_SLIVER=1      Skip Sliver omnibus install
#   SKIP_MYTHIC=1       Skip Docker + Mythic git clone
#   SKIP_HAVOC=1        Skip Havoc git clone
#   SKIP_METASPLOIT=1   Skip Metasploit installer (if already present)
#
set -euo pipefail

REGION="${1:?Usage: $0 <region> (e.g. apac, amer)}"
SSH_KEY="terraform/certs/project-responder-ssh"
ATTACK_USER="ubuntu"
DETAILS="inventory/attack_server_details_${REGION}"

if [[ ! -f "${DETAILS}" ]]; then
  echo "[!] Missing ${DETAILS}"
  exit 1
fi

ATTACK_IP=$(awk '/^Linux Bastion Public IP:/ { print $5 }' "${DETAILS}")
if [[ -z "${ATTACK_IP}" ]]; then
  echo "[!] Could not read attack server IP from ${DETAILS}"
  exit 1
fi

SSH_OPTS="-i ${SSH_KEY} -o StrictHostKeyChecking=no"

echo "[*] Region:        ${REGION}"
echo "[*] Attack server: ${ATTACK_IP}"
echo "[*] Installing C2 stacks (this can take several minutes)..."

ssh ${SSH_OPTS} "${ATTACK_USER}@${ATTACK_IP}" bash -s <<'REMOTE'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "[*] apt update + base packages..."
sudo apt-get update -qq
sudo apt-get install -y \
  curl wget git jq tmux zip unzip nmap swaks \
  build-essential cmake pkg-config python3 python3-pip \
  docker.io docker-compose-plugin \
  golang-go nodejs npm \
  mingw-w64 \
  || true

if getent group docker >/dev/null 2>&1; then
  sudo usermod -aG docker "${USER}" || true
  echo "[+] User added to docker group (re-login may be required for docker without sudo)."
fi

if [[ "${SKIP_METASPLOIT:-0}" != "1" ]]; then
  if command -v msfvenom >/dev/null 2>&1; then
    echo "[+] Metasploit already present: $(command -v msfvenom)"
  else
    echo "[*] Installing Metasploit Framework (omnibus)..."
    curl -fsSL -o /tmp/msfinstall \
      https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb
    chmod +x /tmp/msfinstall
    sudo /tmp/msfinstall || { echo "[!] Metasploit install failed"; }
  fi
else
  echo "[*] SKIP_METASPLOIT=1 — skipping Metasploit"
fi

if [[ "${SKIP_SLIVER:-0}" != "1" ]]; then
  if command -v sliver-client >/dev/null 2>&1; then
    echo "[+] sliver-client already present"
  else
    echo "[*] Installing Sliver (https://sliver.sh/install)..."
    curl -fsSL https://sliver.sh/install | sudo bash || echo "[!] Sliver install failed — install manually from https://github.com/BishopFox/sliver"
  fi
else
  echo "[*] SKIP_SLIVER=1 — skipping Sliver"
fi

if [[ "${SKIP_MYTHIC:-0}" != "1" ]]; then
  echo "[*] Preparing Mythic (Docker + repo clone; full install still uses mythic-cli interactively)..."
  sudo systemctl enable docker 2>/dev/null || true
  sudo systemctl start docker 2>/dev/null || true
  if [[ ! -d /opt/Mythic ]]; then
    sudo git clone --depth 1 https://github.com/its-a-feature/Mythic.git /opt/Mythic || echo "[!] Mythic clone failed"
  else
    echo "[+] /opt/Mythic already exists"
  fi
  echo "[i] Finish Mythic on this host:  cd /opt/Mythic && sudo ./mythic-cli install (see Mythic docs for Docker-based install)."
else
  echo "[*] SKIP_MYTHIC=1 — skipping Mythic"
fi

if [[ "${SKIP_HAVOC:-0}" != "1" ]]; then
  if [[ ! -d /opt/Havoc ]]; then
    echo "[*] Cloning Havoc C2 framework source..."
    sudo git clone --depth 1 https://github.com/HavocFramework/Havoc.git /opt/Havoc || echo "[!] Havoc clone failed"
  else
    echo "[+] /opt/Havoc already exists"
  fi
  echo "[i] Build Havoc per upstream docs (Go + Node client):  cd /opt/Havoc && cat README.md"
else
  echo "[*] SKIP_HAVOC=1 — skipping Havoc"
fi

echo ""
echo "============================================"
echo "  C2 tooling pass complete"
echo "============================================"
command -v msfvenom >/dev/null && msfvenom -h >/dev/null 2>&1 && echo "[+] msfvenom: OK" || echo "[-] msfvenom: missing"
command -v sliver-client >/dev/null && echo "[+] sliver-client: OK" || echo "[-] sliver-client: missing (or use external payload)"
command -v docker >/dev/null && echo "[+] docker: OK" || echo "[-] docker: missing"
[[ -d /opt/Mythic ]] && echo "[+] Mythic repo: /opt/Mythic" || echo "[-] Mythic repo missing"
[[ -d /opt/Havoc ]] && echo "[+] Havoc repo: /opt/Havoc" || echo "[-] Havoc repo missing"
REMOTE

echo ""
echo "[+] Done. Re-SSH to the attack box if docker group was added. Then run attack_* scripts as usual."
