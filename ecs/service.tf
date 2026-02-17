resource "aws_ecs_service" "strapi_service" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.strapi.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "EC2"
}

