locals {
  environment                = "dev"
  aws_region                 = "us-east-1"
  vpc_cidr                   = "10.10.0.0/16"
  availability_zones         = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs        = ["10.10.0.0/24", "10.10.1.0/24"]
  private_subnet_cidrs       = ["10.10.10.0/24", "10.10.11.0/24"]
  enable_nat_gateway         = true
  task_cpu                   = 256
  task_memory                = 512
  desired_count              = 1
  log_retention_days         = 365
  enable_deletion_protection = false
  tags = {
    Environment = "dev"
    CostCenter  = "portfolio"
    Owner       = "platform-team"
  }
}
