output "bastion" {
  value = aws_instance.bastion.public_ip
}

output "jenkins" {
  value = aws_instance.jenkins.public_dns
}
