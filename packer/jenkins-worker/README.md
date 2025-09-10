## Create Jenkins Worker AMI with Packer

**Note** Variables declared in the packer template `packer/jenkins-worker/template.pkr.hcl` can be overridden using an ignored and untracked file `variables.auto.pkrvars.hcl` in the `packer/jenkins-worker` directory.

```bash
cd worker
packer fmt .
packer validate .
packer build .
```