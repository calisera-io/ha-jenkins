data "aws_ami" "bastion" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_ami" "server" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_ami" "worker" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  effective_ip = var.my_ip != "" ? var.my_ip : trimspace(data.http.my_ip.response_body)
}

resource "aws_security_group" "bastion_security_group" {
  name        = "bastion-security-group-${var.vpc_name}"
  description = "Allow SSH from my IP"
  vpc_id      = aws_vpc.custom.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${local.effective_ip}/32"]
  }
  tags = {
    Name   = "bastion-security-group-${var.vpc_name}"
    Author = var.author
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.bastion.id
  instance_type               = var.bastion_instance_type
  key_name                    = var.public_key_name
  vpc_security_group_ids      = [aws_security_group.bastion_security_group.id]
  subnet_id                   = values(aws_subnet.public_subnet)[0].id
  associate_public_ip_address = true
  tags = {
    Name   = "bastion-${var.vpc_name}"
    Author = var.author
  }
}

resource "aws_security_group" "worker_security_group" {
  name        = "worker-security-group-${var.vpc_name}"
  description = "Allow traffic on port 22 from bastion security group"
  vpc_id      = aws_vpc.custom.id
  ingress {
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_security_group.id]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name   = "worker-security-group-${var.vpc_name}"
    Author = var.author
  }
}

resource "aws_launch_template" "worker_launch_template" {
  name          = "worker-launch-template"
  image_id      = data.aws_ami.worker.id
  instance_type = var.worker_instance_type
  key_name      = var.public_key_name
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.worker_security_group.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "worker-${var.vpc_name}"
    }
  }
}

resource "aws_autoscaling_group" "worker_autoscaling_group" {
  name                = "worker-autoscaling-group"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 2
  vpc_zone_identifier = values(aws_subnet.private_subnet)[*].id

  launch_template {
    id      = aws_launch_template.worker_launch_template.id
    version = "$Latest"
  }

  health_check_type = "EC2"
}