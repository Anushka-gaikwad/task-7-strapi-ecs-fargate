variable "aws_region" {
  default = "us-east-1"
}

variable "db_user" {
  default = "strapi"
}

variable "db_password" {
  default = "Strapi@123"
}

variable "ecs_instance_type" {
  default = "t2.micro"
}

variable "ecs_desired_count" {
  default = 1
}

variable "ecr_repo_name" {
  default = "strapi-repo"
}

