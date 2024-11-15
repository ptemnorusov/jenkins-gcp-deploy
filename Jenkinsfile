pipeline {
    agent any
    environment {
        PROJECT_ID = 'prefab-faculty-350219' // Set your Google Cloud project ID
        REGION = 'us-central1' // Set your desired region
        TELEGRAM_BOT_TOKEN = credentials('telegram-bot-token') 
        TELEGRAM_CHAT_ID = credentials('tg-chat-id')
    }
    triggers {
        // Poll SCM every minute for changes (adjust the interval if necessary)
        pollSCM('*/1 * * * *')
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
    post 
        {
            success {
                // Notify on success
                script {
                    def message = "✅ *Terraform Deployment Success*\nJob: ${env.JOB_NAME}\nBuild: #${env.BUILD_NUMBER}"
                    sendTelegramNotification(message)
                }
            }
            failure {
                // Notify on failure
                script {
                    def message = "❌ *Terraform Deployment Failed*\nJob: ${env.JOB_NAME}\nBuild: #${env.BUILD_NUMBER}"
                    sendTelegramNotification(message)
                }
            }
    //     always {
    //         // There could be an artiface saver
    //         archiveArtifacts artifacts: 'terraform.tfstate*'
    //         cleanWs() // Clean up other workspace files
    //     }
    // }
}

// Function to send a Telegram notification
def sendTelegramNotification(message) {
    sh """
    curl -s -X POST "https://api.telegram.org/bot${env.TELEGRAM_BOT_TOKEN}/sendMessage" \
         -d chat_id=${env.TELEGRAM_CHAT_ID} \
         -d text="${message}" \
         -d parse_mode=Markdown
    """
}
