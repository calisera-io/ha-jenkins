data "aws_ami" "proxy" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_ami" "jenkins" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["jenkins-server-*"]
  }
}

data "aws_ami" "worker" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["jenkins-worker"]
  }
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  effective_ip = var.my_ip != "" ? var.my_ip : trimspace(data.http.my_ip.response_body)
}

resource "aws_security_group" "proxy" {
  name        = "proxy-security-group-${var.vpc_name}"
  description = "Allow tcp/80 from my IP"
  vpc_id      = aws_vpc.custom.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${local.effective_ip}/32"]
  }
  tags = {
    Name   = "proxy-security-group-${var.vpc_name}"
    Author = var.author
  }
}

data "template_file" "user_data_proxy" {
  template = file("user-data/proxy.sh.tpl")
  vars = {
    jenkins_private_ip = aws_instance.jenkins.private_ip
  }
}

resource "aws_instance" "proxy" {
  ami                         = data.aws_ami.proxy.id
  instance_type               = var.proxy_instance_type
  vpc_security_group_ids      = [aws_security_group.proxy.id]
  user_data_base64            = base64encode(data.template_file.user_data_proxy.rendered)
  subnet_id                   = values(aws_subnet.public_subnet)[0].id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  root_block_device {
    volume_type           = var.proxy_root_block_device.volume_type
    volume_size           = var.proxy_root_block_device.volume_size
    encrypted             = var.proxy_root_block_device.encrypted
    delete_on_termination = var.proxy_root_block_device.delete_on_termination
  }
  tags = {
    Name   = "proxy-${var.vpc_name}"
    Author = var.author
  }
  depends_on = [aws_instance.jenkins]
}

# resource "aws_security_group" "lb" {
#   name        = "lb-security-group-${var.vpc_name}"
#   description = "Allow tcp/80 and tcp/443 from everywhere"
#   vpc_id      = aws_vpc.custom.id
#   ingress {
#     from_port   = "80"
#     to_port     = "80"
#     protocol    = "tcp"
#     cidr_blocks = ["${local.effective_ip}/32"]
#     #    cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = "443"
#     to_port     = "443"
#     protocol    = "tcp"
#     cidr_blocks = ["${local.effective_ip}/32"]
#     #    cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     from_port   = "0"
#     to_port     = "0"
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Name   = "lb-security-group-${var.vpc_name}"
#     Author = var.author
#   }
# }

# resource "aws_lb" "jenkins" {
#   name               = "lb-${var.vpc_name}"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.lb.id]
#   subnets            = values(aws_subnet.public_subnet)[*].id
#   tags = {
#     Name   = "lb-${var.vpc_name}"
#     Author = var.author
#   }
# }

# resource "aws_lb_target_group" "jenkins" {
#   name     = "lb-target-group-${var.vpc_name}"
#   port     = 8080
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.custom.id
#   health_check {
#     path                = "/login/index.html"
#     healthy_threshold   = 2
#     unhealthy_threshold = 3
#     timeout             = 5
#     interval            = 30
#   }
#   tags = {
#     Name   = "lb-target-group-${var.vpc_name}"
#     Author = var.author
#   }
# }

# resource "aws_lb_target_group_attachment" "jenkins" {
#   target_group_arn = aws_lb_target_group.jenkins.arn
#   target_id        = aws_instance.jenkins.id
#   port             = 8080
# }

# resource "aws_lb_listener" "jenkins_http" {
#   load_balancer_arn = aws_lb.jenkins.arn
#   port              = "80"
#   protocol          = "HTTP"
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.jenkins.arn
#   }
# }

# resource "aws_lb_listener" "jenkins_https" {
#   load_balancer_arn = aws_lb.jenkins.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = var.ssl_certificate_arn
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.jenkins.arn
#   }
# }

