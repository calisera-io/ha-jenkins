import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.CredentialsScope
import jenkins.model.*

def env = System.getenv()
def githubUsername = env['GITHUB_USERNAME'] ?: 'username'
def githubToken = env['GITHUB_TOKEN'] ?: 'token'
def credentialsId = "github-token"                 
def description = "GitHub HTTPS Personal Access Token"

def jenkins = Jenkins.instance
def domain = Domain.global()
def store = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

def githubCred = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    credentialsId,
    description,
    githubUsername,
    githubToken
)

def existing = store.getCredentials(domain).find { it.id == credentialsId }
if (existing) {
    println "Credentials with ID '${credentialsId}' already exist. Skipping."
} else {
    store.addCredentials(domain, githubCred)
    println "Credentials with ID '${credentialsId}' added successfully."
}
