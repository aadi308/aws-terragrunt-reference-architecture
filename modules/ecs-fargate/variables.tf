variable "name" {
  description = "Name prefix for service resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC that hosts the load balancer and service."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the internet-facing load balancer."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Fargate tasks."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID attached to the load balancer."
  type        = string
}

variable "service_security_group_id" {
  description = "Security group ID attached to Fargate tasks."
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener."
  type        = string
}

variable "container_image" {
  description = "Container image reference. Pin an approved digest in production."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:1.27-alpine"
}

variable "container_port" {
  description = "Port exposed by the application container."
  type        = number
  default     = 80
}

variable "cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired task count."
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "CloudWatch application log retention."
  type        = number
  default     = 365
}

variable "enable_deletion_protection" {
  description = "Protect the load balancer from accidental deletion."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to supported resources."
  type        = map(string)
  default     = {}
}
