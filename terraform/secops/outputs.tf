############
## secops ##
############

output "windows_bastion" {
  value = aws_instance.windows_bastion
}

output "windows_bastion_eip" {
  value = aws_eip.windows_bastion_eip
}

# output "linux_bastion_eip" {
#     value = aws_eip.linux_bastion_eip
# }

# output "linux_bastion_eip_association" {
#     value = aws_eip_association.linux_bastion_eip_association
# }

output "windows_bastion_password" {
  value = rsadecrypt(aws_instance.windows_bastion.password_data, file("${var.win_rsa_private_key_file}"))
}