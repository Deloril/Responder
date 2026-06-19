
### Local file provisioners
## Windows ansible inventory file
resource "local_file" "windows_ansible_inventory_file" {
  filename = "${var.windows_ansible_inventory_file}_${terraform.workspace}"
  content  = <<-EOT
    [dc]
    ${module.corp.DC.private_dns} ansible_host=${module.corp.DC.private_ip} ansible_user=Administrator ansible_password="${module.corp.DC_password}" domain_hostname=${var.DC_hostname}-${local.username_short}

    [ms:children]
    clients
    sql
    file
    paws

    [clients]
    ${module.corp.client_1.private_dns} ansible_host=${module.corp.client_1.private_ip} ansible_user=Deployer ansible_password="SuperDeployer_55" domain_hostname=${var.client_1_domain_hostname}-${local.username_short}
    ${module.corp.client_2.private_dns} ansible_host=${module.corp.client_2.private_ip} ansible_user=Deployer ansible_password="SuperDeployer_55" domain_hostname=${var.client_2_domain_hostname}-${local.username_short}
    ${module.corp.client_3.private_dns} ansible_host=${module.corp.client_3.private_ip} ansible_user=Deployer ansible_password="SuperDeployer_55" domain_hostname=${var.client_3_domain_hostname}-${local.username_short}

    [sql]
    ${module.super_secret.sql_server.private_dns} ansible_host=${module.super_secret.sql_server.private_ip} ansible_user=Administrator ansible_password="${module.super_secret.sql_server_password}" domain_hostname=${var.sql_server_hostname}-${local.username_short}

    [file]
    ${module.super_secret.file_server.private_dns} ansible_host=${module.super_secret.file_server.private_ip} ansible_user=Administrator ansible_password="${module.super_secret.file_server_password}" domain_hostname=${var.file_server_hostname}-${local.username_short}

    [paws]
    ${module.paw.paw_1.private_dns} ansible_host=${module.paw.paw_1.private_ip} ansible_user=Deployer ansible_password="SuperDeployer_55" domain_hostname=${var.paw_1_domain_hostname}-${local.username_short}
    ${module.paw.paw_2.private_dns} ansible_host=${module.paw.paw_2.private_ip} ansible_user=Deployer ansible_password="SuperDeployer_55" domain_hostname=${var.paw_2_domain_hostname}-${local.username_short}

    [all:vars]
    ansible_connection=winrm
    ansible_winrm_server_cert_validation=ignore
    EOT
}

## Inner firewalls + Guacamole ansible inventory file
resource "local_file" "inner_fw_ansible_inventory_file" {
  filename = "../ansible/inner-firewalls/inventory/inner_firewalls_inventory_file_${terraform.workspace}"
  content  = <<-EOT
    [fw_dmz_corp]
    ${var.fw_dmz_corp_corp_ip} ansible_user=ubuntu

    [fw_corp_secret]
    ${var.fw_corp_secret_corp_ip} ansible_user=ubuntu

    [inner_firewalls:children]
    fw_dmz_corp
    fw_corp_secret

    [inner_firewalls:vars]
    ansible_ssh_private_key_file="~/project-responder-ssh"
    dmz_corp_dmz_ip=${var.fw_dmz_corp_dmz_ip}
    dmz_corp_corp_ip=${var.fw_dmz_corp_corp_ip}
    corp_secret_corp_ip=${var.fw_corp_secret_corp_ip}
    corp_secret_secret_ip=${var.fw_corp_secret_secret_ip}
    paw_subnet_cidr=${var.paw_subnet_cidr}
    file_server_ip=${var.file_server_private_ip}
    sql_server_ip=${var.sql_server_private_ip}
    EOT
}

