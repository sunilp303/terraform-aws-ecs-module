##############################################################
# ECS Cluster
##############################################################
resource "aws_ecs_cluster" "this" {
  count = var.create_cluster ? 1 : 0

  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  dynamic "configuration" {
    for_each = var.cluster_configuration != null ? [var.cluster_configuration] : []
    content {
      dynamic "execute_command_configuration" {
        for_each = try([configuration.value.execute_command_configuration], [])
        content {
          kms_key_id = try(execute_command_configuration.value.kms_key_id, null)
          logging    = try(execute_command_configuration.value.logging, "DEFAULT")

          dynamic "log_configuration" {
            for_each = try([execute_command_configuration.value.log_configuration], [])
            content {
              cloud_watch_encryption_enabled = try(log_configuration.value.cloud_watch_encryption_enabled, null)
              cloud_watch_log_group_name     = try(log_configuration.value.cloud_watch_log_group_name, null)
              s3_bucket_name                 = try(log_configuration.value.s3_bucket_name, null)
              s3_bucket_encryption_enabled   = try(log_configuration.value.s3_bucket_encryption_enabled, null)
              s3_key_prefix                  = try(log_configuration.value.s3_key_prefix, null)
            }
          }
        }
      }
    }
  }

  tags = merge(
    var.tags,
    { Name = var.cluster_name }
  )
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  count = var.create_cluster ? 1 : 0

  cluster_name       = aws_ecs_cluster.this[0].name
  capacity_providers = var.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy
    content {
      base              = try(default_capacity_provider_strategy.value.base, null)
      weight            = try(default_capacity_provider_strategy.value.weight, null)
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
    }
  }
}

##############################################################
# Task Definition
##############################################################
resource "aws_ecs_task_definition" "this" {
  count = var.create_task_definition ? 1 : 0

  family                   = var.task_family
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  network_mode             = var.network_mode
  requires_compatibilities = var.requires_compatibilities
  execution_role_arn       = var.create_iam_roles ? aws_iam_role.ecs_execution[0].arn : var.execution_role_arn
  task_role_arn            = var.create_iam_roles ? aws_iam_role.ecs_task[0].arn : var.task_role_arn

  container_definitions = var.container_definitions

  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value.name

      dynamic "efs_volume_configuration" {
        for_each = try([volume.value.efs_volume_configuration], [])
        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = try(efs_volume_configuration.value.root_directory, "/")
          transit_encryption      = try(efs_volume_configuration.value.transit_encryption, "DISABLED")
          transit_encryption_port = try(efs_volume_configuration.value.transit_encryption_port, null)

          dynamic "authorization_config" {
            for_each = try([efs_volume_configuration.value.authorization_config], [])
            content {
              access_point_id = try(authorization_config.value.access_point_id, null)
              iam             = try(authorization_config.value.iam, "DISABLED")
            }
          }
        }
      }

      dynamic "docker_volume_configuration" {
        for_each = try([volume.value.docker_volume_configuration], [])
        content {
          autoprovision = try(docker_volume_configuration.value.autoprovision, null)
          driver        = try(docker_volume_configuration.value.driver, null)
          driver_opts   = try(docker_volume_configuration.value.driver_opts, null)
          labels        = try(docker_volume_configuration.value.labels, null)
          scope         = try(docker_volume_configuration.value.scope, null)
        }
      }
    }
  }

  dynamic "runtime_platform" {
    for_each = var.runtime_platform != null ? [var.runtime_platform] : []
    content {
      operating_system_family = try(runtime_platform.value.operating_system_family, null)
      cpu_architecture        = try(runtime_platform.value.cpu_architecture, null)
    }
  }

  tags = merge(
    var.tags,
    { Name = var.task_family }
  )

  lifecycle {
    create_before_destroy = true
  }
}

