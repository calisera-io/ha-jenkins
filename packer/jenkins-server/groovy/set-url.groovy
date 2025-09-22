import jenkins.model.*
import jenkins.model.JenkinsLocationConfiguration

def command = "curl -s http://169.254.169.254/latest/meta-data/local-ipv4"
def process = command.execute()
process.waitFor()

def localIpv4 = process.text

def jenkinsLocationConfiguration = JenkinsLocationConfiguration.get()

def newUrl = "http://${localIpv4}:8080/"
jenkinsLocationConfiguration.setUrl(newUrl)

jenkinsLocationConfiguration.save()