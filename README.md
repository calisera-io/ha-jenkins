# HA Jenkins Setup

## Deploy Infrastructure with Terraform

[Terraform](https://developer.hashicorp.com/terraform)


* Jenkins master
    * EC2
    * Active/passive
    * One Region, multiple Availability Zones
    * Elastic Load Balancer
    * Elastic File System -> persist Jenkins home directory
* Jenkins workers
    * EC2
    * Auto Scaling Group
    * CloudWatch Alarm
    * Prometheus
* Pipelines
    * Run automated tests
    * Build Docker Images
    * Trigger Labmda

## Create Machine Images with Packer

[Packer](https://developer.hashicorp.com/packer)

