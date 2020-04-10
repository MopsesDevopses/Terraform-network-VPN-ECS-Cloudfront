output "alb_dns_name" {
  value = module.EC2.alb_dns_name
}

output "s3_id" {
  value = aws_s3_bucket.s3.id
}
