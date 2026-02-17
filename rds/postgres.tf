resource "aws_db_instance" "strapi" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = "db.t2.micro"
  name                 = "strapidb"
  username             = var.db_user
  password             = var.db_password
  publicly_accessible  = true
  skip_final_snapshot  = true
}

