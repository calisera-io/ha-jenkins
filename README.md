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

### Integration
* *Lambda* Handles GitHub webhook events and triggers Jenkins builds.
* *API Gateway* Exposes REST endpoint for GitHub webhook integration.
* *CloudWatch* Monitors CPU metrics and triggers auto-scaling alarms.
* *S3* Artifact storage and deployment target.

### Security
* *IAM* Manages roles and policies for Jenkins server, workers, and Lambda function.
* *Systems Manager* Stores and manages Jenkins credentials and configuration secrets.

## System Architecture

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
│   │  (Artifact storage and deployment target)                                   │   │
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

### Jenkins `base`, `server` and `worker` AMIs

The `packer` directory contains [Packer](https://developer.hashicorp.com/packer) templates and scripts to build three custom AMIs (base, server, worker) for a fully automated, scalable Jenkins infrastructure on AWS with pre-configured security, plugins, and Docker-enabled build agents.

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

The [Terraform](https://developer.hashicorp.com/terraform) configuration provisions a production-grade, highly available Jenkins CI/CD environment on AWS using Infrastructure as Code (IaC). It leverages custom AMIs built with Packer and incorporates scalability, security, and automation best practices.

### GitHub webhook URL

Deployment output is an API Gateway URL that can be used to configure a GitHub webhook, enabling automated CI/CD pipeline triggers.

### EC2 User Data

User data scripts for EC2 leverage AWS Systems Manager for secure credential retrieval and use systemd for service management, ensuring automated and secure initialization of Jenkins infrastructure components.

The script `jenkins.sh` initializes Jenkins server on startup:
* Fetch WireGuard VPN configuration from Systems Manager
* Retrieve Jenkins admin credentials from Systems Manager
* Download GitHub credentials for repository integration
* Enable and start services:
    * `wg-quick@wg0` (WireGuard VPN)
    * `ping-loop.service` (connectivity beacon)
    * `nginx.service` (reverse proxy for VPN access)
    * `jenkins.service` (Jenkins server)

The script template `worker.sh.tpl` configures Jenkins workers to connect to server (Template variable `${jenkins_private_ip}` is dynamically injected Jenkins server private IP):
* Set Jenkins server URL using private IP (template variable)
* Fetch Jenkins connection secrets from Systems Manager
* Configure systemd service override with Jenkins URL environment variable
* Enable and start `jenkins-worker.service`

### Lambda Function

`github_webhook_handler.py.tpl` is a template for a Lambda function that processes GitHub webhook events and forwards them to Jenkins server. A GitHub push or pull request triggers a GitHub webhook that is configured with an API Gateway URL and a secret for validation. This enables automated CI/CD pipeline triggers while maintaining security through signature validation and credential management via AWS Systems Manager.

Security Validation
* Retrieves GitHub webhook secret from Systems Manager
* Validates webhook signature using HMAC-SHA256
* Rejects unauthorized requests

Credential Management
* Fetches Jenkins admin credentials from Systems Manager
* Obtains Jenkins CSRF crumb for authenticated requests
* Uses basic authentication for Jenkins API calls

Event Processing
* Handles GitHub webhook payload parsing (URL-encoded format)
* Filters for relevant events: `push` and `pull_request`
* Logs event details for monitoring

Jenkins Integration
* Forwards validated webhooks to Jenkins GitHub webhook endpoint
* Includes proper headers (Content-Type, X-GitHub-Event, CSRF crumb)
* Uses Jenkins server private IP (template variable `${jenkins_private_ip}` is dynamically injected Jenkins server private IP)

## Technical Challenge: Free Tier vCPU Limit 

AWS account vCPU limits forced architectural changes to reduce instance count while maintaining secure access to Jenkins infrastructure.

### Original Architecture Issues
* *Bastion Host* Dedicated EC2 instance for SSH access (2 vCPUs)
* *Proxy Instance* Separate EC2 for VPN/reverse proxy (2 vCPUs)
* *Jenkins Server* Main controller instance (2 vCPUs)
* *Workers* Auto-scaling group instances (2+ vCPUs each)

Total: 8+ vCPUs baseline, exceeding limits with worker scaling.

### Final Consolidated Architecture

#### Eliminated Components
* **Bastion Host**: Removed dedicated SSH jump server
* **Proxy Instance**: Removed separate VPN/proxy server

#### Integrated Solution
Jenkins Server Enhancement:
* **Embedded Proxy**: Integrated nginx reverse proxy directly into Jenkins EC2
* **WireGuard VPN**: Built-in VPN server on Jenkins instance (port 51820)
* **Multi-service Instance**: Single EC2 running Jenkins, nginx and WireGuard

SSM Integration:
* AWS Systems Manager Session Manager for secure shell access
* No SSH keys or bastion hosts required
* Direct browser-based terminal access through AWS Console

#### Benefits
* **vCPU Reduction**: 4 vCPUs saved by eliminating dedicated instances
* **Simplified Architecture**: Fewer moving parts and security groups
* **Cost Optimization**: Reduced instance count lowers operational costs
* **Enhanced Security**: VPN and SSM provide secure access without exposed SSH ports

## Future Scope / Possible Improvements

### Scalability and Performance
* *Multi-Region Deployment* Cross-region Jenkins setup for disaster recovery and global CI/CD
* *Spot Instances* Use EC2 Spot instances for worker nodes to reduce costs
* *Container Orchestration*: Migrate to EKS with Jenkins on Kubernetes for better resource utilization
* *Build Cache Optimization*: Implement distributed build caching with S3 or EFS

### Security Enhancements
* *Secrets Management* Replace Systems Manager with AWS Secrets Manager for automatic rotation
* *Network Segmentation* Implement additional security layers with NACLs 
* *Certificate Management* Add SSL/TLS certificates for HTTPS access
* *Compliance* Implement logging and monitoring 

### Monitoring and Observability
* *Centralized Logging* ELK stack or CloudWatch Logs Insights for build analytics.
* *Performance Metrics* Custom CloudWatch dashboards for Jenkins performance monitoring.
* *Alerting* SNS notifications for build failures and infrastructure issues.
* *Cost Monitoring* AWS Cost Explorer integration for resource optimization.

### Operational Improvements
* *Backup Strategy* Automated Jenkins configuration and job backups to S3
* *Disaster Recovery* Cross-AZ failover with RDS for Jenkins metadata
* *Resource Tagging* Enhanced cost allocation and resource management
* *Environment Promotion* Automated dev/staging/prod pipeline promotion

