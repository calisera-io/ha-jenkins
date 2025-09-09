#!groovy

import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*
import jenkins.model.*

def credentialId   = "jenkins-worker"
def username       = "ec2-user"
def passphrase     = "" 
def description    = "Worker private key"

def domain = Domain.global()
def store = Jenkins.instance.getExtensionList(
    'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
)[0].getStore()

def existing = store.getCredentials(domain).find { it.id == credentialId }
if (existing) {
    println "Credential '${credentialId}' already exists. Skipping creation."
    return
}

def keySource = new BasicSSHUserPrivateKey.UsersPrivateKeySource()
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
