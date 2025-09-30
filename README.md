# HA Jenkins Deployment on AWS

Development needs a robust, scalable CI/CD infrastructure that can handle dynamic workloads while maintaining high availability, security, and cost efficiency.

Jenkins is one of the most widely used CI/CD platforms, trusted by enterprises globally, with a mature ecosystem and strong community support. Its server-worker architecture supports distributed builds, making it possible to handle dynamic and large-scale workloads efficiently. Jenkins allows teams to define CI/CD processes as code (Jenkinsfiles), ensuring repeatability, version control, and governance.

#### Operational Challenges with Traditional Jenkins Deployments

* *Manual Setup Overhead* Traditional Jenkins deployments require extensive manual configuration, plugin installation, and security setup.
* *Scalability Limitations* Static Jenkins workers can't handle variable build loads efficiently
* *Single Point of Failure* Standard Jenkins deployments lack high availability.
* *Security Complexity* Managing credentials, SSH keys, and secure communication between components.
* *Infrastructure Drift* Manual configurations lead to inconsistent environments.

#### Operational Gains with HA Jenkins Deployments

* *Zero-Touch Deployment* Fully automated Jenkins setup with pre-configured plugins, security, and pipelines.
* *Elastic Scaling* Auto Scaling Groups dynamically adjust worker capacity based on CPU utilization.
* *High Availability* Multi-AZ deployment ensures service continuity.
* *Security by Design* SSH key-based authentication, VPN access, AWS Systems Manager for credential management.
* *Infrastructure as Code* Reproducible deployments using Packer and Terraform.
* *Cost Optimization* Pay-per-use scaling reduces idle resource costs.

## AWS Technologies and Services Used

### Compute
* *EC2* Hosts Jenkins server and auto-scaling worker instances using custom AMIs.
* *Auto Scaling Group* Dynamically scales Jenkins workers based on CPU utilization.
* *Security Groups* Instance-level firewall rules for Jenkins server and workers.

### Networking
* *VPC* Isolated network environment with public/private subnets across multiple AZs.
* *Subnets* Public subnets for NAT Gateway, private subnets for Jenkins infrastructure
* *Internet Gateway* Provides internet access to public subnets and is required for NAT Getway.
* *NAT Gateway* Enables outbound internet access for private subnet resources.
* *Elastic IP* Static IP address for NAT Gateway.
* *Route Tables* Direct traffic between subnets and gateways.

### Integration and Automation
* *Lambda* Handles GitHub webhook events and triggers Jenkins builds.
* *API Gateway* Exposes REST endpoint for GitHub webhook integration.
* *CloudWatch* Monitors CPU metrics and triggers auto-scaling alarms.

### Security and Management
* *IAM* Manages roles and policies for Jenkins server, workers, and Lambda function.
* *Systems Manager* Stores and manages Jenkins credentials and configuration secrets.
* *S3* Artifact storage and deployment target.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                    Internet                                         │
└───────────────────────────────────────┬─────────────────────────────────────────────┘
                                        │
