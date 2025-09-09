packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
    jenkins_username = vault("secret/data/jenkins", "jenkins_username")
    jenkins_password = vault("secret/data/jenkins", "jenkins_password")
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
}

build {
  sources = ["source.amazon-ebs.jenkins"]

  provisioner "shell" {
    inline = [
      "sudo sh -c 'echo JENKINS_USERNAME=${local.jenkins_username} >> /etc/environment'",
      "sudo sh -c 'echo JENKINS_PASSWORD=${local.jenkins_password} >> /etc/environment'"
    ]
  }

  provisioner "shell" {
    script          = "${path.root}/setup.sh"
    execute_command = "sudo -E -S sh '{{ .Path }}'"
  }

  provisioner "shell" {
    script          = "${path.root}/check.sh"
    execute_command = "sudo -E -S sh '{{ .Path }}'"
  }
}
