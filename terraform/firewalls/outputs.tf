###################
## Inner Firewalls
###################

output "fw_dmz_corp" {
  value = aws_instance.fw_dmz_corp
}

output "fw_corp_secret" {
  value = aws_instance.fw_corp_secret
}

output "fw_dmz_corp_corp_ip" {
  value = var.fw_dmz_corp_corp_ip
}

output "fw_dmz_corp_dmz_ip" {
  value = var.fw_dmz_corp_dmz_ip
}

output "fw_corp_secret_corp_ip" {
  value = var.fw_corp_secret_corp_ip
}

output "fw_corp_secret_secret_ip" {
  value = var.fw_corp_secret_secret_ip
}
