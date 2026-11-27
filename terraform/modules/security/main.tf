resource "aws_default_security_group" "this" {
  vpc_id = var.vpc_id

  ingress = []
  egress  = []

  tags = {
    Name    = "${var.project_name}-default-sg"
    Project = var.project_name
  }
}

resource "aws_security_group" "public" {
  name        = "${var.project_name}-public-sg"
  description = "SSH access to public EC2"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project_name}-public-sg"
    Project = var.project_name
  }
}

resource "aws_security_group" "private" {
  name        = "${var.project_name}-private-sg"
  description = "SSH access from public EC2"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project_name}-private-sg"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "public_ssh" {
  security_group_id = aws_security_group.public.id
  cidr_ipv4         = var.allowed_ssh_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "private_ssh" {
  security_group_id            = aws_security_group.private.id
  referenced_security_group_id = aws_security_group.public.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_egress_rule" "public_outbound" {
  security_group_id = aws_security_group.public.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "private_outbound" {
  security_group_id = aws_security_group.private.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}