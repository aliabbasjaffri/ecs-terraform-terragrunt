locals {
  region = "eu-central-1"

  version_terraform    = "=1.2.1"
  version_terragrunt   = "=0.37.1"
  version_provider_aws = "=4.15.1"

  root_tags = {
    project = "ecs-terraform-terragrunt"
  }
}

generate "provider_global" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = "${local.version_terraform}"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "${local.version_provider_aws}"
    }
  }
}

provider "aws" {
  region = "${local.region}"
}
EOF
}


remote_state {
  backend = "s3"
  config = {
    bucket         = "ecs-terraform-terragrunt-state-bucket"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    encrypt        = true
    region         = local.region
    dynamodb_table = "terraform-locks-table"
  }
}