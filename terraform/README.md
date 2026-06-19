# `Project: Responder` - Terraform

To set up the environment for `Project: Responder`, terraform has been used as the IaC provider. Terraform is a cloud agnostic IaC framework that allows you to build and deploy infrastructure at scale.

`Project: Responder` contains five terraform modules, each module describes a logical section of the infrastructure. 
- core: Describes foundational AWS infrastructure such as the VPC and key pairs.
- public: Describes the public AWS infrastructure such as the NAT gateway and a public-facing webserver.
- corp: Describes the corporate resources such as client machines and the domain controller.
- super_secret: Describes the segregated subnet and protected sql and file server.
- secops: Describes the splunk and bastion resources for the environment.
---

## Running Terraform
This terraform deployment uses an AWS S3 backend, meaning that terraform state is stored in a shared backend. This allows multiple developers to operate on the same terraform state.

The S3 backend uses partial configuration — the bucket name is supplied at
init time from `$TERRAFORM_STATE_BUCKET` (set in `.env`, see `.env.example`).
The static portion looks like:
```
backend "s3" {
        workspace_key_prefix = "project-responder-workspaces"
        key    = "terraform.tfstate"
        region = "ap-southeast-2"
        dynamodb_table = "terraform-s3-state-lock"
  }
```
Run `make init` (or `terraform init -backend-config=bucket=$TERRAFORM_STATE_BUCKET`) to wire it up.

## Setting up Terraform
To set up terraform locally and connect to the `Project: Responder` terraform state: 
1. Download and install terraform to your local machine.
2. Clone the whole `Project: Responder` repository to you local machine.
3. Follow the steps below to build with terraform

## Building with Terraform
Note: In the root of this repository, there is a Makefile that can be used to automate the build and configuration of `Project: Responder`. Only use terraform directly if you know what you are doing!

To build the infrastructure in this repository with terraform, follow these steps:
1. Provide AWS credentials as environment variables. You'll need an admin role on the target AWS account; terraform assumes the account to deploy to is the account where the credentials are valid. Copy `../.env.example` to `../.env` and fill in your account ID, KMS key, state bucket and AWS profile (see `.env.example` for documentation).
2. Run `terraform init` to initialize your local terraform and connect to the backend terraform state. A success message should be shown if successfully connected to the `Project: Responder` terraform state. If you get an unauthorized message, check the AWS credentials are available as environment variables and that they are valid using `aws sts get-caller-identity`.
3. Run `terraform plan` to check the deployment plan is accurate and no errors are found.
4. Run `terraform apply` to deploy the infrastructure.
5. Run `terraform destroy` to tear down the infrastructure.


### Build Notes
- Terraform will drop various files that are then used as inputs to ansible, these files will be dropped in the correct location in the ansible directories. 

# Contributing
Feel free to contribute code/modules/improvements/bug fixes via a pull request. 
