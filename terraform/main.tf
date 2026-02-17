#############################################
# ECR Repository
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
# IAM Role & Instance Profile for EC2
#############################################

resource "aws_iam_role" "ecs_ec2_role" {
  name = "ecsEC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_policy" {
  role       = aws_iam_role.ecs_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile"
  role = aws_iam_role.ecs_ec2_role.name
}

#############################################
# Security Group for EC2
#############################################

resource "aws_security_group" "ecs_sg" {
  name   = "ecs-ec2-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#############################################
# Default VPC & Subnets
#############################################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#############################################
# ECS Optimized AMI
#############################################

data "aws_ami" "ecs" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"]
}

#############################################
# Launch Template
#############################################

resource "aws_launch_template" "ecs" {
  name_prefix   = "ecs-template-"
  image_id      = data.aws_ami.ecs.id
  instance_type = "t2.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ecs_sg.id]

  user_data = base64encode(<<EOF
#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user

# Login to ECR using EC2 instance role
$(aws ecr get-login --no-include-email --region us-east-1)

# Pull / build Strapi image
mkdir -p /home/ec2-user/strapi-app
cd /home/ec2-user/strapi-app
# Optionally, you could git clone your Strapi project here
docker build -t strapi-app:latest .
docker tag strapi-app:latest ${aws_ecr_repository.strapi.repository_url}:latest
docker push ${aws_ecr_repository.strapi.repository_url}:latest
EOF
  )
}

#############################################
# Auto Scaling Group for ECS EC2 Instances
#############################################

resource "aws_autoscaling_group" "ecs" {
  desired_capacity   = 1
  min_size           = 1
  max_size           = 1
  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }
}

#############################################
# ECS Task Definition (EC2)
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
# ECS Service
#############################################

resource "aws_ecs_service" "strapi" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = 1
  launch_type     = "EC2"
}

