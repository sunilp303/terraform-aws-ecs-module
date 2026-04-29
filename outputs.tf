##############################################################
# ECS Cluster Outputs
##############################################################
output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = try(aws_ecs_cluster.this[0].id, null)
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = try(aws_ecs_cluster.this[0].arn, null)
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = try(aws_ecs_cluster.this[0].name, null)
}

##############################################################
# Task Definition Outputs
##############################################################
output "task_definition_arn" {
  description = "Full ARN of the task definition (family:revision)"
  value       = try(aws_ecs_task_definition.this[0].arn, null)
}

output "task_definition_family" {
  description = "Family name of the task definition"
  value       = try(aws_ecs_task_definition.this[0].family, null)
}

output "task_definition_revision" {
  description = "Revision number of the task definition"
  value       = try(aws_ecs_task_definition.this[0].revision, null)
}

##############################################################
# ECS Service Outputs
##############################################################
output "service_id" {
  description = "ID of the ECS service"
  value       = try(aws_ecs_service.this[0].id, null)
}

output "service_name" {
  description = "Name of the ECS service"
  value       = try(aws_ecs_service.this[0].name, null)
}

output "service_cluster" {
  description = "ARN of the cluster the ECS service belongs to"
  value       = try(aws_ecs_service.this[0].cluster, null)
}

output "service_desired_count" {
  description = "Desired count of the ECS service"
  value       = try(aws_ecs_service.this[0].desired_count, null)
}

##############################################################
# IAM Outputs
##############################################################
output "execution_role_arn" {
  description = "ARN of the ECS task execution IAM role"
  value       = try(aws_iam_role.ecs_execution[0].arn, null)
}

output "execution_role_name" {
  description = "Name of the ECS task execution IAM role"
  value       = try(aws_iam_role.ecs_execution[0].name, null)
}

output "task_role_arn" {
  description = "ARN of the ECS task IAM role"
  value       = try(aws_iam_role.ecs_task[0].arn, null)
}

output "task_role_name" {
  description = "Name of the ECS task IAM role"
  value       = try(aws_iam_role.ecs_task[0].name, null)
}

##############################################################
# Security Group Outputs
##############################################################
output "security_group_id" {
  description = "ID of the ECS service security group"
  value       = try(aws_security_group.ecs_service[0].id, null)
}

output "security_group_arn" {
  description = "ARN of the ECS service security group"
  value       = try(aws_security_group.ecs_service[0].arn, null)
}

##############################################################
# CloudWatch Outputs
##############################################################
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = try(aws_cloudwatch_log_group.this[0].name, null)
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = try(aws_cloudwatch_log_group.this[0].arn, null)
}

##############################################################
# Auto Scaling Outputs
##############################################################
output "autoscaling_target_resource_id" {
  description = "Resource ID of the App Auto Scaling target"
  value       = try(aws_appautoscaling_target.ecs[0].resource_id, null)
}
