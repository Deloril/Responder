###################
## Inner Firewalls
###################
#
# Two Linux NVAs (Ubuntu + iptables) sitting between the existing tiers:
#
#   DMZ (10.0.0.0/24) <-- fw-dmz-corp --> Corp (10.0.1.0/24) <-- fw-corp-secret --> Secret (10.0.2.0/24)
#
# Each firewall has an ENI in both adjacent subnets so that incident responders
# can ssh in and inspect a real firewall config (iptables -L, /var/log/syslog,
# packet captures). source_dest_check is disabled so they can forward packets.
#
# AWS routing in a single VPC always prefers the local route within a VPC, so
# segmentation between tiers is *enforced* via security groups -- the firewall
# host is the realistic, attackable, observable representation of the boundary
# rather than a route-table chokepoint.

# AMI for the firewall NVAs
data "aws_ami" "fw_inner_ami" {
  most_recent = true
  owners      = [var.fw_inner_ami_owner]

  filter {
    name   = "name"
    values = [var.fw_inner_ami_name]
  }
}

####################
## Security Groups
####################

# fw-dmz-corp: present in both public/DMZ and corp.
# Allow web/mail traffic from corp out to DMZ; allow DMZ services to talk back.
resource "aws_security_group" "fw_dmz_corp" {
  name        = "fw_dmz_corp"
  description = "Inner firewall between DMZ and corp"
  vpc_id      = var.vpc_id

  ingress {
    description = "All from corp subnet (corp to dmz egress passes through here)"
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.corp_subnet_cidr]
  }

  ingress {
    description = "Web/mail return traffic from DMZ"
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.public_subnet_cidr]
  }

  egress {
    description = "All outbound (forwarder)"
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-fw_dmz_corp_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# fw-corp-secret: present in both corp and secret.
resource "aws_security_group" "fw_corp_secret" {
  name        = "fw_corp_secret"
  description = "Inner firewall between corp and secret storage"
  vpc_id      = var.vpc_id

  ingress {
    description = "All from corp subnet (PAW reaches secret via this firewall)"
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.corp_subnet_cidr]
  }

  ingress {
    description = "Return traffic from secret subnet"
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.super_secret_subnet_cidr]
  }

  egress {
    description = "All outbound (forwarder)"
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-fw_corp_secret_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

####################
## fw-dmz-corp host
####################

resource "aws_network_interface" "fw_dmz_corp_dmz" {
  subnet_id         = var.public_subnet_id
  private_ips       = [var.fw_dmz_corp_dmz_ip]
  source_dest_check = false
  security_groups   = [aws_security_group.fw_dmz_corp.id, var.secops_access_sg.id]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-fw_dmz_corp_dmz_eni-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

resource "aws_network_interface" "fw_dmz_corp_corp" {
  subnet_id         = var.corp_subnet_id
  private_ips       = [var.fw_dmz_corp_corp_ip]
  source_dest_check = false
  security_groups   = [aws_security_group.fw_dmz_corp.id, var.secops_access_sg.id]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-fw_dmz_corp_corp_eni-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

resource "aws_instance" "fw_dmz_corp" {
  ami           = data.aws_ami.fw_inner_ami.id
  instance_type = var.fw_inner_instance_type
  key_name      = var.ssh_public_key.key_name

  network_interface {
    network_interface_id = aws_network_interface.fw_dmz_corp_dmz.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.fw_dmz_corp_corp.id
    device_index         = 1
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-fw_dmz_corp-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

####################
## fw-corp-secret host
####################

resource "aws_network_interface" "fw_corp_secret_corp" {
  subnet_id         = var.corp_subnet_id
  private_ips       = [var.fw_corp_secret_corp_ip]
  source_dest_check = false
  security_groups   = [aws_security_group.fw_corp_secret.id, var.secops_access_sg.id]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-fw_corp_secret_corp_eni-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

resource "aws_network_interface" "fw_corp_secret_secret" {
  subnet_id         = var.super_secret_subnet_id
  private_ips       = [var.fw_corp_secret_secret_ip]
  source_dest_check = false
  security_groups   = [aws_security_group.fw_corp_secret.id, var.secops_access_sg.id]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-fw_corp_secret_secret_eni-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

resource "aws_instance" "fw_corp_secret" {
  ami           = data.aws_ami.fw_inner_ami.id
  instance_type = var.fw_inner_instance_type
  key_name      = var.ssh_public_key.key_name

  network_interface {
    network_interface_id = aws_network_interface.fw_corp_secret_corp.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.fw_corp_secret_secret.id
    device_index         = 1
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-fw_corp_secret-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}
