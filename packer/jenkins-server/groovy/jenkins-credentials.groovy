import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*
import jenkins.model.*

def credentialId   = "jenkins"
def username       = "jenkins"
def privateKeyFile = new File("/var/lib/jenkins/.ssh/jenkins_id_rsa")

if (!privateKeyFile.exists()) {
    println "Private key file not found: ${privateKeyFile}"
    return
}

def privateKey     = privateKeyFile.text.trim()
def passphrase     = "" 
def description    = "Jenkins private key"

def domain = Domain.global()
def store = Jenkins.instance.getExtensionList(
    'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
)[0].getStore()

def existing = store.getCredentials(domain).find { it.id == credentialId }
if (existing) {
    println "Credential '${credentialId}' already exists. Skipping creation."
    return
}

def keySource = new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(privateKey)
def sshKeyCredential = new BasicSSHUserPrivateKey(
    CredentialsScope.GLOBAL,
    credentialId,
    username,
    keySource,
    passphrase,
    description
)

store.addCredentials(domain, sshKeyCredential)
println "Credential '${credentialId}' added successfully."
