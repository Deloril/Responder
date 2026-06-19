##########
## Core ##
##########

output "vpc_id" {
  value = var.vpc_id
}

output "igw_id" {
  value = var.igw_id
}

output "ssh_public_key" {
  value = aws_key_pair.ssh_public_key
}

output "win_rsa_public_key" {
  value = aws_key_pair.win_rsa_public_key
}
