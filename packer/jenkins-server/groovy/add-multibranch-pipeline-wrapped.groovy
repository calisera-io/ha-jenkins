import jenkins.model.*
import jenkins.branch.*
import jenkins.plugins.git.*
import org.jenkinsci.plugins.workflow.multibranch.*

def maxTries = 60
def sleepTime = 1000
def ready = false

for (int i = 0; i < maxTries; i++) {
    try {
        if (Jenkins.instance.getExtensionList(jenkins.scm.api.SCMSourceDescriptor.class).size() > 0) {
            ready = true
            break
        }
    } catch (e) {
        println "Waiting for SCM plugins to load..."
        sleep(sleepTime)
    }
}

if (!ready) {
    println "SCM plugins not ready, skipping pipeline creation"
    return
}

def jobName = "Calisera-Blog-Pipeline"
def githubUrl = "https://github.com/calisera-io/calisera-project-blog.git"
def credentialsId = "github-token"

def jenkins = Jenkins.instance

def credentialsStore = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
def credential = credentialsStore.getCredentials(Domain.global()).find { it.id == credentialsId }
if (!credential) {
    println "Credential '${credentialsId}' not found, skipping pipeline creation"
    return
}

if (jenkins.getItem(jobName)) {
    println "Job '${jobName}' already exists."
    return
}

def job = new WorkflowMultiBranchProject(jenkins, jobName)
def gitSource = new GitSCMSource(githubUrl)
gitSource.setCredentialsId(credentialsId)

job.sourcesList.add(new BranchSource(gitSource))
jenkins.add(job, jobName)

println "Multibranch Pipeline '${jobName}' created successfully."
