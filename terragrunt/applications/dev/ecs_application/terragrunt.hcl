include "root" {
  path   = find_in_parent_folders("root-config.hcl")
  expose = true
}

include "stage" {
  path   = find_in_parent_folders("stage.hcl")
  expose = true
}

locals {
  # merge tags
  local_tags = {
    "Name" = "ecs-application"
  }

  tags = merge(include.root.locals.root_tags, include.stage.locals.tags, local.local_tags)
}

dependency "vpc" {
  config_path                             = "${get_parent_terragrunt_dir("root")}/base-infrastructure/${include.stage.locals.stage}/vpc_subnet_module"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    vpc_id                  = "some_id"
    vpc_public_subnets_ids  = ["some-id"]
    vpc_private_subnets_ids = ["some-id"]
  }
}

dependency "ecs_cluster" {
  config_path                             = "${get_parent_terragrunt_dir("root")}/base-infrastructure/${include.stage.locals.stage}/ecs_cluster"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    aws_ecs_cluster_id = "some_id"
  }
}

dependency "aws_alb" {
  config_path                             = "${get_parent_terragrunt_dir("root")}/base-infrastructure/${include.stage.locals.stage}/aws_alb"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    aws_alb_arn          = "arn:aws:elasticloadbalancing:eu-central-1:643202173500:loadbalancer/app/ghost-alb/9XXX000XXX000XXX"
    aws_sg_egress_all_id = "some-id"
  }
}


generate "provider_global" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {}
  required_version = "${include.root.locals.version_terraform}"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "${include.root.locals.version_provider_aws}"
    }
  }
}

provider "aws" {
  region = "${include.root.locals.region}"
}
EOF
}

inputs = {
  ecs_task_execution_role = {
    policy_document = {
      actions     = ["sts:AssumeRole"]
      effect      = "Allow"
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    iam_role_name = "task-execution-role"
    iam_policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  }

  ecs_autoscale_role = {
    policy_document = {
      actions     = ["sts:AssumeRole"]
      effect      = "Allow"
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
    iam_role_name = "ecs-scale-application"
    iam_policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
  }

  ecs_task = {
    family                   = "ecs-task-family"
    container_image_name     = "ghost"
    container_image          = "ghost:alpine"
    container_image_port     = 2368
    cpu                      = 256
    memory                   = 512
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
  }

  ecs_service = {
    name            = "ecs_service"
    cluster         = dependency.ecs_cluster.outputs.aws_ecs_cluster_id
    launch_type     = "FARGATE"
    desired_count   = 3
    egress_all_id   = dependency.aws_alb.outputs.aws_sg_egress_all_id
    private_subnets = dependency.vpc.outputs.vpc_private_subnets_ids
  }

  vpc_id  = dependency.vpc.outputs.vpc_id
  alb_arn = dependency.aws_alb.outputs.aws_alb_arn
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/..//terraform/ecs_application"
}