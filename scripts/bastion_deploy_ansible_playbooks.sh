#!/bin/bash
# Copy Ansible trees to the Linux bastion and run all victim-environment playbooks
# (Windows DC/members, web, mail, firewall, optional Linux). Replaces manual scp + ansible steps.
set -euo pipefail

REGION="${1:?Usage: $0 <region> [--with-linux]}"
WITH_LINUX=false
[[ "${2:-}" == "--with-linux" ]] && WITH_LINUX=true

SSH_KEY="terraform/certs/project-responder-ssh"
SSH_OPTS="-i ${SSH_KEY} -o StrictHostKeyChecking=no"

BASTION_IP=$(awk '/^Linux Bastion Public IP:/ { print $5 }' "inventory/bastion_server_details_${REGION}")
if [ -z "${BASTION_IP}" ]; then
    echo "[!] Could not extract bastion IP from inventory/bastion_server_details_${REGION}"
    exit 1
fi

FAILED=0
wait_or_fail() {
    local pid=$1 label=$2
    if ! wait "$pid"; then
        echo "[!] FAILED: ${label}"
        FAILED=1
    else
        echo "[+] Done: ${label}"
    fi
}

echo "========================================"
echo "  Deploying region: ${REGION}"
echo "  Bastion: ${BASTION_IP}"
echo "========================================"

# -------------------------------------------------------
# Phase 1: Install prereqs on bastion + attack tools (parallel)
# These target different servers and have zero dependencies.
# -------------------------------------------------------
echo ""
echo "[*] Phase 1: Bastion prereqs + attack tools (parallel)..."

ANSIBLE_CONFIG=ansible/ansible.cfg ANSIBLE_HOST_KEY_CHECKING=False \
    ansible-playbook \
    -i "ansible/ansible-bastion-prereq/inventory/linux_bastion_ansible_inventory_file_${REGION}" \
    ansible/ansible-bastion-prereq/install_ansible-prereqs.yml &
PID_BASTION=$!

ANSIBLE_CONFIG=ansible/ansible.cfg ANSIBLE_HOST_KEY_CHECKING=False \
    ansible-playbook \
    -i "ansible/attack/inventory/attacker_ansible_inventory_file_${REGION}" \
    ansible/attack/install_attack_tools.yml &
PID_ATTACK=$!

wait_or_fail $PID_BASTION "bastion prereqs"
wait_or_fail $PID_ATTACK  "attack tools"
[ $FAILED -ne 0 ] && { echo "[!] Phase 1 had failures, aborting."; exit 1; }

# -------------------------------------------------------
# Phase 2: SCP playbooks + pre-stage shared downloads on bastion
# -------------------------------------------------------
echo ""
echo "[*] Phase 2: Uploading playbooks to bastion..."

SCP_SOURCES="ansible/windows-bastion/ ansible/windows/ ansible/mail/ ansible/firewall/ ansible/inner-firewalls/ ansible/guacamole/ ansible/webserver/ ansible/common/ scripts/attack_c2_helpers/ ${SSH_KEY}"
if $WITH_LINUX; then
    SCP_SOURCES="${SCP_SOURCES} ansible/linux"
fi

scp ${SSH_OPTS} -r ${SCP_SOURCES} "ubuntu@${BASTION_IP}:"

echo "[*] Phase 2b: Pre-staging shared downloads on bastion..."
ssh ${SSH_OPTS} "ubuntu@${BASTION_IP}" bash -s <<'PRESTAGE'
set -e
mkdir -p ~/deploy_cache
cd ~/deploy_cache

if [ ! -f SysinternalsSuite.zip ]; then
    echo "[*] Downloading SysinternalsSuite.zip..."
    wget -q -O SysinternalsSuite.zip https://download.sysinternals.com/files/SysinternalsSuite.zip
fi
if [ ! -f tightvnc.msi ]; then
    echo "[*] Downloading TightVNC MSI..."
    wget -q -O tightvnc.msi https://www.tightvnc.com/download/2.8.85/tightvnc-2.8.85-gpl-setup-64bit.msi
fi

