
#############################################
# ECR
#############################################
resource "aws_ecr_repository" "strapi" {
  name = "strapi-app"
}

#############################################
# ECS Cluster
#############################################
resource "aws_ecs_cluster" "main" {
  name = "strapi-cluster"
}

#############################################
# ECS Task Definition
#############################################
resource "aws_ecs_task_definition" "strapi" {
  family       = "strapi-task"
  network_mode = "bridge"

  container_definitions = jsonencode([{
    name      = "strapi"
    image     = "${aws_ecr_repository.strapi.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = 1337
      hostPort      = 1337
    }]

    environment = [
      {
        name  = "DATABASE_HOST"
        value = aws_db_instance.strapi_db.address
      },
      {
        name  = "DATABASE_PORT"
        value = "5432"
      },
      {
        name  = "DATABASE_NAME"
        value = "postgres"
      },
      {
        name  = "DATABASE_USERNAME"
        value = "strapi"
      },
      {
        name  = "DATABASE_PASSWORD"
        value = "StrapiPassword123"
      }
    ]
  }])
}

#############################################
# ECS Service (single EC2 launch type)
#############################################
resource "aws_ecs_service" "strapi" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = 1
  launch_type     = "EC2"
}

