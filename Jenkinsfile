pipeline {
    agent any
    environment {
        PROJECT_ID = 'prefab-faculty-350219' // Set your Google Cloud project ID
        REGION = 'us-central1' // Set your desired region
    }
    triggers {
        // Poll SCM every minute for changes (adjust the interval if necessary)
        pollSCM('H/1 * * * *')
    }
    
    stages {
        stage('Checkout') {
            steps {
                // Clone the latest code from the repository
                git url: 'https://github.com/ptemnorusov/jenkins-gcp-deploy.git', branch: 'main'
            }
        }
        stage('Terraform Init and Apply') {
            steps {
                // Use withCredentials to inject the Google Cloud service account JSON as an environment variable
                withCredentials([file(credentialsId: 'gcp-svc', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        // Initialize Terraform
                        sh 'terraform init'
                        
                        // Apply Terraform configuration
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }
    }
    // post {
    //     always {
    //         // Archive state files to preserve them for future builds
    //         archiveArtifacts artifacts: 'terraform.tfstate*'
    //         cleanWs() // Clean up other workspace files
    //     }
    // }
}
