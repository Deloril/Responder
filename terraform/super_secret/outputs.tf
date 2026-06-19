##################
## Super_secret ##
##################

output "file_server" {
  value = aws_instance.file_server
}

output "sql_server" {
  value = aws_instance.sql_server
}
output "file_server_password" {
  value = rsadecrypt(aws_instance.file_server.password_data, file("${var.win_rsa_private_key_file}"))
}

output "sql_server_password" {
  value = rsadecrypt(aws_instance.sql_server.password_data, file("${var.win_rsa_private_key_file}"))
}

output "super_secret_subnet_id" {
  value = aws_subnet.super_secret_subnet.id
}