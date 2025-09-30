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

resource "aws_security_group" "jenkins" {
  name        = "jenkins-security-group-${var.vpc_name}"
  description = "Allow tcp/8080 from load balancer and tcp/22 from bastion"
  vpc_id      = aws_vpc.custom.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = values(aws_subnet.private_subnet)[*].cidr_block
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name   = "jenkins-security-group-${var.vpc_name}"
    Author = var.author
  }
}

resource "aws_instance" "jenkins" {
  ami           = data.aws_ami.jenkins.id
  instance_type = var.jenkins_instance_type
  vpc_security_group_ids = [
    aws_security_group.jenkins.id,
    aws_security_group.webhook_handler.id
  ]
  subnet_id                   = values(aws_subnet.private_subnet)[0].id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.jenkins_profile.name
  user_data_base64            = base64encode(file("user-data/jenkins.sh"))
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
    name = aws_iam_instance_profile.worker_profile.name
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

locals {
  lambda_code = templatefile("${path.module}/lambda/github_webhook_handler.py.tpl", {
    jenkins_private_ip = aws_instance.jenkins.private_ip
  })
}

data "archive_file" "webhook_handler_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda/github_webhook_handler.zip"
  source {
    content  = local.lambda_code
    filename = "github_webhook_handler.py"
  }
}

resource "aws_iam_role" "webhook_handler" {
  name = "webhook-handler-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "ssm.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "webhook_handler_ssm" {
  role       = aws_iam_role.webhook_handler.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "webhook_handler" {
  role       = aws_iam_role.webhook_handler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "webhook_handler_vpc_access" {
  role       = aws_iam_role.webhook_handler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_security_group" "webhook_handler" {
  name   = "webhook-handler-security-group-${var.vpc_name}"
  vpc_id = aws_vpc.custom.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lambda_function" "webhook_handler" {
  filename         = data.archive_file.webhook_handler_zip.output_path
  source_code_hash = data.archive_file.webhook_handler_zip.output_base64sha256
  function_name    = "github_webhook_handler"
  runtime          = "python3.12"
  handler          = "github_webhook_handler.lambda_handler"
  role             = aws_iam_role.webhook_handler.arn
  timeout = 30
  
  vpc_config {
    subnet_ids         = values(aws_subnet.private_subnet)[*].id
    security_group_ids = [aws_security_group.webhook_handler.id]
  }
}

resource "aws_api_gateway_rest_api" "webhook_api" {
  name = "webhook-api"
}

resource "aws_api_gateway_resource" "webhook_resource" {
  rest_api_id = aws_api_gateway_rest_api.webhook_api.id
  parent_id   = aws_api_gateway_rest_api.webhook_api.root_resource_id
  path_part   = "webhook"
}

resource "aws_api_gateway_method" "webhook_method" {
  rest_api_id   = aws_api_gateway_rest_api.webhook_api.id
  resource_id   = aws_api_gateway_resource.webhook_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.webhook_api.id
  resource_id = aws_api_gateway_resource.webhook_resource.id
  http_method = aws_api_gateway_method.webhook_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.webhook_handler.invoke_arn
}

resource "aws_api_gateway_deployment" "webhook_deployment" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.webhook_api.id
}

resource "aws_api_gateway_stage" "webhook_stage" {
  deployment_id = aws_api_gateway_deployment.webhook_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.webhook_api.id
  stage_name    = "dev"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webhook_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.webhook_api.execution_arn}/*/*"
}