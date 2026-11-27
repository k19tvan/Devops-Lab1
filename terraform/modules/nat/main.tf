resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name    = "${var.project_name}-nat-eip"
    Project = var.project_name
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id     = aws_eip.nat.id
  subnet_id         = var.public_subnet_id
  connectivity_type = "public"

  tags = {
    Name    = "${var.project_name}-nat"
    Project = var.project_name
  }
}