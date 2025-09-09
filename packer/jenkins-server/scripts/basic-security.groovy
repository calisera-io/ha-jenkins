#!groovy

import jenkins.model.*
import hudson.security.*

def env = System.getenv()
def username = env['JENKINS_USERNAME'] ?: 'username'
def password = env['JENKINS_PASSWORD'] ?: 'password'

def instance = Jenkins.getInstance()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount(username, password)
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()

