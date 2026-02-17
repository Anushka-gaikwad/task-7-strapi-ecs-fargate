resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile"
  role = "ecsEC2Role" # the role ARN they gave you
}

