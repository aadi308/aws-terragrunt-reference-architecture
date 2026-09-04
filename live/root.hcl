locals {
  environment_config = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  environment        = local.environment_config.locals.environment
  aws_region         = local.environment_config.locals.aws_region
}

remote_state {
  backend = "s3"

  config = {
    bucket         = get_env("TF_STATE_BUCKET", "REPLACE_ME-terraform-state-bucket")
    key            = "${path_relative_to_include("root")}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = get_env("TF_LOCK_TABLE", "REPLACE_ME-terraform-lock-table")
  }

  generate = {
    path      = "backend.generated.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "provider" {
  path      = "provider.generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"

      default_tags {
        tags = {
          Environment = "${local.environment}"
          Project     = "aws-terragrunt-reference-architecture"
          ManagedBy   = "Terraform"
        }
      }
    }
  EOF
}

terraform {
  extra_arguments "safe_defaults" {
    commands  = get_terraform_commands_that_need_locking()
    arguments = ["-lock-timeout=5m"]
  }
}
