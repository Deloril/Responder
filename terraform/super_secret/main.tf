##################
## super_secret ##
##################

# subnet
# SGs
# Servers

# Super_secret subnet
resource "aws_subnet" "super_secret_subnet" {
  vpc_id = var.vpc_id

  cidr_block              = var.super_secret_subnet_cidr
  availability_zone       = "${var.region}a" # ap-southeast-2a
  map_public_ip_on_launch = false

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-super_secret_subnet-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# Route Table
resource "aws_route_table" "super_secret_route_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.nat_gateway.id
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-super_secret_route_table-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# Route table association
resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.super_secret_subnet.id
  route_table_id = aws_route_table.super_secret_route_table.id
}

## Security Groups
# Super_secret internal SG
resource "aws_security_group" "super_secret_internal" {
  name        = "super_secret_internal"
  description = "Security group rules for internal VPC communications in super_secret"
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
    Name                = "${var.username}-super_secret_internal_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# super_secret internet access SG
resource "aws_security_group" "super_secret_internet_access" {
  name        = "super_secret_internet_access"
  description = "Security group rules for super_secret instances to reach the internet"
  vpc_id      = var.vpc_id

  egress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-super_secret_internet_access_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}


# File server: SMB only from the privileged-access (PAW) tier.
# Corp clients no longer have direct access -- they must go through Guacamole
# -> PAW -> file server.
resource "aws_security_group" "super_secret_file_server_access" {
  name        = "super_secret_file_server_access"
  description = "PAW workstations to file server (SMB)"
  vpc_id      = var.vpc_id

  ingress {
    description = "SMB from PAW subnet only"
    protocol    = "tcp"
    from_port   = 445
    to_port     = 445
    cidr_blocks = [var.paw_subnet_cidr]
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-super_secret_file_server_access_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# SQL server: MSSQL only from the privileged-access (PAW) tier.
resource "aws_security_group" "super_secret_sql_server_access" {
  name        = "super_secret_sql_server_access"
  description = "PAW workstations to sql server (MSSQL)"
  vpc_id      = var.vpc_id

  ingress {
    description = "MSSQL from PAW subnet only"
    protocol    = "tcp"
    from_port   = 1433
    to_port     = 1433
    cidr_blocks = [var.paw_subnet_cidr]
  }

  ingress {
    description = "MSSQL Browser from PAW subnet"
    protocol    = "udp"
    from_port   = 1434
    to_port     = 1434
    cidr_blocks = [var.paw_subnet_cidr]
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-super_secret_sql_server_access_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}


# file_server ami definition
data "aws_ami" "file_server_ami" {
  most_recent = true
  owners      = [var.file_server_ami_owner]

  filter {
    name   = "name"
    values = [var.file_server_ami_name]
  }
}

# sql_server ami definition
data "aws_ami" "sql_server_ami" {
  most_recent = true
  owners      = [var.sql_server_ami_owner]

  filter {
    name   = "name"
    values = [var.sql_server_ami_name]
  }
}

# ebs key

data "aws_ebs_default_kms_key" "current" {}


# file_server instance
resource "aws_instance" "file_server" {
  # type
  ami           = data.aws_ami.file_server_ami.id
  instance_type = var.file_server_instance_type

  subnet_id  = aws_subnet.super_secret_subnet.id
  private_ip = var.file_server_private_ip

  key_name = var.win_rsa_public_key.key_name

  user_data         = file("./utils/user_data.txt") # this is relative to where terraform is called from
  get_password_data = true

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"
  }

  vpc_security_group_ids = [
    aws_security_group.super_secret_internal.id,
    var.secops_access_sg.id,
    aws_security_group.super_secret_internet_access.id,
    var.adds_access_sg.id,
    aws_security_group.super_secret_file_server_access.id,
  ]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-file_server-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# sql_server instance
resource "aws_instance" "sql_server" {
  # type
  ami           = data.aws_ami.sql_server_ami.id
  instance_type = var.sql_server_instance_type

  subnet_id  = aws_subnet.super_secret_subnet.id
  private_ip = var.sql_server_private_ip

  key_name = var.win_rsa_public_key.key_name

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"

  }

  user_data         = file("./utils/user_data.txt") # this is relative to where terraform is called from
  get_password_data = true

  vpc_security_group_ids = [
    aws_security_group.super_secret_internal.id,
    var.secops_access_sg.id,
    aws_security_group.super_secret_internet_access.id,
    var.adds_access_sg.id,
    aws_security_group.super_secret_sql_server_access.id,
  ]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-sql_server-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}