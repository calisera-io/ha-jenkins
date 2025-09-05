## Create Jenkins Master AMI with Packer

The ignored and untracked file `variables.auto.pkrvars.hcl` conains `jenkins_admin` and `jenkins_admin_password` variable definitions.

```bash
cd master
packer fmt .
packer validate .
packer build .
```