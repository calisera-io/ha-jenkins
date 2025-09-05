#!groovy

import jenkins.model.*
import hudson.util.*;
import jenkins.install.*;

def instance = Jenkins.getInstance()
def state = InstallState.INITIAL_SETUP_COMPLETED
InstallStateProceededListener.completed(instance, state)
instance.setInstallState(state)