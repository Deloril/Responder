############
## Public ##
############

## Project/Deployment ##
variable "region" {}
variable "project_name" {}
variable "username" {}
variable "aws_account_id" {}
variable "kms_key_id" {}

## public ##
variable "vpc_id" {}
variable "igw_id" {}
variable "public_subnet_cidr" {}
variable "trusted_networks" {}
variable "web_server_instance_type" {}
variable "web_server_private_ip" {}
variable "win_rsa_public_key" {}
variable "corp_internal_sg" {}
variable "secops_access_sg" {}
variable "win_rsa_private_key_file" {}

variable "mail_server_ami_owner" {}
variable "mail_server_ami_name" {}
variable "mail_server_instance_type" {}
variable "mail_server_private_ip" {}
variable "ssh_public_key" {}

variable "firewall_instance_type" {}
variable "firewall_private_ip" {}
