###########
## Builder
###########

## Project/Deployment
variable "region" {}
variable "project_name" {}
variable "builder_project_name" {}
variable "username" {}

## Inputs
variable "win_rsa_public_key_file" {}
variable "ssh_public_key_file" {}
variable "enable_dns_support" {
  default = true
}
variable "enable_dns_hostnames" {
  default = true
}
variable "tags" {
  type = map(string)
}

## Workspace mapping used for local provider configuration
variable "workspace_mapping" {
  description = "Used for mapping a name to a workspace."
  default = {
    "apac"     = "ap-southeast-2" # Sydney
    "emea"     = "eu-west-1"      # Dublin
    "amer"     = "us-east-1"      # North Virginia
    "test-env" = "ap-southeast-1" # Singapore
    "star"     = "ap-south-1"     # Mumbai
  }
}

