##########
## Core ##
##########

## Resources
# VPC
# IGW
# Key pairs

## Outputs
# vpc_id
# igw_id
# ssh_public_key
# win_rsa_public_key


## Key Pairs
# Windows
resource "aws_key_pair" "win_rsa_public_key" {
  public_key = file(var.win_rsa_public_key_file)
  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-win_rsa_key_pair-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# Linux
resource "aws_key_pair" "ssh_public_key" {
  public_key = file(var.ssh_public_key_file)
  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-ssh_key_pair-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

