output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnets" {
  value = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]
}

output "sg_id" {
  value = aws_security_group.ecs_sg.id
}
