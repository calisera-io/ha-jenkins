# HA Jenkins Setup

## Create Machine Images with Packer

[Packer](https://developer.hashicorp.com/packer)

```bash
packer build -var-file=variables.pkrvars.hcl template.pkr.hcl
```

## Deploy Infrastructure with Terraform

[Terraform](https://developer.hashicorp.com/terraform)


* Jenkins master
    * Active/passive
    * One Region, multiple Availability Zones
    * Elastic Load Balancer
    * Elastic File System -> persist Jenkins home directory
* Jenkins workers
    * Auto Scaling Group
    * CloudWatch Alarm
    * Prometheus
* Pipelines
    * Run automated tests
    * Build Docker Images
    * Trigger Labmda