resource "aws_security_group" "jenkins" {
  name        = "jenkins-security-group-${var.vpc_name}"
  description = "Allow tcp/8080 from load balancer and tcp/22 from bastion"
  vpc_id      = aws_vpc.custom.id
  ingress {
    from_port       = "8080"
    to_port         = "8080"
    protocol        = "tcp"
    cidr_blocks     = values(aws_subnet.private_subnet)[*].cidr_block
    security_groups = [aws_security_group.proxy.id]
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
  ami                         = data.aws_ami.jenkins.id
  instance_type               = var.jenkins_instance_type
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  subnet_id                   = values(aws_subnet.private_subnet)[0].id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  root_block_device {
    volume_type           = var.jenkins_root_block_device.volume_type
    volume_size           = var.jenkins_root_block_device.volume_size
    iops                  = var.jenkins_root_block_device.iops
    throughput            = var.jenkins_root_block_device.throughput
    encrypted             = var.jenkins_root_block_device.encrypted
    delete_on_termination = var.jenkins_root_block_device.delete_on_termination
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }
  tags = {
    Name   = "server-${var.vpc_name}"
    Author = var.author
  }
  depends_on = [aws_nat_gateway.nat_gateway]
}

resource "aws_security_group" "worker" {
  name        = "worker-security-group-${var.vpc_name}"
  description = "Allow tcp/22 from bastion and jenkins security groups"
  vpc_id      = aws_vpc.custom.id
  ingress {
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins.id]
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

data "template_file" "user_data_worker" {
  template = file("user-data/worker.sh.tpl")
  vars = {
    jenkins_private_ip = aws_instance.jenkins.private_ip
  }
}

resource "aws_launch_template" "worker" {
  name          = "worker-launch-template"
  image_id      = data.aws_ami.worker.id
  instance_type = var.worker_instance_type
  user_data     = base64encode(data.template_file.user_data_worker.rendered)
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.worker.id]
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = var.worker_root_block_device.volume_type
      volume_size           = var.worker_root_block_device.volume_size
      iops                  = var.worker_root_block_device.iops
      throughput            = var.worker_root_block_device.throughput
      encrypted             = var.worker_root_block_device.encrypted
      delete_on_termination = var.worker_root_block_device.delete_on_termination
    }
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "worker-${var.vpc_name}"
    }
  }
  depends_on = [aws_instance.jenkins]
}

resource "aws_autoscaling_group" "worker" {
  name                = "worker-autoscaling-group"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 1
  vpc_zone_identifier = [values(aws_subnet.private_subnet)[0].id]
  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }
  health_check_type = "EC2"
  depends_on        = [aws_instance.jenkins]
}

# locals {
#   lambda_code = templatefile("${path.module}/lambda/github-webhook.py.tpl", {
#     jenkins_private_ip = aws_instance.jenkins.private_ip
#   })
# }

# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   output_path = "${path.module}/lambda/github-webhook.zip"
#   source {
#     content  = local.lambda_code
#     filename = "github-webhook.py"
#   }
# }

# resource "aws_iam_role" "lambda" {
#   name               = "lambda-role"
#   assume_role_policy = file("lambda-policy.json")
# }

# resource "aws_iam_role_policy_attachment" "lambda" {
#   role       = aws_iam_role.lambda.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# resource "aws_security_group" "lambda" {
#   name   = "lambda-security-group-${var.vpc_name}"
#   vpc_id = aws_vpc.custom.id
#   egress {
#     from_port       = 8080
#     to_port         = 8080
#     protocol        = "tcp"
#     cidr_blocks     = [values(aws_subnet.private_subnet)[0].cidr_block]
#     security_groups = [aws_security_group.jenkins.id]
#   }
#   egress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Name   = "lambda-security-group-${var.vpc_name}"
#     Author = var.author
#   }
# }

# resource "aws_lambda_function" "github-webhook" {
#   filename         = data.archive_file.lambda_zip.output_path
#   source_code_hash = data.archive_file.lambda_zip.output_base64sha256
#   function_name    = "github-webhook"
#   runtime          = "python3.12"
#   handler          = "github-webhook.lambda_handler"
#   role             = data.aws_iam_role.lambda.arn
#   vpc_config {
#     subnet_ids         = [values(aws_subnet.private_subnet)[0].id]
#     security_group_ids = [aws_security_group.lambda.id]
#   }
# }