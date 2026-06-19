##########
## Corp ##
##########

## Resources
# subnet
# route table
# route table association
# SGs
# Servers

## Outputs
# corp_internal_sg
# adds_access_sg
# DC server instance
# client_1
# client_2
# DC_password

# Corp subnet
resource "aws_subnet" "corp_subnet" {
  vpc_id = var.vpc_id

  cidr_block              = var.corp_subnet_cidr
  availability_zone       = "${var.region}a" # use availability zone A
  map_public_ip_on_launch = false            # this is a private subnet with NAT gateway, dont need public IPs

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-corp_subnet-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# Route Table
resource "aws_route_table" "corp" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.nat_gateway.id
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-corp_subnet_route_table-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# Route table association
resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.corp_subnet.id
  route_table_id = aws_route_table.corp.id
}


## Security Groups
# Corp internal SG
resource "aws_security_group" "corp_internal" {
  name        = "corp_internal"
  description = "Security group rules for internal VPC communications in corp"
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
    Name                = "${var.username}-corp_internal_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# Corp internet access SG
resource "aws_security_group" "corp_internet_access" {
  name        = "corp_internet_access"
  description = "Security group rules for corp instances to reach the internet"
  vpc_id      = var.vpc_id

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-corp_internet_access_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# ADDS_access
resource "aws_security_group" "adds_access" {
  name        = "adds_access"
  description = "Security group rules for ADDS communications"
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
    Name                = "${var.username}-adds_access-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}


## Servers
# DC ami definition
data "aws_ami" "DC_ami" {
  most_recent = true
  owners      = [var.DC_ami_owner]

  filter {
    name   = "name"
    values = [var.DC_ami_name]
  }
}

# Client ami definition
data "aws_ami" "client_ami" {
  most_recent = true
  owners      = [var.client_ami_owner]

  filter {
    name   = "name"
    values = [var.client_ami_name]
  }
}

# ebs key

data "aws_ebs_default_kms_key" "current" {}


# DC instance
resource "aws_instance" "DC" {
  # type
  ami           = data.aws_ami.DC_ami.id
  instance_type = var.DC_instance_type

  subnet_id  = aws_subnet.corp_subnet.id
  private_ip = var.DC_private_ip

  key_name = var.win_rsa_public_key.key_name

  user_data         = file("./utils/user_data.txt") # this is relative to where terraform is called from
  get_password_data = true

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"

  }

  vpc_security_group_ids = [
    aws_security_group.corp_internal.id,
    aws_security_group.corp_internet_access.id,
    var.secops_access_sg.id,
    aws_security_group.adds_access.id
  ]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-DC-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# Client instance
resource "aws_instance" "client_1" {
  # type
  ami           = data.aws_ami.client_ami.id
  instance_type = var.client_instance_type

  subnet_id  = aws_subnet.corp_subnet.id
  private_ip = var.client_1_private_ip

  key_name = var.win_rsa_public_key.key_name

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"
  }

  user_data = templatefile("${path.root}/utils/user_data_client.ps1.tpl", {
    computer_name = "${var.client_1_domain_hostname}-${var.username_short}"
  })
  get_password_data = false # dont need password info since we know the password already. This is hardcoded in main outputs.tf file.

  vpc_security_group_ids = [
    aws_security_group.corp_internal.id,
    aws_security_group.corp_internet_access.id,
    var.secops_access_sg.id,
  ]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-client_1-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# Client instance
resource "aws_instance" "client_2" {
  # type
  ami           = data.aws_ami.client_ami.id
  instance_type = var.client_instance_type

  subnet_id  = aws_subnet.corp_subnet.id
  private_ip = var.client_2_private_ip

  key_name = var.win_rsa_public_key.key_name

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"
  }

  user_data = templatefile("${path.root}/utils/user_data_client.ps1.tpl", {
    computer_name = "${var.client_2_domain_hostname}-${var.username_short}"
  })
  get_password_data = false # dont need password info since we know the password already. This is hardcoded in main outputs.tf file.

  vpc_security_group_ids = [
    aws_security_group.corp_internal.id,
    aws_security_group.corp_internet_access.id,
    var.secops_access_sg.id,
  ]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-client_2-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# Client instance
resource "aws_instance" "client_3" {
  ami           = data.aws_ami.client_ami.id
  instance_type = var.client_instance_type

  subnet_id  = aws_subnet.corp_subnet.id
  private_ip = var.client_3_private_ip

  key_name = var.win_rsa_public_key.key_name

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"
  }

  user_data = templatefile("${path.root}/utils/user_data_client.ps1.tpl", {
    computer_name = "${var.client_3_domain_hostname}-${var.username_short}"
  })
  get_password_data = false

  vpc_security_group_ids = [
    aws_security_group.corp_internal.id,
    aws_security_group.corp_internet_access.id,
    var.secops_access_sg.id,
  ]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-client_3-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

## Other Machines

data "aws_ami" "ubuntu2004_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server*"]
  }
}

resource "aws_instance" "Ubuntu_2004" {
  # type
  ami           = data.aws_ami.ubuntu2004_ami.id
  instance_type = "t3.medium"

  subnet_id  = aws_subnet.corp_subnet.id
  private_ip = "10.0.1.20"

  key_name = var.ssh_public_key.key_name

  root_block_device {
    delete_on_termination = true
    volume_size           = 200
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${var.region}:${var.aws_account_id}:key/${var.kms_key_id}"
  }

  vpc_security_group_ids = [
    aws_security_group.corp_internal.id,
    aws_security_group.corp_internet_access.id,
    var.secops_access_sg.id,
  ]

  tags = {
    managed-by          = "terraform"
    Name                = "${var.username}-Ubuntu_2004-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}