# Kill any existing cache server
fuser -k 8888/tcp 2>/dev/null || true
nohup python3 -m http.server 8888 > /tmp/deploy_cache_http.log 2>&1 &
echo "[+] Download cache HTTP server started on :8888 (PID: $!)"
PRESTAGE

echo "[+] Phase 2 complete."

# -------------------------------------------------------
# Phase 3: Run everything from the bastion with max parallelism
# -------------------------------------------------------
echo ""
echo "[*] Phase 3: Running playbooks from bastion..."

LINUX_BLOCK=""
if $WITH_LINUX; then
    LINUX_BLOCK='
echo "[$$] Starting linux build..."
ansible-playbook -i linux/inventory/linux_ansible_inventory_file_'"${REGION}"' linux/linux_build_env.yml \
    > /tmp/deploy_linux.log 2>&1 &
BG_PIDS="$BG_PIDS $!"
BG_LABELS="$BG_LABELS linux_build"
BG_LOGS="$BG_LOGS /tmp/deploy_linux.log"
'
fi

ssh ${SSH_OPTS} "ubuntu@${BASTION_IP}" bash -s <<REMOTE
set -eo pipefail

REGION="${REGION}"
WIN_INV="windows/inventory/windows_ansible_inventory_file_\${REGION}"
MAIL_INV="mail/inventory/mail_server_ansible_inventory_file_\${REGION}"
FW_INV="firewall/inventory/firewall_ansible_inventory_file_\${REGION}"
INNER_FW_INV="inner-firewalls/inventory/inner_firewalls_inventory_file_\${REGION}"
GUAC_INV="guacamole/inventory/guacamole_inventory_file_\${REGION}"
WEB_INV="webserver/inventory/web_server_ansible_inventory_file_\${REGION}"
BAST_INV="windows-bastion/inventory/windows_bastion_ansible_inventory_file_\${REGION}"

FAILED=0
BG_PIDS=""
BG_LABELS=""
BG_LOGS=""

check_result() {
    local pid=\$1 label=\$2 logfile=\$3
    if ! wait \$pid; then
        echo "[!] FAILED: \${label} (log: \${logfile})"
        echo "--- last 30 lines of \${logfile} ---"
        tail -30 "\${logfile}" 2>/dev/null || true
        echo "---"
        FAILED=1
    else
        echo "[+] Done: \${label}"
    fi
}

# --- Independent jobs: background immediately ---

echo "[\$\$] Starting windows bastion config..."
ansible-playbook -i \$BAST_INV windows-bastion/configure_windows_bastion.yml \
    > /tmp/deploy_wbastion.log 2>&1 &
BG_PIDS="\$BG_PIDS \$!"
BG_LABELS="\$BG_LABELS windows_bastion"
BG_LOGS="\$BG_LOGS /tmp/deploy_wbastion.log"

echo "[\$\$] Starting mail server setup..."
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i \$MAIL_INV mail/install_mail_server.yml \
    > /tmp/deploy_mail.log 2>&1 &
BG_PIDS="\$BG_PIDS \$!"
BG_LABELS="\$BG_LABELS mail_server"
BG_LOGS="\$BG_LOGS /tmp/deploy_mail.log"

echo "[\$\$] Starting firewall/router setup..."
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i \$FW_INV firewall/configure_firewall.yml \
    > /tmp/deploy_firewall.log 2>&1 &
BG_PIDS="\$BG_PIDS \$!"
BG_LABELS="\$BG_LABELS firewall"
BG_LOGS="\$BG_LOGS /tmp/deploy_firewall.log"

echo "[\$\$] Starting web server setup..."
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i \$WEB_INV webserver/configure_web_server.yml \
    > /tmp/deploy_webserver.log 2>&1 &
BG_PIDS="\$BG_PIDS \$!"
BG_LABELS="\$BG_LABELS web_server"
BG_LOGS="\$BG_LOGS /tmp/deploy_webserver.log"

echo "[\$\$] Starting inner firewalls (DMZ-corp + corp-secret) setup..."
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i \$INNER_FW_INV inner-firewalls/configure_inner_firewalls.yml \
    > /tmp/deploy_inner_fw.log 2>&1 &
