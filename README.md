# HA Jenkins Setup

## AWS Technologies and Services

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

## Setup credentials

### Hashicorp vault

Start vault server in development mode
```bash
pkill vault
vault server -dev
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN=$(vault print token)
```

Run
```bash
./read-jenkins-admin-credentials.sh
```
to set `jenkins_admin_id` and `jenkins_admin_password`.

Use
```bash
vault kv get -field=jenkins_admin_id secret/jenkins
vault kv get -field=jenkins_admin_password secret/jenkins
```
to verify credentials for debugging


### OpenSSH

```bash
mkdir credentials
ssh-keygen -f credentials/jenkins_id_rsa -N '' -t rsa -b 4096
```

## Deploy Infrastructure with Terraform

[Terraform](https://developer.hashicorp.com/terraform)

## Create custom Amazon Machine Images (AMI) with Packer

[Packer](https://developer.hashicorp.com/packer)

* Jenkins server image
    * Install [Jenkins on Amazon Linux](https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/)
    * Configure Jenkins server on start and reboot (`init.groovy.d` Groovy scripts)
    * Install Jenkins plugins (`bash`)
    * Setup Jenkins credentials (`bash`) 
    * Disable Jenkins setup wizard (`bash`)
* Worker image
    * Install [Docker on Amazon Linux](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-docker.html)