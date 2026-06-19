############
## secops ##
############

## Project/Deployment ##
variable "region" {}
variable "project_name" {}
variable "builder_project_name" {}
variable "username" {}
variable "aws_account_id" {}
variable "kms_key_id" {}

## public ##
variable "secops_subnet_cidr" {}
variable "vpc_id" {}
variable "vpc_cidr" {}
variable "trusted_networks" {}
variable "igw_id" {}
variable "win_rsa_public_key" {}
variable "ssh_public_key" {}
variable "windows_bastion_server_ami_owner" {}
variable "windows_bastion_server_ami_name" {}
variable "windows_bastion_server_instance_type" {}
variable "windows_bastion_server_private_ip" {}
variable "win_rsa_private_key_file" {}
variable "linux_bastion_server_ami_owner" {}
variable "linux_bastion_server_ami_name" {}
variable "linux_bastion_server_instance_type" {}
variable "linux_bastion_server_private_ip" {}
variable "secops_subnet_id" {}
variable "secops_internal_sg_id" {}
variable "secops_internet_access_sg_id" {}
variable "secops_access_sg_id" {}