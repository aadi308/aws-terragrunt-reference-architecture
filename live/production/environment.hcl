locals {
  environment                = "production"
  aws_region                 = "us-east-1"
  vpc_cidr                   = "10.30.0.0/16"
  availability_zones         = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs        = ["10.30.0.0/24", "10.30.1.0/24", "10.30.2.0/24"]
  private_subnet_cidrs       = ["10.30.10.0/24", "10.30.11.0/24", "10.30.12.0/24"]
  enable_nat_gateway         = true
  task_cpu                   = 512
  task_memory                = 1024
  desired_count              = 3
  log_retention_days         = 365
  enable_deletion_protection = true
  tags = {
    Environment = "production"
    CostCenter  = "portfolio"
    Owner       = "platform-team"
  }
}
