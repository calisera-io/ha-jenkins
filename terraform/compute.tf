data "aws_ami" "bastion" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_ami" "jenkins" {
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

resource "aws_security_group" "bastion" {
  name        = "bastion-security-group-${var.vpc_name}"
  description = "Allow tcp/22 from my IP"
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
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  subnet_id                   = values(aws_subnet.public_subnet)[0].id
  associate_public_ip_address = true
  tags = {
    Name   = "bastion-${var.vpc_name}"
    Author = var.author
  }
}

resource "aws_security_group" "jenkins" {
  name        = "jenkins-security-group-${var.vpc_name}"
  description = "Allow tcp/8080 and tcp/22"
  vpc_id      = aws_vpc.custom.id

  ingress {
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    from_port       = "8080"
    to_port         = "8080"
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
    cidr_blocks     = [var.cidr_block]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = "jenkins-security-group-${var.vpc_name}"
    Author = var.author
  }
}

resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.jenkins.id
  instance_type          = var.jenkins_instance_type
  key_name               = var.public_key_name
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  subnet_id              = values(aws_subnet.private_subnet)[0].id
  user_data_base64       = filebase64("./jenkins-user-data.sh")
  tags = {
    Name   = "jenkins_master"
    Author = var.author
  }
}

resource "aws_lb_target_group_attachment" "jenkins" {
  target_group_arn = aws_lb_target_group.jenkins.arn
  target_id        = aws_instance.jenkins.id
  port             = 8080
}

resource "aws_security_group" "worker" {
  name        = "worker-security-group-${var.vpc_name}"
  description = "Allow tcp/22 from bastion and jenkins security groups"
  vpc_id      = aws_vpc.custom.id
  ingress {
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id, aws_security_group.jenkins.id]
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

resource "aws_launch_template" "worker" {
  name          = "worker-launch-template"
  image_id      = data.aws_ami.worker.id
  instance_type = var.worker_instance_type
  key_name      = var.public_key_name
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.worker.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "worker-${var.vpc_name}"
    }
  }
}

resource "aws_autoscaling_group" "worker" {
  name                = "worker-autoscaling-group"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 2
  vpc_zone_identifier = values(aws_subnet.private_subnet)[*].id

  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }

  health_check_type = "EC2"
}