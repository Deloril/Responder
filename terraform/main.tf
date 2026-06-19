###################################
## Terraform Core / AWS Provider ##
###################################

terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.20.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
  # Partial backend configuration. The bucket name is environment-specific and
  # provided at init time via -backend-config or `make init`, which reads
  # TERRAFORM_STATE_BUCKET from .env (see .env.example).
  backend "s3" {
    workspace_key_prefix = "project-responder-workspaces"
    key                  = "terraform.tfstate"
    region               = "ap-southeast-2"
    dynamodb_table       = "terraform-s3-state-lock"
  }
}

# Detect the OS username at plan time so deployed resources are tagged with the
# person that created them rather than the workspace/region name.
data "external" "username" {
  program = ["sh", "-c", "printf '{\"username\":\"%s\"}' \"$USER\""]
}

locals {
  region   = lookup(var.workspace_mapping, terraform.workspace)
  username = data.external.username.result.username
  # Short form for places with strict naming rules (Windows NetBIOS computer_name
  # is 15 chars max and disallows dots).
  username_short = element(split(".", local.username), 0)

  # Public IP of the machine running terraform, allowlisted for SSH/RDP/etc.
  # Captured at apply time so the lab "just works" from wherever the operator
  # runs `make build-*`. Add CIDRs to `extra_trusted_networks` (e.g. teammates'
  # IPs, a corp VPN range) to extend access without re-applying from each box.
  caller_ip        = chomp(data.http.caller_ip.response_body)
  trusted_networks = concat(["${local.caller_ip}/32"], var.extra_trusted_networks)
}

# checkip.amazonaws.com is run by AWS, returns just the source IP, no
# rate-limiting concerns for terraform apply cadence.
data "http" "caller_ip" {
  url = "https://checkip.amazonaws.com"
}

provider "aws" {
  region = local.region
}

###############
## Resources ##
###############

## VPC 
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    managed-by          = "terraform-responder"
    Name                = "${local.username}-vpc-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

## Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    managed-by          = "terraform-responder"
    Name                = "${local.username}-igw-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

