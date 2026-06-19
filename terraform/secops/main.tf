############
## secops ##
############

# subnet
# SGs
# Servers

# windows_bastion inbound
resource "aws_security_group" "windows_bastion_public_access" {
  name        = "windows_bastion public access"
  description = "Security group rules for the windows_bastion"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 3389
    to_port     = 3389
    cidr_blocks = var.trusted_networks
  }

  ingress {
    protocol    = "tcp"
    from_port   = 5985
    to_port     = 5986
    cidr_blocks = var.trusted_networks
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-windows_bastion_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# ebs key

data "aws_ebs_default_kms_key" "current" {}


## Servers

# windows_bastion ami definition
data "aws_ami" "windows_bastion_server_ami" {
  most_recent = true
  owners      = [var.windows_bastion_server_ami_owner]

  filter {
    name   = "name"
    values = [var.windows_bastion_server_ami_name]
  }
}

# windows_bastion instance
resource "aws_instance" "windows_bastion" {
  # type
  ami           = data.aws_ami.windows_bastion_server_ami.id
  instance_type = var.windows_bastion_server_instance_type

  subnet_id  = var.secops_subnet_id
  private_ip = var.windows_bastion_server_private_ip

  key_name = var.win_rsa_public_key.key_name

  user_data         = file("./utils/user_data_windows_bastion.txt") # this is relative to where terraform is called from
  get_password_data = true

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"

  }

  # Secondary 50GB volume — initialized and mounted as D: by user_data
  ebs_block_device {
    device_name           = "xvdb"
    volume_size           = 50
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"
  }

  vpc_security_group_ids = [
    var.secops_internal_sg_id,
    aws_security_group.windows_bastion_public_access.id,
    var.secops_internet_access_sg_id
  ]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-windows_bastion-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

resource "aws_eip" "windows_bastion_eip" {
  domain = "vpc"
  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-windows_bastion_eip-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}
resource "aws_eip_association" "windows_bastion_eip_association" {
  instance_id   = aws_instance.windows_bastion.id
  allocation_id = aws_eip.windows_bastion_eip.id
}

## Note: linux_bastion instance is created in root; its public IP is passed directly to the attacker module from root.