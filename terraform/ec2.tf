#############################################
# Security Group for EC2
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
# Single EC2 Instance
#############################################
resource "aws_instance" "ecs" {
  ami           = data.aws_ami.ecs.id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnets.default.ids[0]
  security_groups = [aws_security_group.ecs_sg.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<EOF
#!/bin/bash
yum update -y
amazon-linux-extras install docker git -y
service docker start
usermod -a -G docker ec2-user

# Login to ECR
$(aws ecr get-login --no-include-email --region ap-south-1)
EOF
}

#############################################
# ECS Optimized AMI
#############################################
data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

#############################################
# IAM Role & Instance Profile
#############################################
resource "aws_iam_role" "ecs_role" {
  name = "ecsEC2Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_attach" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ecsInstanceProfile"
  role = aws_iam_role.ecs_role.name
}

