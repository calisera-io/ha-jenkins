# Create Jenkins Server and Worker AMI with Packer

## Setup 

### Jenkins admin credentials

Set `jenkins_admin_id` and `jenkins_admin_password` credentials in AWS Systems Manager parameter store:
```bash
./setup-jenkins-admin-credentials.sh
```
Verify credentials for debugging:
```bash
aws ssm get-parameter \
  --name "/jenkins/dev/jenkins_admin_id" \
  --with-decryption \
  --query Parameter.Value \
  --output text
aws ssm get-parameter \
  --name "/jenkins/dev/jenkins_admin_password" \
  --with-decryption \
  --query Parameter.Value \
  --output text
```

### Jenkins public/private OpenSSH key pair

```bash
mkdir credentials
ssh-keygen -f credentials/jenkins_id_rsa -N '' -t rsa -b 4096
```

### Set `shared_credentials_file` location

```bash
cd packer/jenkins-<server|worker>
cp variables.auto.pkrvars.hcl.example variables.auto.pkrvars.hcl
```

**Note** All variables declared in a packer template can be overridden using an ignored and untracked file `variables.auto.pkrvars.hcl`.

### Setup Packer IAM user

```bash
./setup-packer-user.sh
```

## Packer commands 

```bash
cd packer/jenkins-<server|worker>
packer init .
packer fmt .
packer validate .
packer build .
```
