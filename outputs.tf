output "db_endpoint" {
  value = aws_db_instance.strapi.endpoint
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.strapi.name
}

output "ecs_service_name" {
  value = aws_ecs_service.strapi_service.name
}

