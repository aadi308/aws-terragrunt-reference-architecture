locals {
  common_tags = merge(var.tags, { ManagedBy = "Terraform" })
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name}-ecs-cpu-high"
  alarm_description   = "ECS service CPU utilization exceeded 80 percent for 10 minutes."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.name}-ecs-memory-high"
  alarm_description   = "ECS service memory utilization exceeded 80 percent for 10 minutes."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name          = "${var.name}-target-5xx"
  alarm_description   = "Targets returned five or more 5xx responses in five minutes."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions

  dimensions = {
    LoadBalancer = var.load_balancer_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.name}-service-health"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ECS CPU and memory"
          region = var.aws_region
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.service_name],
            [".", "MemoryUtilization", ".", ".", ".", "."],
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Target 5xx responses"
          region = var.aws_region
          metrics = [[
            "AWS/ApplicationELB",
            "HTTPCode_Target_5XX_Count",
            "LoadBalancer",
            var.load_balancer_arn_suffix,
            "TargetGroup",
            var.target_group_arn_suffix,
          ]]
          period = 300
          stat   = "Sum"
        }
      },
    ]
  })
}

