##############################################################
# Security Group for ECS Service
##############################################################
resource "aws_security_group" "ecs_service" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.service_name}-ecs-sg"
  description = "Security group for ECS service ${var.service_name}"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    { Name = "${var.service_name}-ecs-sg" }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_service" {
  for_each = var.create_security_group ? { for idx, rule in var.security_group_ingress_rules : idx => rule } : {}

  security_group_id = aws_security_group.ecs_service[0].id

  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.protocol
  cidr_ipv4                    = try(each.value.cidr_ipv4, null)
  cidr_ipv6                    = try(each.value.cidr_ipv6, null)
  referenced_security_group_id = try(each.value.referenced_security_group_id, null)
  description                  = try(each.value.description, null)

  tags = merge(
    var.tags,
    { Name = try(each.value.description, "ecs-ingress-${each.key}") }
  )
}

resource "aws_vpc_security_group_egress_rule" "ecs_service" {
  for_each = var.create_security_group ? { for idx, rule in var.security_group_egress_rules : idx => rule } : {}

  security_group_id = aws_security_group.ecs_service[0].id

  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.protocol
  cidr_ipv4                    = try(each.value.cidr_ipv4, null)
  cidr_ipv6                    = try(each.value.cidr_ipv6, null)
  referenced_security_group_id = try(each.value.referenced_security_group_id, null)
  description                  = try(each.value.description, null)

  tags = merge(
    var.tags,
    { Name = try(each.value.description, "ecs-egress-${each.key}") }
  )
}
