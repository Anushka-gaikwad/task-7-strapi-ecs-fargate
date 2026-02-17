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
# Launch Template for ECS EC2 Instances
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
amazon-linux-extras install docker git -y
service docker start
usermod -a -G docker ec2-user

# Login to ECR using EC2 instance role
$(aws ecr get-login --no-include-email --region ap-south-1)

# Pull your Strapi app from GitHub
cd /home/ec2-user
git clone https://github.com/Anushka-gaikwad/task-7-strapy-ecs-fargate.git strapi-app

# Build and push Docker image
cd strapi-app/app
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
  desired_capacity    = 1
  min_size            = 1
  max_size            = 1
  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }
}