┌───────────────────────────────────────┴─────────────────────────────────────────────┐
│                                    AWS VPC                                          │
│                                                                                     │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │                            Internet Gateway                                 │   │
│   └───────────────────────────────────┬─────────────────────────────────────────┘   │
│                                       │                                             │
│   ┌───────────────────────────────────┴─────────────────────────────────────────┐   │
│   │                         Public Subnets (Multi-AZ)                           │   │
│   │                                                                             │   │
│   │   ┌─────────────────┐                    ┌─────────────────┐                │   │
│   │   │   NAT Gateway   │                    │   Elastic IP    │                │   │
│   │   │   (AZ-1)        │                    │                 │                │   │
│   │   └─────────────────┘                    └─────────────────┘                │   │
│   └────────────────────────────────────┬────────────────────────────────────────┘   │
│                                        │                                            │
│   ┌────────────────────────────────────┴────────────────────────────────────────┐   │
│   │                         Private Subnets (Multi-AZ)                          │   │
│   │                                                                             │   │
│   │   ┌─────────────────────────────────────────────────────────────────────┐   │   │
│   │   │   Jenkins Server                                                    │   │   │
│   │   │   (EC2 Instance)                                                    │   │   │
│   │   │                                                                     │   │   │
│   │   │  • Custom AMI (jenkins-server)                                      │   │   │
│   │   │  • IAM Role (SSM access)                                            │   │   │
│   │   │  • Security Group (Jenkins UI, SSH access, WireGuard VPN)           │   │   │
│   │   └─────────────────────────────────┬───────────────────────────────────┘   │   │
│   │                                     │                                       │   │
│   │  ┌──────────────────────────────────┴────────────────────────────────────┐  │   │
│   │  │                          Auto Scaling Group                           │  │   │
│   │  │                                                                       │  │   │
│   │  │ ┌────────────────────────────────┐ ┌────────────────────────────────┐ │  │   │
│   │  │ │ Jenkins Worker                 │ │ Jenkins Worker                 │ │  │   │
│   │  │ │ (EC2 Instance)                 │ │ (EC2 Instance)                 │ │  │   │
│   │  │ │                                │ │                                │ │  │   │
│   │  │ │ • Custom AMI (jenkins-worker)  │ │ • Custom AMI (jenkins-worker)  │ │  │   │
│   │  │ │ • Docker (node.js, AWS CLI)    │ │ • Docker (node.js, AWS CLI)    │ │  │   │
│   │  │ │ • IAM Role (SSM and S3 access) │ │ • IAM Role (SSM and S3 access) │ │  │   │
│   │  │ │ • Security Group (SSH access)  │ │ • Security Group (SSH access)  │ │  │   │
│   │  │ └────────────────────────────────┘ └────────────────────────────────┘ │  │   │
│   │  └───────────────────────────────────────────────────────────────────────┘  │   │
│   │                                                                             │   │
│   │  ┌───────────────────────────────────────────────────────────────────────┐  │   │
│   │  │  Lambda Function                                                      │  │   │
│   │  │  (GitHub Webhook Handler)                                             │  │   │
│   │  │                                                                       │  │   │
│   │  │  • Python 3.12 Runtime                                                │  │   │
│   │  │  • VPC Configuration                                                  │  │   │
│   │  │  • IAM Role (SSM and VPC access)                                      │  │   │
│   │  └───────────────────────────────────────────────────────────────────────┘  │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                   External Services                                 │
│                                                                                     │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │  S3 Bucket                                                                  │   │
│   │                                                                             │   │
│   │  • Artifact storage and deployment target                                   │   │
│   │                                                                             │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
│   ┌─────────────────────────────────────────────────────────────────────────────┐   │
│   │  API Gateway                                                                │   │
│   │                                                                             │   │
│   │  • REST API: /webhook endpoint                                              │   │
│   │  • POST method                                                              │   │
│   │  • Lambda integration                                                       │   │
│   │  • Stage: dev                                                               │   │
│   └───────────────────────────────────────┬─────────────────────────────────────┘   │
│                                           │                                         │
│   ┌───────────────────────────────────────┴─────────────────────────────────────┐   │
│   │  GitHub                                                                     │   │
│   │  (Webhook Source)                                                           │   │
│   │                                                                             │   │
│   └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Build custom Amazon Machine Images (AMI) with Packer

### `base`, `server`, `worker` AMIs

The packer directory contains [Packer](https://developer.hashicorp.com/packer) templates and scripts to build three custom AMIs (base, server, worker) for a fully automated, scalable Jenkins infrastructure on AWS with pre-configured security, plugins, and Docker-enabled build agents.

* Base image (foundation AMI with common configurations)
    * Install [Amazon Coretto (Java) on Amazon Linux](https://docs.aws.amazon.com/corretto/)
    * Install [git (version control)](https://git-scm.com/)
* Server image (controller AMI with Jenkins installation, plugins, and Groovy automation scripts)
    * Install [Jenkins on Amazon Linux](https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/)
    * Configure Jenkins server on start and reboot (`init.groovy.d` Groovy scripts)
        * Admin user credentials (AWS Systems Manager paramater store)
        * Security (SSH key-based authentication between server and workers)
        * Pipeline (preconfigured)
    * Install Jenkins plugins (plugin manager `bash` script)
    * Disable Jenkins setup wizard (`JAVA_OPTS` environment variable)
* Worker image (agent AMI with Docker and worker connection capabilities)
    * Install [Docker on Amazon Linux](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-docker.html)
    * Automated startup/shutdown scripts for workers (`systemd`)
    * AWS Systems Manager integration for secure credential storage (parameter store)

### IAM Policy and User Setup for Packer Operations

The `setup-packer-user.sh` script provisions the required IAM resources to support Amazon Machine Image (AMI) builds with [Packer](https://developer.hashicorp.com/packer). This configuration follows the principle of least privilege by granting only the permissions necessary to perform AMI creation and related EC2 operations.

#### Script Functionality

1. IAM Policy Creation
    * Creates a managed policy named `PackerAMIBuilderPolicy`.
    * Grants the required Amazon EC2 permissions, including:
        * Launching and terminating instances
        * Creating AMIs and snapshots
        * Managing security groups and volumes
2. IAM User Creation
    * Creates a dedicated IAM user named `packer`.
    * Attaches the `PackerAMIBuilderPolicy` to this user.
3. Access Key and CLI Profile Configuration
    * Generates a new access key for the `packer` user.
    * Configures an AWS CLI profile named `packer` with the default region set to `us-east-1`.
4. Resource Cleanup
    * Detects and removes any pre-existing IAM user or policy with the same name.
    * Ensures a consistent, reproducible setup.


## Deploy Infrastructure with Terraform

[Terraform](https://developer.hashicorp.com/terraform)