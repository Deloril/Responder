############
## Public ##
############

# subnet
# route table
# route table association
# elastic IP
# nat_gateway
# SGs
# web_server instance
# web_server EIP


# Public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id = var.vpc_id

  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.region}a" # Availability zone A
  map_public_ip_on_launch = false

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-public_subnet-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

#Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-public_subnet_route_table-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

#Route table association
resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Elastic IPs
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-nat_eip-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

resource "aws_eip" "web_server_eip" {
  domain = "vpc"
  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-web_server_eip-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-nat_gateway-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

## Security Groups
# Firewall/Router public SG -- single public entry point for web + mail traffic
resource "aws_security_group" "firewall_public" {
  name        = "firewall_public_access"
  description = "Allow inbound HTTP, HTTPS, and SMTP to the firewall/router from trusted networks"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP inbound"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = var.trusted_networks
  }

  ingress {
    description = "HTTPS inbound"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = var.trusted_networks
  }

  ingress {
    description = "SMTP inbound"
    protocol    = "tcp"
    from_port   = 25
    to_port     = 25
    cidr_blocks = var.trusted_networks
  }

  egress {
    description = "Allow all outbound"
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-firewall_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# Shared egress SG for public subnet servers that need outbound internet (apt, etc.)
resource "aws_security_group" "public_internet_egress" {
  name        = "public_internet_egress"
  description = "Allow all outbound internet access for public subnet instances"
  vpc_id      = var.vpc_id

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-public_egress_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# ebs key

data "aws_ebs_default_kms_key" "current" {}

## Servers

# Web server (Ubuntu)
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.mail_server_ami.id
  instance_type = var.web_server_instance_type

  subnet_id                   = aws_subnet.public_subnet.id
  private_ip                  = var.web_server_private_ip
  associate_public_ip_address = true

  key_name = var.ssh_public_key.key_name

  vpc_security_group_ids = [
    var.corp_internal_sg.id,
    var.secops_access_sg.id,
    aws_security_group.public_internet_egress.id
  ]

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-web_server-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

## Firewall / Router (Linux)

data "aws_ami" "firewall_ami" {
  most_recent = true
  owners      = [var.mail_server_ami_owner]

  filter {
    name   = "name"
    values = [var.mail_server_ami_name]
  }
}

resource "aws_instance" "firewall" {
  ami           = data.aws_ami.firewall_ami.id
  instance_type = var.firewall_instance_type

  subnet_id  = aws_subnet.public_subnet.id
  private_ip = var.firewall_private_ip

  source_dest_check = false

  key_name = var.ssh_public_key.key_name

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"
  }

  vpc_security_group_ids = [
    var.corp_internal_sg.id,
    var.secops_access_sg.id,
    aws_security_group.firewall_public.id
  ]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-firewall-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

resource "aws_eip_association" "firewall_eip_association" {
  instance_id   = aws_instance.firewall.id
  allocation_id = aws_eip.web_server_eip.id
}

## Mail Server (Linux)

data "aws_ami" "mail_server_ami" {
  most_recent = true
  owners      = [var.mail_server_ami_owner]

  filter {
    name   = "name"
    values = [var.mail_server_ami_name]
  }
}

resource "aws_instance" "mail_server" {
  ami           = data.aws_ami.mail_server_ami.id
  instance_type = var.mail_server_instance_type

  subnet_id                   = aws_subnet.public_subnet.id
  private_ip                  = var.mail_server_private_ip
  associate_public_ip_address = true

  key_name = var.ssh_public_key.key_name

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"
  }

  vpc_security_group_ids = [
    var.corp_internal_sg.id,
    var.secops_access_sg.id,
    aws_security_group.public_internet_egress.id
  ]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-mail_server-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}


