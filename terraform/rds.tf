
# Security Group for RDS

resource "aws_security_group" "rds_sg" {
  name   = "rds-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "Allow Postgres"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Assignment simplicity only
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-security-group"
  }
}

# Subnet Group for RDS

resource "aws_db_subnet_group" "strapi_db_subnet" {
  name       = "strapi-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "strapi-db-subnet-group"
  }
}

# RDS PostgreSQL Instance

resource "aws_db_instance" "strapi_db" {
  identifier        = "strapi-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "strapidb"
  username = "strapi"
  password = "StrapiPassword123"

  publicly_accessible = true
  skip_final_snapshot = true

  db_subnet_group_name   = aws_db_subnet_group.strapi_db_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "strapi-postgres-db"
  }
}

