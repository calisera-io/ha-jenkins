data "aws_instances" "jenkins" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.jenkins.name]
  }
  instance_state_names = ["running"]
}

output "bastion" {
  value = aws_instance.bastion.public_ip
}

output "elb" {
  value = aws_lb.jenkins.dns_name
}

output "jenkins_private_ip" {
  value = length(data.aws_instances.jenkins.private_ips) > 0 ? data.aws_instances.jenkins.private_ips[0] : null
}