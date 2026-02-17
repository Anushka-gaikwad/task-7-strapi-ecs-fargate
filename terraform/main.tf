#ECR
resource "aws_ecr_repository" "strapi" {
  name = "strapi-app"
}

#ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "strapi-cluster"
}

#IAM roles for ECS
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#Task defination
resource "aws_ecs_task_definition" "strapi" {
  family                   = "strapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
  {
    name  = "strapi"
    image = "${aws_ecr_repository.strapi.repository_url}:${var.image_tag}"
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
  }
])


#Service using default vpc
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#Service
resource "aws_ecs_service" "strapi" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    assign_public_ip = true
    security_groups  = []
  }
}


