variable "shared_config_file" {
  type        = string
  description = "AWS config file path"
}

variable "shared_credentials_file" {
  type        = string
  description = "AWS credentials file path"
}

variable "profile" {
  type        = string
  description = "AWS profile"
  default     = "default"
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-west-2"
}

variable "author" {
  type        = string
  description = "Created by"
  default     = "Marcus Hogh"
}

variable "vpc_name" {
  type        = string
  description = "VPC name"
  default     = "jenkins"
}

variable "cidr_block" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of Availability Zones"
  default     = ["us-west-2a", "us-west-2b"]
}

variable "public_key_name" {
  type        = string
  description = "SSH public key name"
}

variable "my_ip" {
  type        = string
  description = "My public IPv4 address"
  default     = ""
}

variable "bastion_instance_type" {
  type        = string
  description = "Bastion instance type"
  default     = "t3.micro"
}

variable "jenkins_instance_type" {
  type        = string
  description = "Jenlins instance type"
  default     = "t3.micro"
}

variable "worker_instance_type" {
  type        = string
  description = "Worker instance type"
  default     = "t3.micro"
}

variable "ssl_certificate_arn" {
  type        = string
  description = "ARN of SSL certificate for HTTPS listener"
  default     = ""
}

variable "jenkins_private_key_file" {
  type        = string
  description = ""
  default     = "jenkins_id_rsa"
}

variable "jenkins_public_key_file" {
  type        = string
  description = ""
  default     = "jenkins_id_rsa.pub"
}

variable "jenkins_credentials_id" {
  type        = string
  description = "Jenkins credentials id"
  default     = "jenkins"
}

variable "jenkins_user" {
  type        = string
  description = "Jenkins user name"
  default     = "jenkins"
}