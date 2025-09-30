resource "aws_vpc" "custom" {
  cidr_block           = var.vpc_cidr_block
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
    Name   = "internet-gateway-${var.vpc_name}"
    Author = var.author
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.custom.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name   = "public-route-table-${var.vpc_name}"
    Author = var.author
  }

  depends_on = [aws_internet_gateway.igw]
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

  tags = {
    Name   = "nat-gateway-${var.vpc_name}"
    Author = var.author
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.custom.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name   = "private-route-table-${var.vpc_name}"
    Author = var.author
  }

  depends_on = [aws_nat_gateway.nat_gateway]
}

resource "aws_route_table_association" "private_subnets" {
  for_each       = aws_subnet.private_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_route_table.id
}
