##########
## Corp ##
##########

## Project/Deployment ##
variable "region" {}
variable "project_name" {}
variable "username" {}
variable "username_short" {}
variable "aws_account_id" {}
variable "kms_key_id" {}

## public ##

variable "vpc_id" {}
variable "nat_gateway" {}
variable "corp_subnet_cidr" {}
variable "DC_ami_owner" {}
variable "DC_ami_name" {}
variable "client_ami_owner" {}
variable "client_ami_name" {}
variable "DC_instance_type" {}
variable "DC_private_ip" {}
variable "client_instance_type" {}
variable "client_1_private_ip" {}
variable "client_2_private_ip" {}
variable "client_3_private_ip" {}
variable "client_1_domain_hostname" {}
variable "client_2_domain_hostname" {}
variable "client_3_domain_hostname" {}
variable "win_rsa_public_key" {}
variable "ssh_public_key" {}
variable "secops_access_sg" {}
variable "file_server_private_ip" {}
variable "win_rsa_private_key_file" {}