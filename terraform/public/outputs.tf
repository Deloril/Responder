############
## Public ##
############

output "nat_gateway" {
  value = aws_nat_gateway.nat_gateway
}

output "web_server" {
  value = aws_instance.web_server
}

output "web_server_eip" {
  value = aws_eip.web_server_eip
}

output "mail_server" {
  value = aws_instance.mail_server
}

output "firewall" {
  value = aws_instance.firewall
}

output "firewall_sg_id" {
  value = aws_security_group.firewall_public.id
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}