## SSH public key 
resource "aws_key_pair" "ssh_public_key" {
  public_key = file(var.ssh_public_key_file)
  tags = {
    managed-by          = "terraform-responder"
    Name                = "${local.username}-ssh_key_pair-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# Secops subnet
resource "aws_subnet" "secops_subnet" {
  vpc_id = aws_vpc.vpc.id

  cidr_block              = var.secops_subnet_cidr
  availability_zone       = "${local.region}a"
  map_public_ip_on_launch = true

  tags = {
    managed-by          = "terraform-responder"
    Name                = "${local.username}-secops_subnet-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

#Route Table
resource "aws_route_table" "secops_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    managed-by          = "terraform-responder"
    Name                = "${local.username}-secops_subnet_route_table-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

#Route table association
resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.secops_subnet.id
  route_table_id = aws_route_table.secops_route_table.id
}

## Security Groups
# secops internal SG
resource "aws_security_group" "secops_internal" {
  name        = "secops_internal"
  description = "Security group rules for internal VPC communications in secops"
  vpc_id      = aws_vpc.vpc.id

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

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpc_cidr]
  }
  tags = {
    managed-by          = "terraform-responder"
    Name                = "${local.username}-secops_internal_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

resource "aws_security_group" "secops_internet_access" {
  name        = "secops_internet_access"
  description = "Security group rules for secops instances to reach the internet"
  vpc_id      = aws_vpc.vpc.id

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    managed-by          = "terraform-responder"
    Name                = "${local.username}-secops_internet_access_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# secops access SG
resource "aws_security_group" "secops_access" {
  name        = "secops_access"
  description = "Security group rules for internal VPC communications to all hosts"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.secops_subnet_cidr]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.secops_subnet_cidr]
  }

  tags = {
    managed-by          = "terraform-responder"
    Name                = "${local.username}-secops_access_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# linux_bastion inbound
resource "aws_security_group" "linux_bastion_public_access" {
  name        = "linux_bastion public access"
  description = "Security group rules for the linux_bastion"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = local.trusted_networks
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    managed-by          = "terraform-responder"
    Name                = "${local.username}-linux_bastion_sg-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

# linux_bastion ami definition
data "aws_ami" "linux_bastion_server_ami" {
  most_recent = true
  owners      = [var.linux_bastion_server_ami_owner]

  filter {
    name   = "name"
    values = [var.linux_bastion_server_ami_name]
  }
}

# linux_bastion instance
resource "aws_instance" "linux_bastion" {
  # type
  ami           = data.aws_ami.linux_bastion_server_ami.id
  instance_type = var.linux_bastion_server_instance_type

  subnet_id                   = aws_subnet.secops_subnet.id
  private_ip                  = var.linux_bastion_server_private_ip
  associate_public_ip_address = true

  key_name = aws_key_pair.ssh_public_key.key_name

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = "arn:aws:kms:${local.region}:${var.aws_account_id}:key/${var.kms_key_id}"
  }

  vpc_security_group_ids = [
    aws_security_group.secops_internal.id,
    aws_security_group.linux_bastion_public_access.id,
    aws_security_group.secops_internet_access.id
  ]

  tags = {
    managed-by          = "terraform-responder"
    Name                = "${local.username}-linux_bastion-${var.project_name}"
    terraform-workspace = "${terraform.workspace}"
  }
}

#############
## Modules ##
#############

module "builder" {
  source = "./builder"

  # Project/Deployment variables
  project_name         = var.project_name
  region               = local.region
  builder_project_name = var.builder_project_name
  username             = local.username

  win_rsa_public_key_file = var.win_rsa_public_key_file
  ssh_public_key_file     = var.ssh_public_key_file

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    managed-by          = "terraform-responder"
    Name                = "${local.username}-vpc-${var.project_name}"
    created-by-username = local.username
  }
}

## Core ##
# - contains core resources like vpc, igw, key_pair

module "core" {
  source = "./core"

  # Project/Deployment variables
  project_name         = var.project_name
  region               = local.region
  builder_project_name = var.builder_project_name
  username             = local.username
  vpc_id               = aws_vpc.vpc.id
  igw_id               = aws_internet_gateway.igw.id

  # Module variables
  win_rsa_public_key_file = var.win_rsa_public_key_file
  ssh_public_key_file     = var.ssh_public_key_file
}

## Public ##
# - contains public resources such as nat_gateway, web_server
module "public" {
  source = "./public"

  # Project/Deployment variables
  project_name   = var.project_name
  region         = local.region
  username       = local.username
  aws_account_id = var.aws_account_id
  kms_key_id     = var.kms_key_id

  # Module variables
  vpc_id                    = module.core.vpc_id
  igw_id                    = module.core.igw_id
  public_subnet_cidr        = var.public_subnet_cidr
  trusted_networks          = local.trusted_networks
  web_server_instance_type  = var.web_server_instance_type
  web_server_private_ip     = var.web_server_private_ip
  win_rsa_public_key        = module.core.win_rsa_public_key
  corp_internal_sg          = module.corp.corp_internal_sg
  secops_access_sg          = aws_security_group.secops_access
  win_rsa_private_key_file  = var.win_rsa_private_key_file
  mail_server_ami_owner     = var.mail_server_ami_owner
  mail_server_ami_name      = var.mail_server_ami_name
  mail_server_instance_type = var.mail_server_instance_type
  mail_server_private_ip    = var.mail_server_private_ip
  ssh_public_key            = module.core.ssh_public_key
  firewall_instance_type    = var.firewall_instance_type
  firewall_private_ip       = var.firewall_private_ip
}

## Corp ##
# - contains resources such as DC and clients
module "corp" {
  source = "./corp"

  # Project/Deployment variables
  project_name   = var.project_name
  region         = local.region
  username       = local.username
  username_short = local.username_short
  aws_account_id = var.aws_account_id
  kms_key_id     = var.kms_key_id

  # Module variables
  vpc_id                   = module.core.vpc_id
  nat_gateway              = module.public.nat_gateway
  corp_subnet_cidr         = var.corp_subnet_cidr
  DC_ami_owner             = var.DC_ami_owner
  DC_ami_name              = var.DC_ami_name
  client_ami_owner         = coalesce(var.client_ami_owner, var.aws_account_id)
  client_ami_name          = var.client_ami_name
  DC_instance_type         = var.DC_instance_type
  DC_private_ip            = var.DC_private_ip
  client_instance_type     = var.client_instance_type
  client_1_private_ip      = var.client_1_private_ip
  client_2_private_ip      = var.client_2_private_ip
  client_3_private_ip      = var.client_3_private_ip
  client_1_domain_hostname = var.client_1_domain_hostname
  client_2_domain_hostname = var.client_2_domain_hostname
  client_3_domain_hostname = var.client_3_domain_hostname
  win_rsa_public_key       = module.core.win_rsa_public_key
  ssh_public_key           = module.core.ssh_public_key
  secops_access_sg         = aws_security_group.secops_access
  file_server_private_ip   = var.file_server_private_ip
  win_rsa_private_key_file = var.win_rsa_private_key_file
}

## SuperSecret (secret storage / vault network) ##
# - contains resources such as sql_server, file_server.
# - Reachable from the PAW tier only (corp clients no longer have direct path).
module "super_secret" {
  source = "./super_secret"

  # Project/Deployment variables
  project_name   = var.project_name
  region         = local.region
  username       = local.username
  aws_account_id = var.aws_account_id
  kms_key_id     = var.kms_key_id

  # Module variables
  vpc_id                    = module.core.vpc_id
  nat_gateway               = module.public.nat_gateway
  super_secret_subnet_cidr  = var.super_secret_subnet_cidr
  file_server_ami_owner     = var.file_server_ami_owner
  file_server_ami_name      = var.file_server_ami_name
  sql_server_ami_owner      = var.sql_server_ami_owner
  sql_server_ami_name       = var.sql_server_ami_name
  file_server_instance_type = var.file_server_instance_type
  file_server_private_ip    = var.file_server_private_ip
  sql_server_instance_type  = var.sql_server_instance_type
  sql_server_private_ip     = var.sql_server_private_ip
  win_rsa_public_key        = module.core.win_rsa_public_key
  ssh_public_key            = module.core.ssh_public_key
  secops_access_sg          = aws_security_group.secops_access
  corp_subnet_cidr          = var.corp_subnet_cidr
  paw_subnet_cidr           = var.paw_subnet_cidr
  adds_access_sg            = module.corp.adds_access_sg
  win_rsa_private_key_file  = var.win_rsa_private_key_file
}

## Privileged Access (PAW + Guacamole) ##
# - Two domain-joined Windows workstations and a Guacamole RDP gateway.
# - The only path corp users have to reach the secret-storage tier.
module "paw" {
  source = "./paw"

  project_name   = var.project_name
  region         = local.region
  username       = local.username
  username_short = local.username_short
  aws_account_id = var.aws_account_id
  kms_key_id     = var.kms_key_id

  vpc_id                   = module.core.vpc_id
  vpc_cidr                 = var.vpc_cidr
  nat_gateway              = module.public.nat_gateway
  paw_subnet_cidr          = var.paw_subnet_cidr
  corp_subnet_cidr         = var.corp_subnet_cidr
  super_secret_subnet_cidr = var.super_secret_subnet_cidr

  client_ami_owner = coalesce(var.client_ami_owner, var.aws_account_id)
  client_ami_name  = var.client_ami_name

  paw_instance_type     = var.paw_instance_type
  paw_1_private_ip      = var.paw_1_private_ip
  paw_1_domain_hostname = var.paw_1_domain_hostname
  paw_2_private_ip      = var.paw_2_private_ip
  paw_2_domain_hostname = var.paw_2_domain_hostname

  guac_ami_owner     = var.guac_ami_owner
  guac_ami_name      = var.guac_ami_name
  guac_instance_type = var.guac_instance_type
  guac_private_ip    = var.guac_private_ip

  win_rsa_public_key       = module.core.win_rsa_public_key
  ssh_public_key           = module.core.ssh_public_key
  secops_access_sg         = aws_security_group.secops_access
  adds_access_sg           = module.corp.adds_access_sg
  win_rsa_private_key_file = var.win_rsa_private_key_file
}

## Inner Firewalls ##
# - Linux NVAs (Ubuntu + iptables) sitting between DMZ-corp and corp-secret.
# - Real, attackable, observable hosts that IR responders can investigate.
module "firewalls" {
  source = "./firewalls"

  project_name   = var.project_name
  region         = local.region
  username       = local.username
  aws_account_id = var.aws_account_id
  kms_key_id     = var.kms_key_id

  vpc_id                   = module.core.vpc_id
  vpc_cidr                 = var.vpc_cidr
  public_subnet_id         = module.public.public_subnet_id
  public_subnet_cidr       = var.public_subnet_cidr
  corp_subnet_id           = module.corp.corp_subnet_id
  corp_subnet_cidr         = var.corp_subnet_cidr
  super_secret_subnet_id   = module.super_secret.super_secret_subnet_id
  super_secret_subnet_cidr = var.super_secret_subnet_cidr

  fw_inner_ami_owner       = var.fw_inner_ami_owner
  fw_inner_ami_name        = var.fw_inner_ami_name
  fw_inner_instance_type   = var.fw_inner_instance_type
  fw_dmz_corp_dmz_ip       = var.fw_dmz_corp_dmz_ip
  fw_dmz_corp_corp_ip      = var.fw_dmz_corp_corp_ip
  fw_corp_secret_corp_ip   = var.fw_corp_secret_corp_ip
  fw_corp_secret_secret_ip = var.fw_corp_secret_secret_ip

  ssh_public_key   = module.core.ssh_public_key
  secops_access_sg = aws_security_group.secops_access
}

## SecOps ##
# - contains secops resources such as bastions
module "secops" {
  source = "./secops"

  # Project/Deployment variables
  project_name         = var.project_name
  builder_project_name = var.builder_project_name
  region               = local.region
  username             = local.username
  aws_account_id       = var.aws_account_id
  kms_key_id           = var.kms_key_id

  # Module variables
  vpc_id                               = module.core.vpc_id
  vpc_cidr                             = var.vpc_cidr
  trusted_networks                     = local.trusted_networks
  igw_id                               = module.core.igw_id
  win_rsa_public_key                   = module.core.win_rsa_public_key
  ssh_public_key                       = module.core.ssh_public_key
  secops_subnet_cidr                   = var.secops_subnet_cidr
  secops_subnet_id                     = aws_subnet.secops_subnet.id
  secops_internal_sg_id                = aws_security_group.secops_internal.id
  secops_internet_access_sg_id         = aws_security_group.secops_internet_access.id
  secops_access_sg_id                  = aws_security_group.secops_access.id
  windows_bastion_server_ami_owner     = var.windows_bastion_server_ami_owner
  windows_bastion_server_ami_name      = var.windows_bastion_server_ami_name
  windows_bastion_server_instance_type = var.windows_bastion_server_instance_type
  windows_bastion_server_private_ip    = var.windows_bastion_server_private_ip
  linux_bastion_server_ami_owner       = var.linux_bastion_server_ami_owner
  linux_bastion_server_ami_name        = var.linux_bastion_server_ami_name
  linux_bastion_server_instance_type   = var.linux_bastion_server_instance_type
  linux_bastion_server_private_ip      = var.linux_bastion_server_private_ip
  win_rsa_private_key_file             = var.win_rsa_private_key_file
}

## Attacker ##
# - contains attacker resources
module "attacker" {
  source = "./attacker"

  # Project/Deployment variables
  project_name   = var.project_name
  region         = local.region
  username       = local.username
  aws_account_id = var.aws_account_id
  kms_key_id     = var.kms_key_id

  # Module variables
  attacker_vpc_cidr             = var.attacker_vpc_cidr
  attacker_subnet_cidr          = var.attacker_subnet_cidr
  victim_network_nat            = module.public.nat_gateway.public_ip
  linux_bastion_public_ip       = aws_instance.linux_bastion.public_ip
  trusted_networks              = local.trusted_networks
  attacker_server_ami_owner     = var.attacker_server_ami_owner
  attacker_server_ami_name      = var.attacker_server_ami_name
  attacker_server_instance_type = var.attacker_server_instance_type
  ssh_public_key                = module.core.ssh_public_key
}

# Allow the attacker box to reach the firewall/router (HTTP, HTTPS, SMTP).
# Defined here at root level to avoid circular dependency between public and attacker modules.
resource "aws_security_group_rule" "attacker_to_firewall_http" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["${module.attacker.attacker_server.public_ip}/32"]
  security_group_id = module.public.firewall_sg_id
  description       = "HTTP from attacker box"
}

resource "aws_security_group_rule" "attacker_to_firewall_https" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["${module.attacker.attacker_server.public_ip}/32"]
  security_group_id = module.public.firewall_sg_id
  description       = "HTTPS from attacker box"
}

resource "aws_security_group_rule" "attacker_to_firewall_smtp" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 25
  to_port           = 25
  cidr_blocks       = ["${module.attacker.attacker_server.public_ip}/32"]
  security_group_id = module.public.firewall_sg_id
  description       = "SMTP from attacker box for phishing simulation"
}