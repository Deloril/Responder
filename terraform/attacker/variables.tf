##############
## Attacker ##
##############

## Project/Deployment
variable "region" {}
variable "project_name" {}
variable "username" {}
variable "aws_account_id" {}
variable "kms_key_id" {}

## Attacker 
variable "attacker_vpc_cidr" {}
variable "attacker_subnet_cidr" {}
variable "victim_network_nat" {}
variable "linux_bastion_public_ip" {}
variable "trusted_networks" {}
variable "attacker_server_ami_owner" {}
variable "attacker_server_ami_name" {}
variable "attacker_server_instance_type" {}
variable "ssh_public_key" {}
