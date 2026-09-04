locals {
  environment_config = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  environment        = local.environment_config.locals.environment
  config             = local.environment_config.locals
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../modules/network"
}

inputs = {
  name                    = "reference-${local.environment}"
  vpc_cidr                = local.config.vpc_cidr
  availability_zones      = local.config.availability_zones
  public_subnet_cidrs     = local.config.public_subnet_cidrs
  private_subnet_cidrs    = local.config.private_subnet_cidrs
  enable_nat_gateway      = local.config.enable_nat_gateway
  flow_log_retention_days = local.config.log_retention_days
  tags                    = local.config.tags
}