## Guacamole ansible inventory file
resource "local_file" "guacamole_ansible_inventory_file" {
  filename = "../ansible/guacamole/inventory/guacamole_inventory_file_${terraform.workspace}"
  content  = <<-EOT
    [guacamole]
    ${module.paw.guac.private_ip} ansible_user=ubuntu

    [guacamole:vars]
    ansible_ssh_private_key_file="~/project-responder-ssh"
    paw_1_ip=${module.paw.paw_1.private_ip}
    paw_2_ip=${module.paw.paw_2.private_ip}
    paw_1_hostname=${var.paw_1_domain_hostname}-${local.username_short}
    paw_2_hostname=${var.paw_2_domain_hostname}-${local.username_short}
    EOT
}

## Linux bastion ansible inventory file
resource "local_file" "linux_bastion_ansible_inventory_file" {
  filename = "${var.linux_bastion_ansible_inventory_file}_${terraform.workspace}"
  content  = <<-EOT
    [linux_bastion]
    ${aws_instance.linux_bastion.public_ip} ansible_user=ubuntu

    [linux_bastion:vars]
    ansible_ssh_private_key_file="${path.cwd}/${var.ssh_private_key_file}"
    EOT
}

## Bastion ansible inventory file
resource "local_file" "windows_bastion_ansible_inventory_file" {
  filename = "${var.windows_bastion_ansible_inventory_file}_${terraform.workspace}"
  content  = <<-EOT
    [windows_bastion]
    ${var.windows_bastion_server_private_ip} ansible_user=Administrator ansible_password="${module.secops.windows_bastion_password}"

    [windows_bastion:vars]
    ansible_connection=winrm
    ansible_winrm_server_cert_validation=ignore
    EOT
}


## Attacker ansible inventory file
resource "local_file" "attacker_ansible_inventory_file" {
  filename = "${var.attacker_ansible_inventory_file}_${terraform.workspace}"
  content  = <<-EOT
    [attacker_server]
    ${module.attacker.attacker_server.public_ip} ansible_user=ubuntu

    [attacker_server:vars]
    ansible_ssh_private_key_file="${path.cwd}/${var.ssh_private_key_file}"
    EOT
}

## Mail server ansible inventory file
resource "local_file" "mail_server_ansible_inventory_file" {
  filename = "../ansible/mail/inventory/mail_server_ansible_inventory_file_${terraform.workspace}"
  content  = <<-EOT
    [mail_server]
    ${module.public.mail_server.private_ip} ansible_user=ubuntu

    [mail_server:vars]
    ansible_ssh_private_key_file="~/project-responder-ssh"
    EOT
}

## Web server ansible inventory file
resource "local_file" "web_server_ansible_inventory_file" {
  filename = "../ansible/webserver/inventory/web_server_ansible_inventory_file_${terraform.workspace}"
  content  = <<-EOT
    [web_server]
    ${module.public.web_server.private_ip} ansible_user=ubuntu

    [web_server:vars]
    ansible_ssh_private_key_file="~/project-responder-ssh"
    domain_name=TSG-INTERNAL.LAB
    domain_admin_user=Administrator
    domain_admin_password=${module.corp.DC_password}
    dc_ip=${var.DC_private_ip}
    EOT
}

## Firewall ansible inventory file
resource "local_file" "firewall_ansible_inventory_file" {
  filename = "../ansible/firewall/inventory/firewall_ansible_inventory_file_${terraform.workspace}"
  content  = <<-EOT
    [firewall]
    ${module.public.firewall.private_ip} ansible_user=ubuntu

    [firewall:vars]
    ansible_ssh_private_key_file="~/project-responder-ssh"
    web_server_ip=${var.web_server_private_ip}
    mail_server_ip=${var.mail_server_private_ip}
    EOT
}

## Linux ansible inventory file
resource "local_file" "linux_ansible_inventory_file" {
  filename = "${var.linux_ansible_inventory_file}_${terraform.workspace}"
  content  = <<-EOT
    [ubuntu]
    10.0.1.20 ansible_user=ubuntu

    [ubuntu:vars]
    ansible_ssh_private_key_file="~/project-responder-ssh"
    EOT
}

