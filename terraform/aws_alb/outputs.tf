output "aws_alb_arn" {
  value = aws_alb.application_load_balancer.arn
}

output "aws_sg_egress_all_id" {
  value = aws_security_group.egress_all.id
}

output "alb_url" {
  value = "http://${aws_alb.application_load_balancer.dns_name}"
}