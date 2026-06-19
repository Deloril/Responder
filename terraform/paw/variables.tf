######################
## Privileged Access
######################

variable "region" {}
variable "project_name" {}
variable "username" {}
variable "username_short" {}
variable "aws_account_id" {}
variable "kms_key_id" {}

variable "vpc_id" {}
variable "vpc_cidr" {}
variable "nat_gateway" {}
variable "paw_subnet_cidr" {}
variable "corp_subnet_cidr" {}
variable "super_secret_subnet_cidr" {}

variable "client_ami_owner" {}
variable "client_ami_name" {}

variable "paw_instance_type" {}
variable "paw_1_private_ip" {}
variable "paw_1_domain_hostname" {}
variable "paw_2_private_ip" {}
variable "paw_2_domain_hostname" {}

variable "guac_ami_owner" {}
variable "guac_ami_name" {}
variable "guac_instance_type" {}
variable "guac_private_ip" {}

variable "win_rsa_public_key" {}
variable "ssh_public_key" {}
variable "secops_access_sg" {}
variable "adds_access_sg" {}
variable "win_rsa_private_key_file" {}
