###################
## Inner Firewalls
###################

variable "region" {}
variable "project_name" {}
variable "username" {}
variable "aws_account_id" {}
variable "kms_key_id" {}

variable "vpc_id" {}
variable "vpc_cidr" {}
variable "public_subnet_id" {}
variable "public_subnet_cidr" {}
variable "corp_subnet_id" {}
variable "corp_subnet_cidr" {}
variable "super_secret_subnet_id" {}
variable "super_secret_subnet_cidr" {}

variable "fw_inner_ami_owner" {}
variable "fw_inner_ami_name" {}
variable "fw_inner_instance_type" {}
variable "fw_dmz_corp_dmz_ip" {}
variable "fw_dmz_corp_corp_ip" {}
variable "fw_corp_secret_corp_ip" {}
variable "fw_corp_secret_secret_ip" {}

variable "ssh_public_key" {}
variable "secops_access_sg" {}
