pipeline {
    agent any
    environment {
        SVC_ACCOUNT_KEY = credentials('gcp-devops-sa')
    }
    stages {

        stage('Checkout to branch') { 

            steps { 
                git branch: '${BRANCH}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/experience-gcp-infra.git'
            }

        }


        stage('Terraform Install') {
            steps {
                script {
                    // Check if the terraform command is available
                    def terraformCommandStatus = sh(script: 'terraform --version', returnStatus: true)

                    if (terraformCommandStatus == 0) {
                        echo "Terraform is already installed. Skipping installation."
                    } else {
                        // Define the Terraform version you want to install
                        def terraformVersion = "1.6.1"

                        // Define the download URL for Terraform based on the version
                        def downloadUrl = "https://releases.hashicorp.com/terraform/${terraformVersion}/terraform_${terraformVersion}_linux_amd64.zip"

                        // Create a directory to store the Terraform binary
                        def terraformDir = "${env.WORKSPACE}/terraform-binary"

                        // Download and unzip Terraform
                        sh "mkdir -p ${terraformDir}"
                        sh "curl -o ${terraformDir}/terraform.zip ${downloadUrl}"
                        sh "unzip -o ${terraformDir}/terraform.zip -d ${terraformDir}"

                        // Verify Terraform installation
                        sh "echo \$PATH"
                        env.PATH = "${terraformDir}:${env.PATH}"
                        sh "echo \$PATH"
                        sh "terraform --version"
                    }
                }
            }
        }

        stage('Build Dev Environment') {
			environment{
				ENV = "dev"
            }
            steps {
                dir("Infrastructure/Terraform/envs/${ENV}") {
               
                // Verify the installation
                sh 'terraform -version'

                // Setting up credentials
                sh 'echo $SVC_ACCOUNT_KEY | base64 -d > key.json'
                
                // Get the public IP and append "/32"
                sh '''
                    publicIp=$(curl -s ifconfig.me)
                    sed -i "s/IP/$publicIp/g" terraform.tfvars
                '''

                sh 'ls -la'
                sh 'cat key.json'
                
                // Run Terraform init
                // sh 'terraform init -backend-config="credentials=key.json"'
                
                sh 'terraform init'
                

                // Validate terraform Script
                sh 'terraform validate'
                
                // Create Workspace
                sh 'terraform workspace select ${ENV} || terraform workspace new ${ENV}'  
                
                // Run Terraform Plan
                sh 'terraform plan -out ${ENV}.tfplan'
                }
            }
        }

        stage('Approval for Dev') {
          steps {
            script {
              def userInput = input(id: 'confirm', message: 'Apply Terraform for Dev?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Apply Terraform for Dev', name: 'confirm'] ])
            }
          }
        }
        stage('Create Dev Infra') {
			environment{
				ENV = "dev"
            }
            steps {
                dir("Infrastructure/Terraform/envs/${ENV}") {
                    sh 'terraform apply -input=false ${ENV}.tfplan'
                }
            }
        }
    }
}