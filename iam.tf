##############################################################
# IAM - ECS Task Execution Role
##############################################################
data "aws_iam_policy_document" "ecs_assume_role" {
  count = var.create_iam_roles ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  count = var.create_iam_roles ? 1 : 0

  name               = "${var.service_name}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role[0].json

  tags = merge(
    var.tags,
    { Name = "${var.service_name}-ecs-execution-role" }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  count = var.create_iam_roles ? 1 : 0

  role       = aws_iam_role.ecs_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Optional: Allow reading secrets from SSM / Secrets Manager
resource "aws_iam_role_policy" "ecs_execution_secrets" {
  count = var.create_iam_roles && length(var.task_secrets_arns) > 0 ? 1 : 0

  name = "${var.service_name}-execution-secrets"
  role = aws_iam_role.ecs_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters",
          "ssm:GetParameter",
          "kms:Decrypt"
        ]
        Resource = var.task_secrets_arns
      }
    ]
  })
}

##############################################################
# IAM - ECS Task Role
##############################################################
resource "aws_iam_role" "ecs_task" {
  count = var.create_iam_roles ? 1 : 0

  name               = "${var.service_name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role[0].json

  tags = merge(
    var.tags,
    { Name = "${var.service_name}-ecs-task-role" }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  for_each = var.create_iam_roles ? toset(var.task_role_policy_arns) : toset([])

  role       = aws_iam_role.ecs_task[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "ecs_task_inline" {
  count = var.create_iam_roles && var.task_role_inline_policy != null ? 1 : 0

  name   = "${var.service_name}-task-inline-policy"
  role   = aws_iam_role.ecs_task[0].id
  policy = var.task_role_inline_policy
}
