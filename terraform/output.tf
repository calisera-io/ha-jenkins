output "bastion" {
  value = aws_instance.bastion.public_ip
}

output "elb" {
  value = aws_lb.jenkins.dns_name
}