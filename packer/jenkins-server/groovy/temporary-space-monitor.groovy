import jenkins.model.Jenkins
import hudson.node_monitors.TemporarySpaceMonitor
import hudson.node_monitors.NodeMonitor

def jenkins = Jenkins.getInstance()
def tempSpaceMonitor = NodeMonitor.getAll().find { it instanceof TemporarySpaceMonitor }

if (tempSpaceMonitor) {
    def thresholdField = tempSpaceMonitor.getClass().getSuperclass().getDeclaredField("freeSpaceThreshold")
    thresholdField.setAccessible(true)
    thresholdField.set(tempSpaceMonitor, "128MiB")
    def warningThresholdField = tempSpaceMonitor.getClass().getSuperclass().getDeclaredField("freeSpaceWarningThreshold")
    warningThresholdField.setAccessible(true)
    warningThresholdField.set(tempSpaceMonitor, "256MiB")
    jenkins.save()
}