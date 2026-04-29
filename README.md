# terraform-aws-ecs-module

A production-ready, opinionated Terraform module for deploying **AWS ECS (Fargate & EC2)** services — including cluster, task definition, IAM roles, security groups, auto scaling, and CloudWatch logging.

Inspired by [`terraform-aws-ec2-module`](https://github.com/sunilp303/terraform-aws-ec2-module).

---

## Features

- ✅ ECS Cluster with Container Insights & capacity providers
- ✅ Fargate and EC2 launch type support
- ✅ Task definition with volumes (EFS, Docker) and runtime platform
- ✅ ECS Service with ALB integration and service discovery
- ✅ Deployment circuit breaker with auto-rollback
- ✅ ECS Exec (SSM-based shell into containers)
- ✅ IAM execution + task roles with optional secrets access
- ✅ VPC security group with fine-grained ingress/egress rules
- ✅ Application Auto Scaling (CPU & memory target tracking)
- ✅ CloudWatch log group with configurable retention
- ✅ All resources taggable

---

## Usage

### Minimal — Fargate Service

```hcl
module "ecs" {
  source = "github.com/sunilp303/terraform-aws-ecs-module"

  cluster_name = "my-cluster"
  service_name = "my-service"
  task_family  = "my-task"

  task_cpu    = 256
  task_memory = 512

  container_definitions = jsonencode([{
    name      = "my-app"
    image     = "nginx:latest"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{ containerPort = 80, protocol = "tcp" }]
  }])

  vpc_id     = "vpc-0abc1234"
  subnet_ids = ["subnet-aaa", "subnet-bbb"]

  tags = { Environment = "dev" }
}
```

### Complete — Fargate + ALB + Auto Scaling

See [`examples/complete/main.tf`](examples/complete/main.tf) for a full working example.

---

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.3.0 |
| aws       | >= 5.0   |

---

## Inputs

### General

| Name   | Description                           | Type          | Default | Required |
|--------|---------------------------------------|---------------|---------|----------|
| `tags` | Map of tags to assign to all resources | `map(string)` | `{}`    | no       |

### ECS Cluster

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `create_cluster` | Whether to create an ECS cluster | `bool` | `true` | no |
| `cluster_name` | Name of the ECS cluster | `string` | — | **yes** |
| `cluster_arn` | ARN of an existing cluster (when `create_cluster = false`) | `string` | `null` | no |
| `enable_container_insights` | Enable CloudWatch Container Insights | `bool` | `true` | no |
| `capacity_providers` | List of capacity providers (FARGATE, FARGATE_SPOT) | `list(string)` | `["FARGATE","FARGATE_SPOT"]` | no |
| `default_capacity_provider_strategy` | Default capacity provider strategy | `list(map(any))` | FARGATE base=1 weight=1 | no |
| `cluster_configuration` | Advanced cluster configuration (exec logging etc.) | `any` | `null` | no |

### Task Definition

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `create_task_definition` | Whether to create a task definition | `bool` | `true` | no |
| `task_family` | Task definition family name | `string` | `null` | no |
| `task_definition_arn` | Existing task definition ARN | `string` | `null` | no |
| `task_cpu` | Task CPU units (256/512/1024/2048/4096) | `number` | `256` | no |
| `task_memory` | Task memory in MiB | `number` | `512` | no |
| `network_mode` | Network mode (awsvpc/bridge/host/none) | `string` | `"awsvpc"` | no |
| `requires_compatibilities` | Launch type requirements | `list(string)` | `["FARGATE"]` | no |
| `container_definitions` | JSON container definitions | `string` | — | **yes** |
| `volumes` | Task volume definitions (EFS, Docker) | `any` | `[]` | no |
| `runtime_platform` | OS family and CPU architecture | `any` | `null` | no |
| `execution_role_arn` | Existing execution role ARN | `string` | `null` | no |
| `task_role_arn` | Existing task role ARN | `string` | `null` | no |

### ECS Service

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `create_service` | Whether to create the ECS service | `bool` | `true` | no |
| `service_name` | Name of the ECS service | `string` | — | **yes** |
| `desired_count` | Desired task count | `number` | `1` | no |
| `launch_type` | FARGATE or EC2 | `string` | `"FARGATE"` | no |
| `platform_version` | Fargate platform version | `string` | `"LATEST"` | no |
| `force_new_deployment` | Force new deployment on apply | `bool` | `true` | no |
| `wait_for_steady_state` | Wait for steady state | `bool` | `false` | no |
| `enable_execute_command` | Enable ECS Exec | `bool` | `false` | no |
| `health_check_grace_period_seconds` | Grace period before health checks | `number` | `0` | no |
| `propagate_tags` | Tag propagation source | `string` | `"SERVICE"` | no |
| `load_balancers` | ALB target group bindings | `list(map(any))` | `[]` | no |
| `service_registries` | Service discovery config | `any` | `null` | no |
| `deployment_circuit_breaker` | Circuit breaker config | `object` | enable+rollback=true | no |
| `deployment_controller` | Deployment controller type | `object` | ECS | no |
| `capacity_provider_strategy` | Per-service capacity provider strategy | `list(map(any))` | `[]` | no |
| `ordered_placement_strategy` | EC2 task placement strategy | `list(map(string))` | `[]` | no |
| `placement_constraints` | EC2 placement constraints | `list(map(string))` | `[]` | no |

### Networking

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `vpc_id` | VPC ID | `string` | `null` | no |
| `subnet_ids` | Subnet IDs for the service | `list(string)` | `[]` | no |
| `assign_public_ip` | Assign public IP (Fargate awsvpc) | `bool` | `false` | no |
| `create_security_group` | Create service security group | `bool` | `true` | no |
| `security_group_ids` | Additional security group IDs | `list(string)` | `[]` | no |
| `security_group_ingress_rules` | Ingress rules | `list(any)` | `[]` | no |
| `security_group_egress_rules` | Egress rules | `list(any)` | allow all | no |

### IAM

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `create_iam_roles` | Create execution + task roles | `bool` | `true` | no |
| `task_secrets_arns` | Secrets Manager/SSM ARNs for execution role | `list(string)` | `[]` | no |
| `task_role_policy_arns` | Managed policy ARNs for task role | `list(string)` | `[]` | no |
| `task_role_inline_policy` | Inline JSON policy for task role | `string` | `null` | no |

### Auto Scaling

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `enable_autoscaling` | Enable App Auto Scaling | `bool` | `false` | no |
| `autoscaling_min_capacity` | Minimum task count | `number` | `1` | no |
| `autoscaling_max_capacity` | Maximum task count | `number` | `10` | no |
| `autoscaling_cpu_target` | CPU utilization target (%) | `number` | `70` | no |
| `autoscaling_memory_target` | Memory utilization target (%) | `number` | `null` | no |
| `autoscaling_scale_in_cooldown` | Scale-in cooldown (seconds) | `number` | `300` | no |
| `autoscaling_scale_out_cooldown` | Scale-out cooldown (seconds) | `number` | `60` | no |

### CloudWatch Logging

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `create_cloudwatch_log_group` | Create CloudWatch log group | `bool` | `true` | no |
| `cloudwatch_log_group_name` | Log group name (default: /ecs/<service_name>) | `string` | `null` | no |
| `cloudwatch_log_retention_days` | Log retention in days | `number` | `30` | no |
| `cloudwatch_log_kms_key_id` | KMS key for log encryption | `string` | `null` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | ECS Cluster ID |
| `cluster_arn` | ECS Cluster ARN |
| `cluster_name` | ECS Cluster Name |
| `task_definition_arn` | Task Definition ARN |
| `task_definition_family` | Task Definition Family |
| `task_definition_revision` | Task Definition Revision |
| `service_id` | ECS Service ID |
| `service_name` | ECS Service Name |
| `service_cluster` | Cluster ARN the service belongs to |
| `execution_role_arn` | Execution Role ARN |
| `execution_role_name` | Execution Role Name |
| `task_role_arn` | Task Role ARN |
| `task_role_name` | Task Role Name |
| `security_group_id` | Service Security Group ID |
| `security_group_arn` | Service Security Group ARN |
| `cloudwatch_log_group_name` | CloudWatch Log Group Name |
| `cloudwatch_log_group_arn` | CloudWatch Log Group ARN |
| `autoscaling_target_resource_id` | Auto Scaling Target Resource ID |

---

## ECS Exec (Shell into Containers)

Enable ECS Exec for interactive debugging:

```hcl
enable_execute_command = true
```

Then connect:

```bash
aws ecs execute-command \
  --cluster my-cluster \
  --task <task-id> \
  --container my-app \
  --interactive \
  --command "/bin/sh"
```

> The task role requires `ssmmessages:*` permissions — add them via `task_role_inline_policy`.

---

## EFS Volume Support

```hcl
volumes = [
  {
    name = "my-data"
    efs_volume_configuration = {
      file_system_id     = "fs-abc123"
      root_directory     = "/data"
      transit_encryption = "ENABLED"
    }
  }
]
```

---

## License

MIT — see [LICENSE](LICENSE)

---

## Author

[Sunil Pawar](https://github.com/sunilp303)
