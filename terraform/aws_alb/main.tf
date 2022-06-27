resource "aws_security_group" "http" {
  name        = var.aws_security_group_http.name
  description = var.aws_security_group_http.description
  vpc_id      = var.aws_security_group_http.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "egress_all" {
  name        = var.aws_security_group_egress_all.name
  description = var.aws_security_group_egress_all.description
  vpc_id      = var.aws_security_group_egress_all.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "application_load_balancer" {
  name               = var.alb.name
  internal           = var.alb.internal
  load_balancer_type = var.alb.load_balancer_type

  subnets = var.alb.subnets

  security_groups = [
    aws_security_group.http.id,
    aws_security_group.egress_all.id,
  ]
}

