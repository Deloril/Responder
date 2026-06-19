##########
## Corp ##
##########

output "corp_internal_sg" {
  value = aws_security_group.corp_internal
}

output "adds_access_sg" {
  value = aws_security_group.adds_access
}

output "DC" {
  value = aws_instance.DC
}

output "client_1" {
  value = aws_instance.client_1
}

output "client_2" {
  value = aws_instance.client_2
}

output "client_3" {
  value = aws_instance.client_3
}
output "DC_password" {
  value = rsadecrypt(aws_instance.DC.password_data, file("${var.win_rsa_private_key_file}"))
}

output "corp_subnet_id" {
  value = aws_subnet.corp_subnet.id
}