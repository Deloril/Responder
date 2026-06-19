###################################
## Terraform Core / AWS Provider ##
###################################

variable "region" {
  description = "AWS region to deploy all terraform-managed resources"
}

# AWS credential profile selection is now read directly from $AWS_PROFILE
# (exported by .env). The terraform `aws_credential_profile` variable was
# removed because terraform never actually consumed it — it was only used in
# Makefile invocations of the AWS CLI.

variable "aws_account_id" {
  description = "AWS account ID that owns the deployment (custom AMIs, KMS key, S3 backend). Provide via TF_VAR_aws_account_id (see .env.example)."
  type        = string
}

variable "kms_key_id" {
  description = "KMS multi-region key ID (the part after 'key/' in the ARN) used to encrypt EBS volumes. Provide via TF_VAR_kms_key_id (see .env.example)."
  type        = string
}

## Project/Deployment
variable "project_name" {
  description = "Name of project. All resources will be tagged as '<resource_name>-<project_name>."
}

variable "builder_project_name" {
  description = "Name of builder project for use in data resources"
}

variable "workspace_mapping" {
  description = "Used for mapping a name to a workspace. Three workspaces exist apac, emea, amer in the backend state."
  default = {
    "apac"     = "ap-southeast-2", # Sydney
    "emea"     = "eu-west-1",      # Dublin
    "amer"     = "us-east-1",      # North Virginia
    "test-env" = "ap-southeast-1", # Singapore
    "star"     = "ap-south-1"      # Mumbai
  }
}

variable "windows_ansible_inventory_file" {
  description = "location to write the windows ansible inventory file"
}

variable "linux_bastion_ansible_inventory_file" {
  description = "location to write the bastion ansible inventory file"
}

variable "windows_bastion_ansible_inventory_file" {
  description = "location to write the bastion ansible inventory file"
}

variable "attacker_ansible_inventory_file" {
  description = "location to write the attacker server ansible inventory file"
}

variable "linux_ansible_inventory_file" {
  description = "location to write the linux server ansible inventory file"
}

variable "victim_infra_details" {
  description = "location to write the victim infra details file"
}

variable "bastion_server_details" {
  description = "location to write the bastion host details file"
}

variable "attack_server_details" {
  description = "location to write the attack host details file"
}

variable "ssh_public_key_file" {
  description = "File location of public key for linux servers"
}

variable "win_rsa_public_key_file" {
  description = "File location of public key used for encrypting secrets for Windows servers"
}
variable "win_rsa_private_key_file" {
  description = "file path to the private key in the windows key pair. This value is used to decrypt windows-based instance password data."
}

variable "ssh_private_key_file" {
  description = "file path to the private key in the ssh key pair."
}

#############
## Modules ##
#############

## Core 
variable "vpc_cidr" {
  description = "CIDR of the main VPC"
}
variable "extra_trusted_networks" {
  description = "Additional CIDRs allowed inbound on bastions/attacker. The caller's public IP is always added automatically; use this to extend access for teammates or a corp VPN range."
  type        = list(string)
  default     = []
}


## Public
variable "public_subnet_cidr" {
  description = "CIDR of public subnet in the VPC"
}

variable "web_server_instance_type" {
  description = "Instance type for the web_server"
}

variable "web_server_private_ip" {
  description = "Private IP for the web_server"
}

variable "web_server_domain_hostname" {
  description = "Hostname to be given to web_server. This value is passed to Ansible via the inventory file."
}

variable "mail_server_ami_owner" {
  description = "AMI owner for the AMI associated with the mail server"
}

variable "mail_server_ami_name" {
  description = "AMI name for the AMI associated with the mail server"
}

variable "mail_server_instance_type" {
  description = "Instance type for the mail server"
}

variable "mail_server_private_ip" {
  description = "Private IP for the mail server"
}

variable "mail_server_hostname" {
  description = "Hostname for the mail server"
}

variable "firewall_instance_type" {
  description = "Instance type for the firewall/router"
}

variable "firewall_private_ip" {
  description = "Private IP for the firewall/router"
}


## Corp
variable "corp_subnet_cidr" {
  description = "CIDR of corp subnet in the VPC"
}

variable "DC_ami_owner" {
  description = "AMI owner for the AMI associated with the DC"
}

variable "DC_ami_name" {
  description = "AMI name for the AMI associated with the DC"
}

variable "client_ami_owner" {
  description = "AMI owner for the AMI associated with the clients. If null, defaults to var.aws_account_id."
  type        = string
  default     = null
}

variable "client_ami_name" {
  description = "AMI name for the AMI associated with the clients"
}

variable "DC_instance_type" {
  description = "Instance type for the DC"
}

variable "DC_private_ip" {
  description = "Private IP for the DC"
}

variable "DC_hostname" {
  description = "Hostname to be given to the Domain Controller. This value is passed to Ansible via the inventory file."
}

variable "client_instance_type" {
  description = "Instance type for the clients"
}

variable "client_1_private_ip" {
  description = "Private IP for client 1"
}

