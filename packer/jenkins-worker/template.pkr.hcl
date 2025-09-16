packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  jenkins_admin_id       = vault("secret/data/jenkins", "jenkins_admin_id")
  jenkins_admin_password = vault("secret/data/jenkins", "jenkins_admin_password")
}

variable "shared_credentials_file" {
  type    = string
  default = ""
}

variable "profile" {
  type    = string
  default = "default"
}

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "jenkins_user" {
  type    = string
  default = "jenkins"
}

source "amazon-ebs" "jenkins" {
  shared_credentials_file = var.shared_credentials_file
  profile                 = var.profile
  region                  = var.region
  instance_type           = var.instance_type
  ssh_username            = "ec2-user"
  ami_name                = "jenkins-worker"
  ami_description         = "Amazon Linux Image with Worker for Jenkins"
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

  provisioner "file" {
    source      = "${path.root}/../credentials"
    destination = "/tmp/"
  }

  provisioner "file" {
    source      = "${path.root}/scripts"
    destination = "/tmp/"
  }

  provisioner "shell" {
    script          = "${path.root}/setup.sh"
    execute_command = "sudo JENKINS_ADMIN_ID=${local.jenkins_admin_id} JENKINS_ADMIN_PASSWORD=${local.jenkins_admin_password} JENKINS_USER='${var.jenkins_user}' bash '{{ .Path }}'"
  }

  provisioner "shell" {
    script          = "${path.root}/check.sh"
    execute_command = "sudo JENKINS_USER='${var.jenkins_user}' bash '{{ .Path }}'"
  }
}
