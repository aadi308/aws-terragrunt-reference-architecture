locals {
  environment_config = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  environment        = local.environment_config.locals.environment
  aws_region         = local.environment_config.locals.aws_region
  tags               = local.environment_config.locals.tags
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../modules/monitoring"
}

dependency "ecs" {
  config_path = "${get_terragrunt_dir()}/../ecs-service"
  mock_outputs = {
    cluster_name             = "reference-placeholder"
    service_name             = "reference-placeholder"
    load_balancer_arn_suffix = "app/reference/0000000000000000"
    target_group_arn_suffix  = "targetgroup/reference/0000000000000000"
  }
}

inputs = {
  name                     = "reference-${local.environment}"
  aws_region               = local.aws_region
  alarm_actions            = []
  tags                     = local.tags
  cluster_name             = dependency.ecs.outputs.cluster_name
  service_name             = dependency.ecs.outputs.service_name
  load_balancer_arn_suffix = dependency.ecs.outputs.load_balancer_arn_suffix
  target_group_arn_suffix  = dependency.ecs.outputs.target_group_arn_suffix
}
