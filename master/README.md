## Create Jenkins Master AMI with Packer

```bash
packer validate -var-file=variables.pkrvars.hcl master/template.pkr.hcl
```
```bash
packer build -var-file=variables.pkrvars.hcl master/template.pkr.hcl
```