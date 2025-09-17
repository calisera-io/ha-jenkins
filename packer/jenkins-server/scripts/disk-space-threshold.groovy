#!groovy

import jenkins.model.*
import hudson.node_monitors.*
import hudson.node_monitors.DiskSpaceMonitorDescriptor.DiskSpace

def jenkins = Jenkins.instance
def diskMonitor = jenkins.getDescriptor(hudson.node_monitors.DiskSpaceMonitor.class)

if (diskMonitor != null) {
    println "Current threshold: ${diskMonitor.freeSpaceThreshold} bytes"

    diskMonitor.setFreeSpaceThreshold("500MB")
    diskMonitor.save()

    println "Updated disk threshold to: ${thresholdBytes} bytes (${thresholdBytes / (1024*1024*1024)} GB)"
} else {
    println "DiskSpaceMonitor not found. Ensure NodeMonitors are enabled."
}