BG_PIDS="\$BG_PIDS \$!"
BG_LABELS="\$BG_LABELS inner_firewalls"
BG_LOGS="\$BG_LOGS /tmp/deploy_inner_fw.log"

echo "[\$\$] Starting Guacamole gateway setup..."
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i \$GUAC_INV guacamole/install_guacamole.yml \
    > /tmp/deploy_guac.log 2>&1 &
BG_PIDS="\$BG_PIDS \$!"
BG_LABELS="\$BG_LABELS guacamole"
BG_LOGS="\$BG_LOGS /tmp/deploy_guac.log"

${LINUX_BLOCK}

# --- Overlap: member server common setup runs while DC builds ---

echo "[\$\$] Starting member server common setup (parallel with DC)..."
ansible-playbook -i \$WIN_INV windows/windows_ms_common.yml \
    > /tmp/deploy_ms_common.log 2>&1 &
PID_MS_COMMON=\$!

echo "[\$\$] Windows Phase A: Domain controller setup..."
ansible-playbook -i \$WIN_INV windows/windows_dc.yml

# Wait for member server common setup before domain join
echo "[\$\$] Waiting for member server common setup to finish..."
check_result \$PID_MS_COMMON "ms common setup" /tmp/deploy_ms_common.log

echo "[\$\$] Windows Phase B: Domain join (member servers, common already done)..."
ansible-playbook -i \$WIN_INV windows/windows_ms_domain_join.yml

# Kick off SQL media prefetch while Phase C file/client tasks start
echo "[\$\$] Starting SQL media prefetch in background..."
ansible-playbook -i \$WIN_INV windows/windows_sql_prefetch.yml \
    > /tmp/deploy_sql_prefetch.log 2>&1 &
PID_SQL_PREFETCH=\$!

echo "[\$\$] Windows Phase C: Host-specific playbooks (file + client + paw in parallel, SQL after prefetch)..."
ansible-playbook -i \$WIN_INV windows/windows_file_server.yml   > /tmp/deploy_file.log   2>&1 &
PID_FILE=\$!
ansible-playbook -i \$WIN_INV windows/windows_client_setup.yml  > /tmp/deploy_client.log 2>&1 &
PID_CLIENT=\$!
ansible-playbook -i \$WIN_INV windows/windows_paw_setup.yml     > /tmp/deploy_paw.log    2>&1 &
PID_PAW=\$!

# Wait for SQL prefetch, then start SQL server install
check_result \$PID_SQL_PREFETCH "sql prefetch" /tmp/deploy_sql_prefetch.log
ansible-playbook -i \$WIN_INV windows/windows_sql_server.yml    > /tmp/deploy_sql.log    2>&1 &
PID_SQL=\$!

check_result \$PID_FILE   "file server"   /tmp/deploy_file.log
check_result \$PID_CLIENT "client setup"  /tmp/deploy_client.log
check_result \$PID_PAW    "paw setup"     /tmp/deploy_paw.log
check_result \$PID_SQL    "sql server"    /tmp/deploy_sql.log

echo "[\$\$] Windows Phase D: Finalize..."
ansible-playbook -i \$WIN_INV windows/windows_finalize.yml

# --- Wait for all independent background jobs ---

echo "[\$\$] Waiting for background jobs..."
set -- \$BG_PIDS
set +e
IDX=0
LABEL_ARR=(\$BG_LABELS)
LOG_ARR=(\$BG_LOGS)
for PID in "\$@"; do
    check_result \$PID "\${LABEL_ARR[\$IDX]}" "\${LOG_ARR[\$IDX]}"
    IDX=\$((IDX + 1))
done
set -e

# Clean up download cache server
fuser -k 8888/tcp 2>/dev/null || true

if [ \$FAILED -ne 0 ]; then
    echo ""
    echo "[!] Some playbooks failed. Logs are on the bastion in /tmp/deploy_*.log"
    exit 1
fi

echo ""
echo "[+] All playbooks completed successfully."
REMOTE

echo ""
echo "========================================"
echo "  Deployment complete: ${REGION}"
echo "========================================"
