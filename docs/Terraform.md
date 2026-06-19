## Terraform

### Overview
Terraform is an IaC framework that is used to define, build and destroy the infrastructure for `Project: Responder`. We have two separate terraform code bases which was originally designed to facilitate automation via CI/CD pipelines. At this moment, that is not currently implemented.

The `builder` code defines the main VPC, Internet Gateway, subnet and a linux bastion server. In future, this linux bastion host could be used as a build server in CI/CD implementations.

The main code defines all of the other infrastructure that makes up `Project: Responder`.

### Structure
The Terraform code-base is structured in to 5 modules and each module defines a distinct set of infrastructure.
- core: Retrieves the details of the VPC and Internet Gateway, defines the key pairs which facilitate access to the windows and linux servers in the environment.
- corp: Defines the subnet, routing, security groups and instances that are part of the corp subnet.
- public: Defines the subnet, routing, security groups, external IP mappings and instances that are part of the public subnet.
- secops: Retrieves the details of the secops subnet, defines security groups and a windows instance.
- super_secret: Defines the subnet, routing, security groups and instances that are part of the super_secret subnet.

### Variables
The variables used in terraform are all defined in the terraform.tfvars file. This file is used by terraform to determine the value of variables at build time. Terraform also uses ths file to check current state against the definition when completing other actions (destroy/validate). Variables are passed through to each module via the main.tf file.

### Workspaces
Terraform workspaces are used to separate the different environments logically. We use 5 workspaces for the 5 different environments, switching to the workspace when we need to work on a specific environment.

The 5 workspaces are:
- amer
- apac
- emea
- star
- test-env

### Backend State

Backend is defined in `terraform/main.tf` using a partial configuration. The
S3 bucket name is provided at init time via `$TERRAFORM_STATE_BUCKET` (set in
`.env`, see `.env.example`). The backend state allows multiple people to
operate on the state as it is in a shared location. Resource locking via the
state lock prevents concurrent operations.

```
terraform {
    required_version = ">= 0.13"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
    backend "s3" {
        # bucket supplied via -backend-config at init time
        workspace_key_prefix = "project-responder-workspaces"
        key    = "terraform.tfstate"
        region = "ap-southeast-2"
        dynamodb_table = "terraform-s3-state-lock"
  }
}
```
