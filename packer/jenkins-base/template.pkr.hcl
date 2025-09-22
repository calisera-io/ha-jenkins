packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "shared_credentials_file" {
  type    = string
  default = ""
}

variable "profile" {
  type    = string
  default = "packer"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

source "amazon-ebs" "jenkins" {
  shared_credentials_file = var.shared_credentials_file
  profile                 = var.profile
  region                  = var.region
  instance_type           = var.instance_type
  ssh_username            = "ec2-user"
  ami_name                = "jenkins-base"
  ami_description         = "Amazon Linux Base Image for Jenkins"
  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "al2023-ami-*-x86_64"
      root-device-type    = "ebs"
    }
    owners      = ["amazon"]
    most_recent = true
  }
  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }
}

build {
  sources = ["source.amazon-ebs.jenkins"]

  provisioner "shell" {
    script          = "${path.root}/setup.sh"
    execute_command = "sudo bash '{{ .Path }}'"
  }

  provisioner "shell" {
    script          = "${path.root}/check.sh"
    execute_command = "sudo bash '{{ .Path }}'"
  }
}
