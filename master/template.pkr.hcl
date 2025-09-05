variable "jenkins_admin" {
  type    = string
  default = "admin"
}

variable "jenkins_admin_password" {
  type    = string
  default = ""
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
  region        = var.region
  instance_type = var.instance_type
  ssh_username  = "ec2-user"
  ami_name      = "jenkins-master"
  ami_description = "Amazon Linux Image with Jenkins Server"
  
  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size          = 8
    volume_type          = "gp3"
    delete_on_termination = true
  }

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
    source      = "${path.root}/config"
    destination = "/tmp/"
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
}
