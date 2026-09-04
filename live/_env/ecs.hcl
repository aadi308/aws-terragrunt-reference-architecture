locals {
  environment_config = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  environment        = local.environment_config.locals.environment
  config             = local.environment_config.locals
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../modules/ecs-fargate"
}

dependency "network" {
  config_path = "${get_terragrunt_dir()}/../network"
  mock_outputs = {
    vpc_id             = "vpc-00000000000000000"
    public_subnet_ids  = ["subnet-00000000000000001", "subnet-00000000000000002"]
    private_subnet_ids = ["subnet-00000000000000003", "subnet-00000000000000004"]
  }
}

dependency "alb_security_group" {
  config_path = "${get_terragrunt_dir()}/../alb-security-group"
  mock_outputs = {
    security_group_id = "sg-00000000000000001"
  }
}

dependency "service_security_group" {
  config_path = "${get_terragrunt_dir()}/../service-security-group"
  mock_outputs = {
    security_group_id = "sg-00000000000000002"
  }
}

inputs = {
  name                       = "reference-${local.environment}"
  container_image            = "public.ecr.aws/nginx/nginx:1.27-alpine"
  container_port             = 80
  cpu                        = local.config.task_cpu
  memory                     = local.config.task_memory
  desired_count              = local.config.desired_count
  log_retention_days         = local.config.log_retention_days
  enable_deletion_protection = local.config.enable_deletion_protection
  certificate_arn            = get_env("TF_VAR_certificate_arn", "REPLACE_ME_WITH_ACM_CERTIFICATE_ARN")
  tags                       = local.config.tags
  vpc_id                     = dependency.network.outputs.vpc_id
  public_subnet_ids          = dependency.network.outputs.public_subnet_ids
  private_subnet_ids         = dependency.network.outputs.private_subnet_ids
  alb_security_group_id      = dependency.alb_security_group.outputs.security_group_id
  service_security_group_id  = dependency.service_security_group.outputs.security_group_id
}
