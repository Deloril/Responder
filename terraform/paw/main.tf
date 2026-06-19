######################
## Privileged Access
######################
#
# The "privileged access workstation" tier. Two domain-joined Windows hosts
# (paw-1, paw-2) plus an Apache Guacamole gateway. Users RDP through Guacamole
# (HTTPS) to a PAW; the PAWs are the *only* hosts allowed to reach SMB/MSSQL on
# the secret-storage tier.
#
# In TSG canon this is the Strongroom Trust HNW custody access path: a
# break-glass tier with its own narrow audit trail.

####################
## Subnet + Routing
####################

resource "aws_subnet" "paw_subnet" {
  vpc_id = var.vpc_id

  cidr_block              = var.paw_subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-paw_subnet-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

resource "aws_route_table" "paw" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.nat_gateway.id
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-paw_route_table-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

resource "aws_route_table_association" "paw_rta" {
  subnet_id      = aws_subnet.paw_subnet.id
  route_table_id = aws_route_table.paw.id
}

####################
## Security Groups
####################

# All hosts in this tier can talk to each other freely.
resource "aws_security_group" "paw_internal" {
  name        = "paw_internal"
  description = "Internal communications within the privileged-access tier"
  vpc_id      = var.vpc_id

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    self      = true
  }

  egress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    self      = true
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-paw_internal_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# Outbound internet (via NAT gateway) for patching, ansible, falcon sensor.
resource "aws_security_group" "paw_internet_access" {
  name        = "paw_internet_access"
  description = "Outbound internet for the privileged-access tier"
  vpc_id      = var.vpc_id

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-paw_internet_access_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# Reach the secret-storage tier (file SMB + MSSQL).
# This SG is *applied to the PAW workstations only* -- it is the narrow path
# from corp/PAW to the secret storage subnet.
resource "aws_security_group" "paw_to_secret" {
  name        = "paw_to_secret"
  description = "PAW workstations to secret storage (SMB, MSSQL, AD)"
  vpc_id      = var.vpc_id

  egress {
    description = "SMB to file server"
    protocol    = "tcp"
    from_port   = 445
    to_port     = 445
    cidr_blocks = [var.super_secret_subnet_cidr]
  }

  egress {
    description = "MSSQL to sql server"
    protocol    = "tcp"
    from_port   = 1433
    to_port     = 1433
    cidr_blocks = [var.super_secret_subnet_cidr]
  }

  egress {
    description = "MSSQL Browser"
    protocol    = "udp"
    from_port   = 1434
    to_port     = 1434
    cidr_blocks = [var.super_secret_subnet_cidr]
  }

  egress {
    description = "RDP to PAWs (Guacamole brokers RDP to these)"
    protocol    = "tcp"
    from_port   = 3389
    to_port     = 3389
    cidr_blocks = [var.paw_subnet_cidr]
  }

  egress {
    description = "WinRM to PAWs (ansible)"
    protocol    = "tcp"
    from_port   = 5985
    to_port     = 5986
    cidr_blocks = [var.paw_subnet_cidr]
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-paw_to_secret_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# Guacamole web (HTTPS) reachable from corp + secops only. Not from internet
# directly -- a corp user goes through the secops bastion or a VPN to reach it.
resource "aws_security_group" "guac_ingress" {
  name        = "guac_ingress"
  description = "Inbound HTTPS to Guacamole gateway from corp + secops only"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from corp"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [var.corp_subnet_cidr]
  }

  ingress {
    description = "Guacamole web 8080 from corp (dev/inspection)"
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = [var.corp_subnet_cidr]
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-guac_ingress_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

####################
## Servers
####################

data "aws_ami" "client_ami" {
  most_recent = true
  owners      = [var.client_ami_owner]

  filter {
    name   = "name"
    values = [var.client_ami_name]
  }
}

data "aws_ami" "guac_ami" {
  most_recent = true
  owners      = [var.guac_ami_owner]

  filter {
    name   = "name"
    values = [var.guac_ami_name]
  }
}

# paw-1
resource "aws_instance" "paw_1" {
  ami           = data.aws_ami.client_ami.id
  instance_type = var.paw_instance_type

  subnet_id  = aws_subnet.paw_subnet.id
  private_ip = var.paw_1_private_ip

  key_name = var.win_rsa_public_key.key_name

  user_data = templatefile("${path.root}/utils/user_data_client.ps1.tpl", {
    computer_name = "${var.paw_1_domain_hostname}-${var.username_short}"
  })
  get_password_data = false

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"
  }

  vpc_security_group_ids = [
    aws_security_group.paw_internal.id,
    aws_security_group.paw_internet_access.id,
    aws_security_group.paw_to_secret.id,
    var.secops_access_sg.id,
    var.adds_access_sg.id,
  ]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-paw_1-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# paw-2
resource "aws_instance" "paw_2" {
  ami           = data.aws_ami.client_ami.id
  instance_type = var.paw_instance_type

  subnet_id  = aws_subnet.paw_subnet.id
  private_ip = var.paw_2_private_ip

  key_name = var.win_rsa_public_key.key_name

  user_data = templatefile("${path.root}/utils/user_data_client.ps1.tpl", {
    computer_name = "${var.paw_2_domain_hostname}-${var.username_short}"
  })
  get_password_data = false

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"
  }

  vpc_security_group_ids = [
    aws_security_group.paw_internal.id,
    aws_security_group.paw_internet_access.id,
    aws_security_group.paw_to_secret.id,
    var.secops_access_sg.id,
    var.adds_access_sg.id,
  ]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-paw_2-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# Guacamole gateway (Linux, brokers RDP to PAWs over HTTPS to users)
resource "aws_instance" "guac" {
  ami           = data.aws_ami.guac_ami.id
  instance_type = var.guac_instance_type

  subnet_id  = aws_subnet.paw_subnet.id
  private_ip = var.guac_private_ip

  key_name = var.ssh_public_key.key_name

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"
  }

  vpc_security_group_ids = [
    aws_security_group.paw_internal.id,
    aws_security_group.paw_internet_access.id,
    aws_security_group.guac_ingress.id,
    var.secops_access_sg.id,
  ]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-guac-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}
