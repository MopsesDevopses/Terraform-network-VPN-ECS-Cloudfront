output "efs_id" {
  value = aws_efs_file_system.project.id
}

output "efs" {
  value = aws_efs_file_system.project
}
