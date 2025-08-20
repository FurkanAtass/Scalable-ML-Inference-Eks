########################
# Security Group Rules
########################

resource "aws_security_group_rule" "allow_prometheus_lb" {
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # For production, restrict to your IP
  security_group_id = module.eks.node_security_group_id
  description       = "Allow Prometheus dashboard access"
}

resource "aws_security_group_rule" "allow_app_lb_8000" {
  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # For production, restrict to your IP
  security_group_id = module.eks.node_security_group_id
  description       = "Allow app access on port 8000"
}