variable "client_1_domain_hostname" {
  description = "Hostname to be given to client 1. This value is passed to Ansible via the inventory file."
}
variable "client_2_private_ip" {
  description = "Private IP for client 2"
}
variable "client_2_domain_hostname" {
  description = "Hostname to be given to client 2. This value is passed to Ansible via the inventory file."
}
variable "client_3_private_ip" {
  description = "Private IP for client 3"
}
variable "client_3_domain_hostname" {
  description = "Hostname to be given to client 3. This value is passed to Ansible via the inventory file."
}

## super_secret
variable "super_secret_subnet_cidr" {
  description = "CIDR of super_secret subnet in the VPC"
}

variable "file_server_ami_owner" {
  description = "AMI owner for the AMI associated with the file_server"
}

variable "file_server_ami_name" {
  description = "AMI name for the AMI associated with the file server"
}

variable "sql_server_ami_owner" {
  description = "AMI owner for the AMI associated with the sql server"
}

variable "sql_server_ami_name" {
  description = "AMI name for the AMI associated with the sql server"
}

variable "file_server_instance_type" {
  description = "Instance type for the file server"
}

variable "file_server_private_ip" {
  description = "Private IP for the file server"
}

variable "file_server_hostname" {
  description = "Hostname to be given to file_server. This value is passed to Ansible via the inventory file."
}

variable "sql_server_instance_type" {
  description = "Instance type for the sql server"
}

variable "sql_server_private_ip" {
  description = "Private IP for the sql server"
}

variable "sql_server_hostname" {
  description = "Hostname to be given to sql_server. This value is passed to Ansible via the inventory file."
}

## SecOps
variable "secops_subnet_cidr" {
  description = "CIDR of secops subnet in VPC"
}

variable "windows_bastion_server_ami_owner" {
  description = "AMI owner for the AMI associated with the bastion server"
}

variable "windows_bastion_server_ami_name" {
  description = "AMI name for the AMI associated with the bastion server"
}

variable "windows_bastion_server_instance_type" {
  description = "Instance type for the bastion server"
}

variable "windows_bastion_server_private_ip" {
  description = "Private IP for the bastion server"
}

variable "linux_bastion_server_ami_owner" {
  description = "AMI owner for the AMI associated with the linux bastion server"
}
variable "linux_bastion_server_ami_name" {
  description = "AMI name for the AMI associated with the linux bastion server"
}
variable "linux_bastion_server_instance_type" {
  description = "Instance type for the linux bastion server"
}
variable "linux_bastion_server_private_ip" {
  description = "Private IP for the linux bastion server"
}

## Inner Firewalls
variable "fw_inner_ami_owner" {
  description = "AMI owner for inner firewall NVAs (Linux)"
}
variable "fw_inner_ami_name" {
  description = "AMI name for inner firewall NVAs (Linux)"
}
variable "fw_inner_instance_type" {
  description = "Instance type for inner firewall NVAs"
}
variable "fw_dmz_corp_dmz_ip" {
  description = "DMZ-side private IP for the DMZ<->corp firewall"
}
variable "fw_dmz_corp_corp_ip" {
  description = "Corp-side private IP for the DMZ<->corp firewall"
}
variable "fw_corp_secret_corp_ip" {
  description = "Corp-side private IP for the corp<->secret firewall"
}
variable "fw_corp_secret_secret_ip" {
  description = "Secret-side private IP for the corp<->secret firewall"
}
variable "fw_dmz_corp_hostname" {
  description = "Hostname for the DMZ<->corp inner firewall"
}
variable "fw_corp_secret_hostname" {
  description = "Hostname for the corp<->secret inner firewall"
}

## Privileged Access (PAW)
variable "paw_subnet_cidr" {
  description = "CIDR for the privileged-access subnet (PAWs + Guacamole)"
}
variable "paw_1_private_ip" {
  description = "Private IP for paw-1"
}
variable "paw_1_domain_hostname" {
  description = "Hostname for paw-1"
}
variable "paw_2_private_ip" {
  description = "Private IP for paw-2"
}
variable "paw_2_domain_hostname" {
  description = "Hostname for paw-2"
}
variable "paw_instance_type" {
  description = "Instance type for the PAW workstations"
}
variable "guac_private_ip" {
  description = "Private IP for the Guacamole gateway"
}
variable "guac_hostname" {
  description = "Hostname for the Guacamole gateway"
}
variable "guac_ami_owner" {
  description = "AMI owner for the Guacamole gateway"
}
variable "guac_ami_name" {
  description = "AMI name for the Guacamole gateway"
}
variable "guac_instance_type" {
  description = "Instance type for the Guacamole gateway"
}

## Attacker
variable "attacker_vpc_cidr" {
  description = "VPC CIDR for attacker network"
}

variable "attacker_subnet_cidr" {
  description = "Subnet CIDR for attacker subnet"
}

variable "attacker_server_ami_owner" {
  description = "AMI owner for the AMI associated with the attacker server"
}

variable "attacker_server_ami_name" {
  description = "AMI name for the AMI associated with the attacker server"
}

variable "attacker_server_instance_type" {
  description = "Instance type for the attacker server"
}
