pipeline {
    agent any
    environment {
        PROJECT_ID = 'prefab-faculty-350219'
        REGION = 'us-central1'
    }
    triggers {
        // Poll SCM every minute for changes in specific paths (adjust frequency as needed)
        pollSCM('H/1 * * * *')
    }
    stages {
        stage('Checkout') {
            steps {
                // Check out the repository from GitHub
                git url: 'https://github.com/ptemnorusov/jenkins-gcp-deploy.git', branch: 'main'
            }
        }
        stage('Detect Changes') {
            steps {
                script {
                    // Get the list of changed files in the latest commit
                    def changes = sh(script: "git diff-tree --no-commit-id --name-only -r HEAD", returnStdout: true).trim()
                    // Check if any changes are in the root directory or in the 'site' folder
                    def redeploy = changes.split('\n').any { it.startsWith("site/") || !it.contains("/") }
                    
                    // If no relevant changes, skip the deployment stage
                    if (!redeploy) {
                        currentBuild.result = 'SUCCESS'
                        echo "No changes in root or 'site' directory. Skipping deployment."
                        return
                    }
                }
            }
        }
        stage('Terraform Init and Apply') {
            steps {
                // Use withCredentials to set GOOGLE_APPLICATION_CREDENTIALS from Jenkins credentials
                withCredentials([file(credentialsId: 'gcp-svc', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        // Initialize and apply Terraform
                        powershell 'terraform init'
                        powershell 'terraform apply -auto-approve'
                    }
                }
            }
        }
    }
    post {
        always {
            cleanWs() // Clean up workspace after build
        }
    }
}
