import jenkins.model.*
import jenkins.branch.*
import jenkins.plugins.git.*
import jenkins.plugins.git.traits.*
import org.jenkinsci.plugins.workflow.multibranch.*
import org.jenkinsci.plugins.github_branch_source.*
import jenkins.scm.api.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.hudson.plugins.folder.computed.ComputedFolder

def maxTries = 60
def sleepTime = 1000
def ready = false

for (int i = 0; i < maxTries; i++) {
    try {
        if (Jenkins.instance.getExtensionList(SCMSourceDescriptor.class).size() > 0) {
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

def jobName = "Calisera Blog Deployment"

def credentialsId = "github-token"
def githubOwner = "calisera-io"
def repoName = "calisera-project-blog"
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
def gitSource = new GitHubSCMSource(githubOwner, repoName)
gitSource.setCredentialsId(credentialsId)
gitSource.traits = [
    new BranchDiscoveryTrait(),
    new OriginPullRequestDiscoveryTrait(OriginPullRequestDiscoveryTrait.MERGE),
]
job.sourcesList.add(new BranchSource(gitSource))
jenkins.add(job, jobName)
job.save()
jenkins.save()

println "Multibranch Pipeline '${jobName}' created successfully."

println "Trigger repository indexing"

job.scheduleBuild()