##############################################################
# ECS Service
##############################################################
resource "aws_ecs_service" "this" {
  count = var.create_service ? 1 : 0

  name            = var.service_name
  cluster         = var.create_cluster ? aws_ecs_cluster.this[0].id : var.cluster_arn
  task_definition = var.create_task_definition ? aws_ecs_task_definition.this[0].arn : var.task_definition_arn
  desired_count   = var.desired_count

  launch_type                       = length(var.capacity_provider_strategy) > 0 ? null : var.launch_type
  platform_version                  = var.launch_type == "FARGATE" ? var.platform_version : null
  scheduling_strategy               = var.scheduling_strategy
  force_new_deployment              = var.force_new_deployment
  wait_for_steady_state             = var.wait_for_steady_state
  enable_execute_command            = var.enable_execute_command
  health_check_grace_period_seconds = var.health_check_grace_period_seconds
  propagate_tags                    = var.propagate_tags
  enable_ecs_managed_tags           = var.enable_ecs_managed_tags

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy
    content {
      base              = try(capacity_provider_strategy.value.base, null)
      weight            = try(capacity_provider_strategy.value.weight, 0)
      capacity_provider = capacity_provider_strategy.value.capacity_provider
    }
  }

  dynamic "network_configuration" {
    for_each = var.network_mode == "awsvpc" ? [1] : []
    content {
      subnets = var.subnet_ids
      security_groups = concat(
        var.create_security_group ? [aws_security_group.ecs_service[0].id] : [],
        var.security_group_ids
      )
      assign_public_ip = var.assign_public_ip
    }
  }

  dynamic "load_balancer" {
    for_each = var.load_balancers
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  dynamic "service_registries" {
    for_each = var.service_registries != null ? [var.service_registries] : []
    content {
      registry_arn   = service_registries.value.registry_arn
      port           = try(service_registries.value.port, null)
      container_name = try(service_registries.value.container_name, null)
      container_port = try(service_registries.value.container_port, null)
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.deployment_circuit_breaker != null ? [var.deployment_circuit_breaker] : []
    content {
      enable   = deployment_circuit_breaker.value.enable
      rollback = deployment_circuit_breaker.value.rollback
    }
  }

  dynamic "deployment_controller" {
    for_each = var.deployment_controller != null ? [var.deployment_controller] : []
    content {
      type = deployment_controller.value.type
    }
  }

  dynamic "ordered_placement_strategy" {
    for_each = var.ordered_placement_strategy
    content {
      type  = ordered_placement_strategy.value.type
      field = try(ordered_placement_strategy.value.field, null)
    }
  }

  dynamic "placement_constraints" {
    for_each = var.placement_constraints
    content {
      type       = placement_constraints.value.type
      expression = try(placement_constraints.value.expression, null)
    }
  }

  tags = merge(
    var.tags,
    { Name = var.service_name }
  )

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution,
    aws_iam_role_policy_attachment.ecs_task,
  ]

  lifecycle {
    ignore_changes = [desired_count]
  }
}

##############################################################
# Auto Scaling
##############################################################
resource "aws_appautoscaling_target" "ecs" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${var.create_cluster ? aws_ecs_cluster.this[0].name : var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.this]
}

resource "aws_appautoscaling_policy" "cpu" {
  count = var.enable_autoscaling && var.autoscaling_cpu_target != null ? 1 : 0

  name               = "${var.service_name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "memory" {
  count = var.enable_autoscaling && var.autoscaling_memory_target != null ? 1 : 0

  name               = "${var.service_name}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.autoscaling_memory_target
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown
  }
}

##############################################################
# CloudWatch Log Group
##############################################################
resource "aws_cloudwatch_log_group" "this" {
  count = var.create_cloudwatch_log_group ? 1 : 0

  name              = var.cloudwatch_log_group_name != null ? var.cloudwatch_log_group_name : "/ecs/${var.service_name}"
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = var.cloudwatch_log_kms_key_id

  tags = merge(
    var.tags,
    { Name = "/ecs/${var.service_name}" }
  )
}
