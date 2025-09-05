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
  ami_name      = "jenkins-worker"
  ami_description = "Amazon Linux Image with Jenkins Worker"
  
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

  provisioner "shell" {
    script          = "${path.root}/setup.sh"
    execute_command = "sudo -E -S sh '{{ .Path }}'"
  }
}
