##############################################################
# General
##############################################################
variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

##############################################################
# ECS Cluster
##############################################################
variable "create_cluster" {
  description = "Whether to create an ECS cluster"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "cluster_arn" {
  description = "ARN of an existing ECS cluster. Required when create_cluster = false"
  type        = string
  default     = null
}

variable "enable_container_insights" {
  description = "Whether to enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}

variable "cluster_configuration" {
  description = "Map of cluster configuration settings (e.g., execute_command_configuration)"
  type        = any
  default     = null
}

variable "capacity_providers" {
  description = "List of capacity providers to use for the cluster (e.g., FARGATE, FARGATE_SPOT)"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy for the cluster"
  type        = list(map(any))
  default = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 1
    }
  ]
}

##############################################################
# Task Definition
##############################################################
variable "create_task_definition" {
  description = "Whether to create an ECS task definition"
  type        = bool
  default     = true
}

variable "task_family" {
  description = "Unique name for your task definition family"
  type        = string
  default     = null
}

variable "task_definition_arn" {
  description = "ARN of an existing task definition. Required when create_task_definition = false"
  type        = string
  default     = null
}

variable "task_cpu" {
  description = "Number of CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Amount of memory (MiB) for the task"
  type        = number
  default     = 512
}

variable "network_mode" {
  description = "Network mode for the task: awsvpc, bridge, host, or none"
  type        = string
  default     = "awsvpc"
}

variable "requires_compatibilities" {
  description = "Set of launch types required by the task: FARGATE or EC2"
  type        = list(string)
  default     = ["FARGATE"]
}

variable "container_definitions" {
  description = "JSON-encoded list of container definitions for the task"
  type        = string
}

variable "volumes" {
  description = "List of volume definitions for the task definition"
  type        = any
  default     = []
}

variable "runtime_platform" {
  description = "Runtime platform configuration (os family, cpu architecture)"
  type        = any
  default     = null
}

variable "execution_role_arn" {
  description = "ARN of the task execution role when create_iam_roles = false"
  type        = string
  default     = null
}

variable "task_role_arn" {
  description = "ARN of the task role when create_iam_roles = false"
  type        = string
  default     = null
}

##############################################################
# ECS Service
##############################################################
variable "create_service" {
  description = "Whether to create an ECS service"
  type        = bool
  default     = true
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "desired_count" {
  description = "Desired number of task instances to run"
  type        = number
  default     = 1
}

variable "launch_type" {
  description = "Launch type: FARGATE or EC2. Ignored if capacity_provider_strategy is set"
  type        = string
  default     = "FARGATE"
}

variable "platform_version" {
  description = "Fargate platform version (e.g., LATEST, 1.4.0)"
  type        = string
  default     = "LATEST"
}

variable "scheduling_strategy" {
  description = "Scheduling strategy: REPLICA or DAEMON"
  type        = string
  default     = "REPLICA"
}

variable "force_new_deployment" {
  description = "Enable forcing a new task deployment on update"
  type        = bool
  default     = true
}

variable "wait_for_steady_state" {
  description = "Wait for the service to reach a steady state before continuing"
  type        = bool
  default     = false
}

variable "enable_execute_command" {
  description = "Enable ECS Exec on the service (requires SSM agent in container)"
  type        = bool
  default     = false
}

variable "health_check_grace_period_seconds" {
  description = "Grace period (seconds) before health checks affect service replacement"
  type        = number
  default     = 0
}

variable "propagate_tags" {
  description = "Propagate tags from SERVICE or TASK_DEFINITION to tasks"
  type        = string
  default     = "SERVICE"
}

variable "enable_ecs_managed_tags" {
  description = "Enable ECS managed tags for tasks"
  type        = bool
  default     = true
}

variable "capacity_provider_strategy" {
  description = "Capacity provider strategies to use for the service"
  type        = list(map(any))
  default     = []
}

variable "load_balancers" {
  description = "List of load balancer config: target_group_arn, container_name, container_port"
  type        = list(map(any))
  default     = []
}

variable "service_registries" {
  description = "Service discovery registry config block"
  type        = any
  default     = null
}

variable "deployment_circuit_breaker" {
  description = "Deployment circuit breaker config: enable = bool, rollback = bool"
  type        = object({ enable = bool, rollback = bool })
  default     = { enable = true, rollback = true }
}

variable "deployment_controller" {
  description = "Deployment controller type: ECS (default), CODE_DEPLOY, or EXTERNAL"
  type        = object({ type = string })
  default     = { type = "ECS" }
}

variable "ordered_placement_strategy" {
  description = "Task placement strategy rules (for EC2 launch type)"
  type        = list(map(string))
  default     = []
}

variable "placement_constraints" {
  description = "Task placement constraints (for EC2 launch type)"
  type        = list(map(string))
  default     = []
}

##############################################################
# Networking
##############################################################
variable "vpc_id" {
  description = "VPC ID where the ECS service runs"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ECS service (awsvpc mode)"
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Assign a public IP to the Fargate task (awsvpc mode)"
  type        = bool
  default     = false
}

variable "security_group_ids" {
  description = "Additional security group IDs to attach to the ECS service"
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Whether to create a dedicated security group for the ECS service"
  type        = bool
  default     = true
}

variable "security_group_ingress_rules" {
  description = "List of ingress rules for the ECS security group"
  type        = list(any)
  default     = []
}

variable "security_group_egress_rules" {
  description = "List of egress rules for the ECS security group"
  type        = list(any)
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  ]
}

##############################################################
# IAM
##############################################################
variable "create_iam_roles" {
  description = "Whether to create ECS execution and task IAM roles"
  type        = bool
  default     = true
}

variable "task_secrets_arns" {
  description = "List of Secrets Manager / SSM ARNs the execution role can read"
  type        = list(string)
  default     = []
}

variable "task_role_policy_arns" {
  description = "List of managed policy ARNs to attach to the ECS task role"
  type        = list(string)
  default     = []
}

variable "task_role_inline_policy" {
  description = "Inline JSON policy document for the ECS task role"
  type        = string
  default     = null
}

##############################################################
# Auto Scaling
##############################################################
variable "enable_autoscaling" {
  description = "Whether to enable Application Auto Scaling for the ECS service"
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks for auto scaling"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks for auto scaling"
  type        = number
  default     = 10
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization (%) for auto scaling. Set to null to disable"
  type        = number
  default     = 70
}

variable "autoscaling_memory_target" {
  description = "Target memory utilization (%) for auto scaling. Set to null to disable"
  type        = number
  default     = null
}

variable "autoscaling_scale_in_cooldown" {
  description = "Scale-in cooldown period in seconds"
  type        = number
  default     = 300
}

variable "autoscaling_scale_out_cooldown" {
  description = "Scale-out cooldown period in seconds"
  type        = number
  default     = 60
}

##############################################################
# CloudWatch Logs
##############################################################
variable "create_cloudwatch_log_group" {
  description = "Whether to create a CloudWatch log group for the ECS service"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group. Defaults to /ecs/<service_name>"
  type        = string
  default     = null
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "cloudwatch_log_kms_key_id" {
  description = "KMS key ID for encrypting CloudWatch logs"
  type        = string
  default     = null
}
