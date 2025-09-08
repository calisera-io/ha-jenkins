## Create Jenkins Worker AMI with Packer

```bash
cd worker
packer fmt .
packer validate .
packer build .
```