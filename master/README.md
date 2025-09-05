## Create Jenkins Master AMI with Packer

To override the `jenkins_admin` and `jenkins_admin_password` defaults create an ignored and untracked file `variables.auto.pkrvars.hcl` in the master directory that conains `jenkins_admin` and `jenkins_admin_password` variable definitions.
```bash
cat master/variables.auto.pkrvars.hcl
jenkins_admin          = "admin"
jenkins_admin_password = "hs!po+a?l12H="
```

```bash
cd master
packer fmt .
packer validate .
packer build .
```