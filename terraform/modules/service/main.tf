resource "aws_ecs_service" "service" {
  name            = "strapi-service"
  cluster         = var.cluster_id
  task_definition = var.task_def_arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = [var.sg_id]
    assign_public_ip = true
  }
}
