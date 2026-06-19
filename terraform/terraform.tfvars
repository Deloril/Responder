#########################
## Terraform Variables ##
#########################

## AWS Provider
region = "ap-southeast-2"
# AWS profile is read from $AWS_PROFILE (set in .env). aws_account_id and
# kms_key_id come from TF_VAR_aws_account_id / TF_VAR_kms_key_id in .env.

## Project
project_name                           = "project-responder"
builder_project_name                   = "project-responder"
windows_ansible_inventory_file         = "../ansible/windows/inventory/windows_ansible_inventory_file"
linux_bastion_ansible_inventory_file   = "../ansible/ansible-bastion-prereq/inventory/linux_bastion_ansible_inventory_file"
windows_bastion_ansible_inventory_file = "../ansible/windows-bastion/inventory/windows_bastion_ansible_inventory_file"
attacker_ansible_inventory_file        = "../ansible/attack/inventory/attacker_ansible_inventory_file"
linux_ansible_inventory_file           = "../ansible/linux/inventory/linux_ansible_inventory_file"
bastion_server_details                 = "../inventory/bastion_server_details"
attack_server_details                  = "../inventory/attack_server_details"
victim_infra_details                   = "../inventory/victim_infra_details"
win_rsa_public_key_file                = "./certs/project-responder-windows.pub"
ssh_public_key_file                    = "./certs/project-responder-ssh.pub"
win_rsa_private_key_file               = "./certs/project-responder-windows"
ssh_private_key_file                   = "./certs/project-responder-ssh"


#############
## Modules ##
#############

## Core
vpc_cidr = "10.0.0.0/16"
# Inbound access: terraform auto-detects the caller's public IP at apply time.
# Add extra CIDRs (teammates, corp VPN) via TF_VAR_extra_trusted_networks in
# .env (see .env.example) so the allowlist isn't committed to source control.

## Public
public_subnet_cidr         = "10.0.0.0/24"
web_server_instance_type   = "t3.small"
web_server_private_ip      = "10.0.0.6"
web_server_domain_hostname = "web"
mail_server_ami_owner      = "099720109477"                                           # Canonical
mail_server_ami_name       = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server*" # Ubuntu 22.04
mail_server_instance_type  = "t3.small"
mail_server_private_ip     = "10.0.0.7"
mail_server_hostname       = "mail"
firewall_instance_type     = "t3.micro"
firewall_private_ip        = "10.0.0.5"

## Corp
corp_subnet_cidr = "10.0.1.0/24"
DC_ami_owner     = "801119661308"                           # Microsoft
DC_ami_name      = "Windows_Server-2016-English-Full-Base*" # 2016 Server Base
# client_ami_owner intentionally unset; defaults to var.aws_account_id (.env)
# because the custom Windows AMI is built in the same account that runs the lab.
# Override via TF_VAR_client_ami_owner if your AMI lives elsewhere.
#client_ami_name = "project-responder-win10Pro-1" # # Project:Responder Windows 10 ami (NEW)
client_ami_name          = "project-responder-win10Pro-20230904_2" # # Project:Responder Windows 10 ami (NEW)
DC_instance_type         = "t3.large"
DC_private_ip            = "10.0.1.6"
DC_hostname              = "DC01"
client_instance_type     = "t3.large"
client_1_private_ip      = "10.0.1.10"
client_1_domain_hostname = "client-1"
client_2_private_ip      = "10.0.1.11"
client_2_domain_hostname = "client-2"
client_3_private_ip      = "10.0.1.12"
client_3_domain_hostname = "client-3"

## Super Secret (secret storage / vault network)
super_secret_subnet_cidr  = "10.0.2.0/24"
file_server_ami_owner     = "801119661308"                           # Microsoft
file_server_ami_name      = "Windows_Server-2016-English-Full-Base*" # 2016 Server Base
sql_server_ami_owner      = "801119661308"                           # Microsoft
sql_server_ami_name       = "Windows_Server-2016-English-Full-Base*" # 2016 Server Base
file_server_instance_type = "t3.large"
file_server_private_ip    = "10.0.2.6"
file_server_hostname      = "file"
sql_server_instance_type  = "t3.large"
sql_server_private_ip     = "10.0.2.7"
sql_server_hostname       = "sql"

## Inner Firewalls (DMZ<->Corp, Corp<->Secret) -- Linux NVAs with iptables
fw_inner_ami_owner       = "099720109477"                                           # Canonical
fw_inner_ami_name        = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server*" # Ubuntu 22.04
fw_inner_instance_type   = "t3.small"
fw_dmz_corp_dmz_ip       = "10.0.0.250" # DMZ-side ENI
fw_dmz_corp_corp_ip      = "10.0.1.250" # corp-side ENI
fw_corp_secret_corp_ip   = "10.0.1.251" # corp-side ENI
fw_corp_secret_secret_ip = "10.0.2.250" # secret-side ENI
fw_dmz_corp_hostname     = "fw-dmz-corp"
fw_corp_secret_hostname  = "fw-corp-secret"

## Privileged Access (PAW) tier -- only path to file/sql, accessed via Guacamole
paw_subnet_cidr       = "10.0.4.0/24"
paw_1_private_ip      = "10.0.4.10"
paw_1_domain_hostname = "paw-1"
paw_2_private_ip      = "10.0.4.11"
paw_2_domain_hostname = "paw-2"
paw_instance_type     = "t3.large"
guac_private_ip       = "10.0.4.6"
guac_hostname         = "guac"
guac_ami_owner        = "099720109477"                                           # Canonical
guac_ami_name         = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server*" # Ubuntu 22.04
guac_instance_type    = "t3.medium"

## SecOps
secops_subnet_cidr                   = "10.0.3.0/24"
windows_bastion_server_ami_owner     = "801119661308"                           # Microsoft
windows_bastion_server_ami_name      = "Windows_Server-2016-English-Full-Base*" # 2016 Server Base
windows_bastion_server_instance_type = "t3.medium"
windows_bastion_server_private_ip    = "10.0.3.7"
linux_bastion_server_ami_owner       = "099720109477"                                           # Canonical
linux_bastion_server_ami_name        = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server*" # Ubuntu 22.04
linux_bastion_server_instance_type   = "t3.medium"
linux_bastion_server_private_ip      = "10.0.3.8"

## Attacker
attacker_vpc_cidr             = "10.0.0.0/16"
attacker_subnet_cidr          = "10.0.0.0/24"
attacker_server_ami_owner     = "099720109477"                                           # Canonical
attacker_server_ami_name      = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server*" # Ubuntu 22.04
attacker_server_instance_type = "t3.medium"
