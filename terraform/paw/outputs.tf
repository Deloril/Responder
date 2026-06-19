######################
## Privileged Access
######################

output "paw_1" {
  value = aws_instance.paw_1
}

output "paw_2" {
  value = aws_instance.paw_2
}

output "guac" {
  value = aws_instance.guac
}

output "paw_subnet_id" {
  value = aws_subnet.paw_subnet.id
}

output "paw_subnet_cidr" {
  value = aws_subnet.paw_subnet.cidr_block
}

output "paw_to_secret_sg" {
  value = aws_security_group.paw_to_secret
}
