resource "aws_ecs_task_definition" "task" {
  family                   = "strapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name  = "strapi"
      image = var.image_uri

      portMappings = [{
        containerPort = var.container_port
        protocol      = "tcp"
      }]

      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "ADMIN_JWT_SECRET", value = "test1" },
        { name = "API_TOKEN_SALT", value = "test2" },
        { name = "APP_KEYS", value = "test3,test4,test5,test6" },
        { name = "JWT_SECRET", value = "test7" }
      ]
    }
  ])
}
