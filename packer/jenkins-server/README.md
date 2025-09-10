## Create Jenkins Master AMI with Packer

**Note** Variables declared in the packer template `packer/jenkins-server/template.pkr.hcl` can be overridden using an ignored and untracked file `variables.auto.pkrvars.hcl` in the `packer/jenkins-server` directory.

### Packer commands 

```bash
cd packer/jenkins-server
packer init .
packer fmt .
packer validate .
packer build .
```
