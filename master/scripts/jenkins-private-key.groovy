#!groovy

import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*
import jenkins.model.*

def credentialId   = "jenkins"
def description    = "Jenkins private key"
def username       = "jenkins"
def privateKeyFile = new File("/var/lib/jenkins/.ssh/id_rsa")

if (!privateKeyFile.exists()) {
    println "Private key file not found: ${privateKeyFile}"
    return
}

def privateKey = privateKeyFile.text.trim()
def passphrase = "" 

def domain = Domain.global()
def store = Jenkins.instance.getExtensionList(
    'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
)[0].getStore()

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
