output "iam_name" {
  value = aws_iam_instance_profile.ecs.name
}

output "iam_bastion_name" {
  value = aws_iam_instance_profile.bastion-node.name
}
