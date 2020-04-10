output "lb_arn" {
  value = aws_lb_target_group.project.arn
}

output "lb" {
  value = aws_lb.project
}

output "alb_dns_name" {
  value = aws_lb.project.dns_name
}
