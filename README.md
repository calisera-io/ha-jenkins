# HA Jenkins Setup

* VPC
* Multi AZ
* Subnets
* Internet Gateway
* Network Address Translation Gateway
* Elastic IP
* Route Tables
* EC2
* Security Group
* Custom AMIs
* Auto Scaling Group
* Launch Template
* CloudWatch Alarm
* Autoscaling Policy
* Elastic Load Balancer
* Elastic File System
* IAM 
* Lambda

## Deploy Infrastructure with Terraform

[Terraform](https://developer.hashicorp.com/terraform)

## Create custom Amazon Machine Images (AMI) with Packer

[Packer](https://developer.hashicorp.com/packer)

* Jenkins server image
    * Install [Jenkins on Amazon Linux](https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/)
    * Configure Jenkins server on start and reboot (`init.groovy.d` Groovy scripts)
    * Install Jenkins plugins (`bash`)
    * Setup Jenkins credentials (`bash`) 
* Worker image
    * Install [Docker on Amazon Linux](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-docker.html)