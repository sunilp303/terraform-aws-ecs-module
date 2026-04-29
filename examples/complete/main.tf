##############################################################
# Example: Complete Fargate ECS Service with ALB
##############################################################

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  name        = "my-app"
  environment = "dev"
  region      = "us-east-1"

  tags = {
    Environment = local.environment
    Project     = local.name
    ManagedBy   = "Terraform"
  }
}

##############################################################
# VPC (using existing VPC in this example)
##############################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

##############################################################
# ALB Target Group (pre-existing)
##############################################################
# This assumes an ALB and target group already exist.
# You can create them using the terraform-aws-alb module.

##############################################################
# ECS Module
##############################################################
module "ecs" {
  source = "../../" # or "github.com/sunilp303/terraform-aws-ecs-module"

  # Cluster
  cluster_name              = "${local.name}-cluster"
  enable_container_insights = true
  capacity_providers        = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 1
    }
  ]

  # Task Definition
  task_family              = "${local.name}-task"
  task_cpu                 = 512
  task_memory              = 1024
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  runtime_platform = {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = local.name
      image     = "nginx:latest"
      cpu       = 512
      memory    = 1024
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "ENV", value = local.environment }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${local.name}"
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  # Service
  service_name                      = "${local.name}-service"
  desired_count                     = 2
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  force_new_deployment              = true
  health_check_grace_period_seconds = 30
  enable_execute_command            = true

  deployment_circuit_breaker = {
    enable   = true
    rollback = true
  }

  # Networking
  vpc_id           = data.aws_vpc.default.id
  subnet_ids       = data.aws_subnets.private.ids
  assign_public_ip = false

  create_security_group = true
  security_group_ingress_rules = [
    {
      from_port                    = 80
      to_port                      = 80
      protocol                     = "tcp"
      referenced_security_group_id = null # Replace with ALB SG id
      cidr_ipv4                    = "10.0.0.0/8"
      description                  = "Allow HTTP from within VPC"
    }
  ]

  # ALB Integration
  load_balancers = [
    {
      target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-tg/abc"
      container_name   = local.name
      container_port   = 80
    }
  ]

  # IAM
  create_iam_roles = true
  task_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]
  task_secrets_arns = [
    "arn:aws:secretsmanager:us-east-1:123456789012:secret:my-app/*"
  ]

  # Auto Scaling
  enable_autoscaling             = true
  autoscaling_min_capacity       = 1
  autoscaling_max_capacity       = 10
  autoscaling_cpu_target         = 70
  autoscaling_memory_target      = 80
  autoscaling_scale_in_cooldown  = 300
  autoscaling_scale_out_cooldown = 60

  # CloudWatch Logs
  create_cloudwatch_log_group   = true
  cloudwatch_log_retention_days = 30

  tags = local.tags
}

##############################################################
# Outputs
##############################################################
output "cluster_arn" {
  value = module.ecs.cluster_arn
}

output "service_name" {
  value = module.ecs.service_name
}

output "task_definition_arn" {
  value = module.ecs.task_definition_arn
}

output "security_group_id" {
  value = module.ecs.security_group_id
}
