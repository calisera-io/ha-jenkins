output "bastion" {
  value = aws_instance.bastion.public_ip
}

output "jenkins" {
  value = aws_instance.jenkins.private_ip
}

output "proxy" {
  value = aws_instance.proxy.public_dns
}
