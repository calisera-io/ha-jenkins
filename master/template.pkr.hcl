packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  jenkins_private_key_file = "/tmp/id_rsa"
}

variable "jenkins_admin" {
  type    = string
  default = "admin"
}

variable "jenkins_admin_password" {
  type    = string
  default = "password"
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
  region          = var.region
  instance_type   = var.instance_type
  ssh_username    = "ec2-user"
  ami_name        = "jenkins-master"
  ami_description = "Amazon Linux Image with Jenkins Server"

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

  provisioner "file" {
    source      = "${path.root}/scripts"
    destination = "/tmp/"
  }

  provisioner "file" {
    source      = "${path.root}/plugins"
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "cat > ${local.jenkins_private_key_file} << 'EOF'",
      "${file("${path.root}/credentials/id_rsa")}",
      "EOF",
      "chmod 600 ${local.jenkins_private_key_file}"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo sh -c 'echo JENKINS_ADMIN_ID=${var.jenkins_admin} >> /etc/environment'",
      "sudo sh -c 'echo JENKINS_ADMIN_PASSWORD=${var.jenkins_admin_password} >> /etc/environment'"
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
