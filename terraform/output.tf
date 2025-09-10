output "bastion" {
  value = aws_instance.bastion.public_ip
}

output "jenkins" {
  value = aws_instance.jenkins.public_dns
}

output "jenkins_user" {
  value     = data.vault_kv_secret_v2.jenkins.data["jenkins_admin_id"]
  sensitive = true
}