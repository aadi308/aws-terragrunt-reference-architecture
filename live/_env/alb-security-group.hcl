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
    vpc_id   = "vpc-00000000000000000"
    vpc_cidr = "10.0.0.0/16"
  }
}

inputs = {
  name        = "reference-${local.environment}-alb"
  description = "Allows public TLS traffic to the reference load balancer"
  vpc_id      = dependency.network.outputs.vpc_id
  tags        = local.tags

  ingress_rules = {
    https = {
      description = "Public HTTPS"
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  egress_rules = {
    service = {
      description = "HTTP to private application targets"
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = dependency.network.outputs.vpc_cidr
    }
  }
}
