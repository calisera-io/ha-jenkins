## Create Jenkins Master AMI with Packer

### Template variables

The following variables are declared in the packer template `packer/jenkins-server/template.pkr.hcl` 

* `jenkins_admin`         
* `jenkins_admin_password`
* `shared_credentials_file`
* `profile`
* `region`
* `instance_type`

and can be overridden using an ignored and untracked file `variables.auto.pkrvars.hcl` in the `packer/jenkins-server` directory.

### Packer commands 

```bash
cd packer/jenkins-server
packer init .
packer fmt .
packer validate .
packer build .
```
