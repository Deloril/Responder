##################
## Super_secret ##
##################

## Project/Deployment ##
variable "region" {}
variable "project_name" {}
variable "username" {}
variable "aws_account_id" {}
variable "kms_key_id" {}

## public ##
variable "super_secret_subnet_cidr" {}
variable "vpc_id" {}
variable "nat_gateway" {}
variable "win_rsa_public_key" {}
variable "ssh_public_key" {}
variable "file_server_ami_owner" {}
variable "file_server_ami_name" {}
variable "sql_server_ami_owner" {}
variable "sql_server_ami_name" {}
variable "file_server_instance_type" {}
variable "file_server_private_ip" {}
variable "sql_server_instance_type" {}
variable "sql_server_private_ip" {}
variable "corp_subnet_cidr" {}
variable "paw_subnet_cidr" {}
variable "secops_access_sg" {}
variable "adds_access_sg" {}
variable "win_rsa_private_key_file" {}