variable "name" {
  description = "Security group name."
  type        = string
}

variable "description" {
  description = "Security group purpose."
  type        = string
}

variable "vpc_id" {
  description = "VPC that owns the security group."
  type        = string
}

variable "ingress_rules" {
  description = "Inbound rules. Set exactly one source per rule."
  type = map(object({
    description                  = string
    from_port                    = number
    to_port                      = number
    ip_protocol                  = string
    cidr_ipv4                    = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for rule in values(var.ingress_rules) :
      (rule.cidr_ipv4 != null) != (rule.referenced_security_group_id != null)
    ])
    error_message = "Each ingress rule must set exactly one source: cidr_ipv4 or referenced_security_group_id."
  }
}

variable "egress_rules" {
  description = "Outbound rules. Set exactly one destination per rule."
  type = map(object({
    description                  = string
    from_port                    = number
    to_port                      = number
    ip_protocol                  = string
    cidr_ipv4                    = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for rule in values(var.egress_rules) :
      (rule.cidr_ipv4 != null) != (rule.referenced_security_group_id != null)
    ])
    error_message = "Each egress rule must set exactly one destination: cidr_ipv4 or referenced_security_group_id."
  }
}

variable "tags" {
  description = "Tags applied to the security group."
  type        = map(string)
  default     = {}
}

