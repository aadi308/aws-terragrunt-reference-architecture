locals {
  environment_config = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  environment        = local.environment_config.locals.environment
  tags               = local.environment_config.locals.tags
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../modules/security-group"
}

dependency "network" {
  config_path = "${get_terragrunt_dir()}/../network"
  mock_outputs = {
    vpc_id = "vpc-00000000000000000"
  }
}

dependency "alb_security_group" {
  config_path = "${get_terragrunt_dir()}/../alb-security-group"
  mock_outputs = {
    security_group_id = "sg-00000000000000000"
  }
}

inputs = {
  name        = "reference-${local.environment}-service"
  description = "Allows only load-balancer traffic to private Fargate tasks"
  vpc_id      = dependency.network.outputs.vpc_id
  tags        = local.tags

  ingress_rules = {
    alb = {
      description                  = "Application traffic from the ALB"
      from_port                    = 80
      to_port                      = 80
      ip_protocol                  = "tcp"
      referenced_security_group_id = dependency.alb_security_group.outputs.security_group_id
    }
  }

  egress_rules = {
    https = {
      description = "TLS egress for image pulls and AWS APIs"
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}
