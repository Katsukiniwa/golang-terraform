resource "aws_alb" "this" {
  name = "golang-terraform-alb"
  #tfsec:ignore:aws-elb-alb-not-public
  internal = false
  subnets = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1c.id,
  ]
  security_groups = [
    aws_security_group.this.id,
  ]
  enable_deletion_protection = false
  drop_invalid_header_fields = true
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_alb.this.arn
  #tfsec:ignore:aws-elb-http-not-used
  protocol = "HTTP"
  port     = "80"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_target_group" "this" {
  name        = "sample"
  protocol    = "HTTP"
  target_type = "ip"
  port        = 8080
  vpc_id      = aws_vpc.vpc.id

  health_check {
    matcher = "200,301,302"
    path    = "/"
  }
}

resource "aws_security_group" "this" {
  name        = "sample"
  vpc_id      = aws_vpc.vpc.id
  description = "security group for ALB"
}

output "lb_dns" {
  value       = aws_alb.this.dns_name
  description = "AWS load balancer DNS Name"
}

resource "aws_security_group_rule" "ingress_http" {
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "-1"
  #tfsec:ignore:aws-ec2-no-public-ingress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
  description       = "Allow all traffic in"
}

resource "aws_security_group_rule" "egress_all" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
  description       = "Allow all traffic out"
}