resource "local_file" "bastion_server_details" {
  filename = "${var.bastion_server_details}_${terraform.workspace}"
  content  = <<-EOT
  [${terraform.workspace}]
  ## Windows Bastion Server ##
  Windows Bastion Public IP: ${module.secops.windows_bastion_eip.public_ip}
  Windows Bastion Private IP: ${var.windows_bastion_server_private_ip}
  Windows Bastion Public DNS: ${module.secops.windows_bastion_eip.public_dns}
  Windows Bastion User: Administrator
  Windows Bastion Password: ${module.secops.windows_bastion_password}

  ## Linux Bastion Server ##
  Linux Bastion Public IP: ${aws_instance.linux_bastion.public_ip}
  Linux Bastion Private IP: ${var.linux_bastion_server_private_ip}
  Linux Bastion User: ubuntu
  Linux Bastion Certificate: project-responder-ssh (see your team's secret store)
  EOT
}

resource "local_file" "attack_server_details" {
  filename = "${var.attack_server_details}_${terraform.workspace}"
  content  = <<-EOT
  [${terraform.workspace}]
  ## Linux Attack Server ##
  Linux Bastion Public IP: ${module.attacker.attacker_server.public_ip}
  Linux Bastion User: ubuntu
  Linux Bastion Certificate: project-responder-ssh (see your team's secret store)
  Firewall EIP: ${module.public.web_server_eip.public_ip}
  EOT
}

resource "local_file" "victim_infrastructure_details" {
  filename = "${var.victim_infra_details}_${terraform.workspace}"
  content  = <<-EOT
  [${terraform.workspace}]

  ## Public subnet (${var.public_subnet_cidr}) ##
  firewall/router: ${var.firewall_private_ip} ${module.public.web_server_eip.public_ip} ${module.public.web_server_eip.public_dns} (forwards :80/:443->web, :25->mail)
  web server: ${var.web_server_domain_hostname}-${local.username_short}.tsg-internal.lab ${var.web_server_private_ip}
  mail server: ${var.mail_server_hostname}-${local.username_short}.tsg-internal.lab ${var.mail_server_private_ip}
  nat gateway: ${module.public.nat_gateway.public_ip}

  ## Corp subnet (${var.corp_subnet_cidr}) ##
  domain controller: ${var.DC_hostname}-${local.username_short}.tsg-internal.lab ${var.DC_private_ip}
  client 1: ${var.client_1_domain_hostname}-${local.username_short}.tsg-internal.lab ${var.client_1_private_ip}
  client 2: ${var.client_2_domain_hostname}-${local.username_short}.tsg-internal.lab ${var.client_2_private_ip}
  client 3: ${var.client_3_domain_hostname}-${local.username_short}.tsg-internal.lab ${var.client_3_private_ip}

  ## Inner firewalls (DMZ-corp, corp-secret) ##
  fw-dmz-corp: dmz=${var.fw_dmz_corp_dmz_ip} corp=${var.fw_dmz_corp_corp_ip}
  fw-corp-secret: corp=${var.fw_corp_secret_corp_ip} secret=${var.fw_corp_secret_secret_ip}

  ## Privileged Access subnet (${var.paw_subnet_cidr}) ##
  paw 1: ${var.paw_1_domain_hostname}-${local.username_short}.tsg-internal.lab ${var.paw_1_private_ip}
  paw 2: ${var.paw_2_domain_hostname}-${local.username_short}.tsg-internal.lab ${var.paw_2_private_ip}
  guacamole gateway: ${var.guac_hostname}-${local.username_short}.tsg-internal.lab ${var.guac_private_ip} (HTTPS broker for RDP to PAWs)

  ## Secret-storage subnet (${var.super_secret_subnet_cidr}) ##
  ## Reachable from PAW tier ONLY (corp clients have no direct path).
  file server: ${var.file_server_hostname}-${local.username_short}.tsg-internal.lab ${var.file_server_private_ip}
  sql server: ${var.sql_server_hostname}-${local.username_short}.tsg-internal.lab ${var.sql_server_private_ip}
  EOT
}
