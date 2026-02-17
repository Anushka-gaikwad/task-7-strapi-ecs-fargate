resource "aws_db_instance" "strapi_db" {
  identifier          = "strapi-db"
  engine              = "postgres"
  engine_version      = "15"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  username            = "strapi"
  password            = "StrapiPassword123"
  publicly_accessible = true
  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.ecs_sg.id]
}

