import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.common.*
import jenkins.branch.*
import jenkins.plugins.git.*
import jenkins.plugins.git.traits.*
import org.jenkinsci.plugins.workflow.multibranch.*
import jenkins.scm.api.*
import jenkins.scm.impl.trait.*

def jobName = "Calisera-Blog-Multibranch-Pipeline"
def githubUrl = "https://github.com/calisera-io/calisera-project-blog.git"
def credentialsId = "github-token"  

def jenkins = Jenkins.instance

def existingJob = jenkins.getItem(jobName)
if (existingJob) {
    println "Job '${jobName}' already exists. Exiting."
} else {
    def job = new WorkflowMultiBranchProject(jenkins, jobName)
    def gitSource = new GitSCMSource(null, githubUrl, credentialsId, "*", "", false)

    gitSource.traits = [
        new BranchDiscoveryTrait()
    ]

    job.sourcesList.add(new BranchSource(gitSource))
    job.save()

    println "Multibranch Pipeline '${jobName}' created successfully."
}
