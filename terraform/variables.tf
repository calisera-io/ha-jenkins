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
  default     = "eu-central-1"
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
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "public_key_name" {
  type        = string
  description = "SSH public key name"
  default     = ""
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

variable "bastion_root_block_device" {
  description = "Bastion root block device configuration"
  type = object({
    volume_type           = string
    volume_size           = number
    encrypted             = bool
    delete_on_termination = bool
  })
  default = {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }
}

variable "proxy_instance_type" {
  type        = string
  description = "Bastion instance type"
  default     = "t3.micro"
}

variable "proxy_root_block_device" {
  description = "Bastion root block device configuration"
  type = object({
    volume_type           = string
    volume_size           = number
    encrypted             = bool
    delete_on_termination = bool
  })
  default = {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }
}

variable "jenkins_instance_type" {
  type        = string
  description = "Jenlins instance type"
  default     = "t3.micro"
}

variable "jenkins_root_block_device" {
  description = "Jenkins server root block device configuration"
  type = object({
    volume_type           = string
    volume_size           = number
    iops                  = optional(number)
    throughput            = optional(number)
    encrypted             = bool
    delete_on_termination = bool
  })
  default = {
    volume_type           = "gp3"
    volume_size           = 30
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = true
  }
}

variable "worker_instance_type" {
  type        = string
  description = "Worker instance type"
  default     = "t3.micro"
}

variable "worker_root_block_device" {
  description = "Jenkins worker root block device configuration"
  type = object({
    volume_type           = string
    volume_size           = number
    iops                  = optional(number)
    throughput            = optional(number)
    encrypted             = bool
    delete_on_termination = bool
  })
  default = {
    volume_type           = "gp3"
    volume_size           = 30
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = true
  }
}

variable "ssl_certificate_arn" {
  type        = string
  description = "ARN of SSL certificate for HTTPS listener"
  default     = ""
}

variable "jenkins_credentials_id" {
  type        = string
  description = "Jenkins credentials id"
  default     = "jenkins"
}