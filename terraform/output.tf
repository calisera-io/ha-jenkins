output "bastion" {
  value = aws_instance.bastion.public_ip
}

output "proxy" {
  value = aws_instance.proxy.public_dns
}
