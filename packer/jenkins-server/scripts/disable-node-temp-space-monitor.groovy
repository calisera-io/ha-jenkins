#!groovy

import jenkins.model.*
import hudson.node_monitors.*

def jenkins = Jenkins.instance

def tempSpaceMonitor = jenkins.getDescriptor(TemporarySpaceMonitor.class)

tempSpaceMonitor.markedOffline = false
tempSpaceMonitor.save()