#!/bin/bash
#
# Print bastion, attack server, VNC targets, domain creds, and quick-start attack script names.
# Invoked at the end of Makefile build/re-build targets.
#
REGION="${1:?Usage: $0 <region>}"

BASTION_FILE="inventory/bastion_server_details_${REGION}"
ATTACK_FILE="inventory/attack_server_details_${REGION}"
VICTIM_FILE="inventory/victim_infra_details_${REGION}"
SSH_KEY="terraform/certs/project-responder-ssh"

# Extract values from inventory files
WIN_BASTION_IP=$(awk '/^Windows Bastion Public IP:/ { print $5 }' "${BASTION_FILE}" 2>/dev/null)
WIN_BASTION_DNS=$(awk '/^Windows Bastion Public DNS:/ { print $5 }' "${BASTION_FILE}" 2>/dev/null)
WIN_BASTION_USER=$(awk '/^Windows Bastion User:/ { print $4 }' "${BASTION_FILE}" 2>/dev/null)
WIN_BASTION_PASS=$(awk '/^Windows Bastion Password:/ { $1=$2=$3=""; print substr($0,4) }' "${BASTION_FILE}" 2>/dev/null)
LIN_BASTION_IP=$(awk '/^Linux Bastion Public IP:/ { print $5 }' "${BASTION_FILE}" 2>/dev/null)
ATTACK_IP=$(awk '/^Linux Bastion Public IP:/ { print $5 }' "${ATTACK_FILE}" 2>/dev/null)
FIREWALL_EIP=$(awk '/^Firewall EIP:/ { print $3 }' "${ATTACK_FILE}" 2>/dev/null)

cat <<EOF

╔══════════════════════════════════════════════════════════════╗
║              ENVIRONMENT READY: ${REGION}
╚══════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────┐
│  BASTION ACCESS                                             │
├─────────────────────────────────────────────────────────────┤
│  Windows Bastion (RDP):                                     │
│    Host:     ${WIN_BASTION_IP:-N/A}
│    DNS:      ${WIN_BASTION_DNS:-N/A}
│    User:     ${WIN_BASTION_USER:-Administrator}
│    Password: ${WIN_BASTION_PASS:-see inventory file}
│                                                             │
│  Linux Bastion (SSH):                                       │
│    ssh -i ${SSH_KEY} ubuntu@${LIN_BASTION_IP:-N/A}
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  ATTACK SERVER                                              │
├─────────────────────────────────────────────────────────────┤
│    ssh -i ${SSH_KEY} ubuntu@${ATTACK_IP:-N/A}
│    Firewall EIP:  ${FIREWALL_EIP:-N/A}
│    Web Portal:    http://${FIREWALL_EIP:-N/A}
│    Mail (SMTP):   ${FIREWALL_EIP:-N/A}:25
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  VNC ACCESS (from bastion, non-disruptive)                  │
├─────────────────────────────────────────────────────────────┤
│    Password:  tsg_vnc_2025                                  │
│    Port:      5900                                          │
│    Targets:   10.0.1.6  (DC)                                │
│               10.0.1.10 (Client-1, auto-login: ben)         │
│               10.0.1.11 (Client-2, auto-login: kate)        │
│               10.0.1.12 (Client-3, auto-login: sam.hewitt)  │
│               10.0.2.6  (File Server)                       │
│               10.0.2.7  (SQL Server)                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  DOMAIN CREDENTIALS                                         │
├─────────────────────────────────────────────────────────────┤
│    Domain:         TSG-INTERNAL.LAB                          │
│    Domain Admin:   TSG-INTERNAL\\Administrator / tsgInt3rnal  │
│    ben (Client-1): TSG-INTERNAL\\ben / Kia0ra2025!           │
│    kate (Client-2):TSG-INTERNAL\\kate / Wellington#1         │
│    sam.hewitt (Client-3):TSG-INTERNAL\\sam.hewitt / DevOps2025!│
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  QUICK START                                                │
├─────────────────────────────────────────────────────────────┤
│  1. RDP to Windows Bastion, then VNC to 10.0.1.10:5900      │
│  2. (Optional) Install C2 stacks on attack server:         │
│     ./scripts/attack_server_install_all_c2_tools.sh ${REGION}│
│  3. Direct HTTP payload:                                    │
│     ./scripts/attack_serve_c2_payload_over_http.sh ${REGION}│
│  4. Web+email phish chain:                                  │
│     ./scripts/attack_serve_c2_payload_for_web_phishing.sh ${REGION}│
│  5. Upload exe to web /uploads/:                           │
│     ./scripts/attack_upload_c2_payload_to_corporate_web.sh ${REGION}│
│  6. VS Code fake-update scenario:                           │
│     ./scripts/attack_scenario_vscode_fake_extension_update.sh ${REGION}│
│  C2: C2_FRAMEWORK=metasploit|sliver|mythic|havoc            │
│      (see scripts/attack_c2_helpers/README.txt)            │
└─────────────────────────────────────────────────────────────┘

EOF
