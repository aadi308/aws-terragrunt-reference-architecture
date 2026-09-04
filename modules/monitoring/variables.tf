variable "name" {
  description = "Name prefix for monitoring resources."
  type        = string
}

variable "aws_region" {
  description = "AWS region displayed by dashboard widgets."
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name."
  type        = string
}

variable "service_name" {
  description = "ECS service name."
  type        = string
}

variable "load_balancer_arn_suffix" {
  description = "ALB ARN suffix for metric dimensions."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix for metric dimensions."
  type        = string
}

variable "alarm_actions" {
  description = "SNS topic ARNs or other actions invoked when alarms enter ALARM."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to supported resources."
  type        = map(string)
  default     = {}
}

