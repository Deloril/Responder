##############
## Attacker ##
##############

## Resources
# VPC
# IGW
# subnet
# route table / route association
# instance definition
# attacker_server

## Outputs
# attacker_server


## VPC 
resource "aws_vpc" "attacker_vpc" {
  cidr_block           = var.attacker_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-attacker_vpc-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

## Internet Gateway
resource "aws_internet_gateway" "attacker_igw" {
  vpc_id = aws_vpc.attacker_vpc.id

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-attacker_igw-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# Attacker subnet
resource "aws_subnet" "attacker_subnet" {
  vpc_id = aws_vpc.attacker_vpc.id

  cidr_block              = var.attacker_subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-attacker_subnet-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# # Route Table
resource "aws_route_table" "attacker_route_table" {
  vpc_id = aws_vpc.attacker_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.attacker_igw.id
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-attacker_subnet_route_table-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# # Route table association
resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.attacker_subnet.id
  route_table_id = aws_route_table.attacker_route_table.id
}


## Security Groups
# attacker inbound/outbound SG
resource "aws_security_group" "attacker_machine" {
  name        = "attacker_machine"
  description = "Security group rules for attacker machine to reach the victim network and inbound connections from trusted networks and bastions"
  vpc_id      = aws_vpc.attacker_vpc.id

  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = flatten(["${var.victim_network_nat}/32", "${var.linux_bastion_public_ip}/32", var.trusted_networks])
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-attacker_machine_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# attacker server ami definition
data "aws_ami" "attacker_server_ami" {
  most_recent = true
  owners      = [var.attacker_server_ami_owner]

  filter {
    name   = "name"
    values = [var.attacker_server_ami_name]
  }
}

# attacker server instance
resource "aws_instance" "attacker" {
  ami           = data.aws_ami.attacker_server_ami.id
  instance_type = var.attacker_server_instance_type

  subnet_id = aws_subnet.attacker_subnet.id

  key_name = var.ssh_public_key.key_name
  root_block_device {
    delete_on_termination = true
    volume_size           = 100
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"

  }

  vpc_security_group_ids = [
    aws_security_group.attacker_machine.id
  ]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-attacker_server-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}