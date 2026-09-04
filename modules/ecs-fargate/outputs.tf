output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "load_balancer_dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = aws_lb.this.dns_name
}

output "load_balancer_arn_suffix" {
  description = "ALB ARN suffix used by CloudWatch metrics."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "Target group ARN suffix used by CloudWatch metrics."
  value       = aws_lb_target_group.this.arn_suffix
}

