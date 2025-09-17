#!groovy

import jenkins.model.Jenkins

def jenkins = Jenkins.instance

jenkins.setNumExecutors(0)
jenkins.save()
