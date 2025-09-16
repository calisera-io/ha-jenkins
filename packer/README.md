# Create Jenkins Server and Worker AMI with Packer

## Setup 

### Jenkins admin credentials

Start Hashicorp vault server in development mode:
```bash
pkill vault
vault server -dev
```
Set `jenkins_admin_id` and `jenkins_admin_password` credentials (in new terminal window):
```bash
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN=$(vault print token)
./setup-jenkins-admin-credentials.sh
```
Verify credentials for debugging:
```bash
vault kv get -field=jenkins_admin_id secret/jenkins
vault kv get -field=jenkins_admin_password secret/jenkins
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
