resource "aws_vpc" "custom" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name   = var.vpc_name
    Author = var.author
  }
}

locals {
  public_subnets = {
    for idx, az in var.availability_zones :
    az => {
      cidr_block = cidrsubnet(aws_vpc.custom.cidr_block, 8, 2 * idx)
      az         = az
    }
  }
}

resource "aws_subnet" "public_subnet" {
  for_each          = local.public_subnets
  vpc_id            = aws_vpc.custom.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az
  tags = {
    Name   = "public-subnet-${each.value.cidr_block}-${each.value.az}-${var.vpc_name}"
    Author = var.author
  }
}

locals {
  private_subnets = {
    for idx, az in var.availability_zones :
    az => {
      cidr_block = cidrsubnet(aws_vpc.custom.cidr_block, 8, 2 * idx + 1)
      az         = az
    }
  }
}

resource "aws_subnet" "private_subnet" {
  for_each          = local.private_subnets
  vpc_id            = aws_vpc.custom.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az
  tags = {
    Name   = "private-subnet-${each.value.cidr_block}-${each.value.az}-${var.vpc_name}"
    Author = var.author
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom.id
  tags = {
    Name   = "igw-${var.vpc_name}"
    Author = var.author
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.custom.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name   = "public-route-table-${var.vpc_name}"
    Author = var.author
  }
}

resource "aws_route_table_association" "public_subnets" {
  for_each       = aws_subnet.public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "nat_gateway_eip" {
  domain = "vpc"
  tags = {
    Name   = "nat-gateway-eip-${var.vpc_name}"
    Author = var.author
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  subnet_id     = values(aws_subnet.public_subnet)[0].id
  allocation_id = aws_eip.nat_gateway_eip.id
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name   = "nat-gateway-${var.vpc_name}"
    Author = var.author
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.custom.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }
  depends_on = [aws_nat_gateway.nat_gateway]
  tags = {
    Name   = "private-route-table-${var.vpc_name}"
    Author = var.author
  }
}

resource "aws_route_table_association" "private_subnets" {
  for_each       = aws_subnet.private_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_security_group" "lb" {
  name        = "lb-security-group-${var.vpc_name}"
  description = "Allow http traffic"
  vpc_id      = aws_vpc.custom.id

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = "lb-security-group-${var.vpc_name}"
    Author = var.author
  }
}

resource "aws_lb" "jenkins" {
  name               = "lb-${var.vpc_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = values(aws_subnet.public_subnet)[*].id

  tags = {
    Name   = "lb-${var.vpc_name}"
    Author = var.author
  }
}

resource "aws_lb_target_group" "jenkins" {
  name     = "lb-target-group-${var.vpc_name}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.custom.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    protocol            = "HTTP"
    path                = "/"
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name   = "lb-target-group-${var.vpc_name}"
    Author = var.author
  }
}

resource "aws_lb_listener" "jenkins" {
  load_balancer_arn = aws_lb.jenkins.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn
  }
}