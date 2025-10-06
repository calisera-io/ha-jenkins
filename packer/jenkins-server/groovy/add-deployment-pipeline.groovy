import jenkins.model.*
import org.jenkinsci.plugins.workflow.job.*
import org.jenkinsci.plugins.workflow.cps.*

def jenkins = Jenkins.instance
def jobName = "calisera-deploy"

if (jenkins.getItem(jobName)) {
    println "Job '${jobName}' already exists."
    return
}

def job = new WorkflowJob(jenkins, jobName)
def definition = new CpsFlowDefinition('''
pipeline {
    agent {
        label 'ec2-worker'
    }
    
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_BUCKET = 'blog.calisera.io'
        ARTIFACT_DIR = 'out'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/calisera-io/calisera-project-blog.git', branch: 'main'
            }
        }
        
        stage('Permissions') {
            steps {
                sh 'sudo chown -R jenkins:jenkins /var/lib/jenkins/workspace'
            }
        }
        
        stage('Build') {
            steps {
                script {
                    docker.image('node:20').inside('-u root:root') {
                        sh 'npm ci && npm run build'
                    }
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    docker.image('amazon/aws-cli').inside('--entrypoint="" -u root:root') {
                        sh """
                            aws s3 sync ${ARTIFACT_DIR}/ s3://${AWS_BUCKET}/ --delete \\
                                --region ${AWS_DEFAULT_REGION}
                        """
                    }
                }
            }
        }
    }
}
''', true)

job.setDefinition(definition)
jenkins.add(job, jobName)

println "Pipeline job '${jobName}' created successfully."