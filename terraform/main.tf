module "ecr" {
  source    = "./modules/ecr"
  repo_name = var.app_name
}

module "vpc" {
  source = "./modules/vpc"
}

module "ecs" {
  source = "./modules/ecs"
}

module "iam" {
  source = "./modules/iam"
}

module "task_definition" {
  source             = "./modules/task-definition"
  execution_role_arn = module.iam.execution_role_arn
  image_uri          = var.image_uri
  container_port     = var.container_port
}

module "service" {
  source       = "./modules/service"
  cluster_id   = module.ecs.cluster_id
  task_def_arn = module.task_definition.task_def_arn
  subnets      = module.vpc.subnets
  sg_id        = module.vpc.sg_id
}
