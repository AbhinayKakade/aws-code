pipeline { 

    agent any 

    environment {
        SVC_ACCOUNT_KEY = credentials('gcp-devops-sa')
    }

     stages { 
        
         stage('SonarQube-Scanning') { 
            steps { 
                git branch: '${BRANCH_FOR_SONARQUBE}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/v2-airflow.git'
                script {
                    def scannerHome = tool 'sonar_scanner';
                        withSonarQubeEnv("Prod-SonarQube") {
                        sh "/opt/sonar-scanner/bin/sonar-scanner \
                        -Dsonar.projectKey=ipro-airflow \
                        -Dsonar.sources=. \
                        -Dsonar.css.node=. \
                        -Dsonar.host.url=http://192.168.5.130:9000"
                        }
                cleanWs()
            }
          }
       
         }
         
         stage('Building Docker image') { 
        
            when {
                expression{ params.REQUIREMENT == true }
            }
            
            steps{
               
               script {
                   
                   if ( params.ADD_REQUIREMENT != "" ) {
                        sh '''#!/bin/bash
                        while read -r p; do
                            echo "$p" | awk -F '=' '{print $1}' | tee -a /var/lib/jenkins/Docker-Kubernetes/ipro-airflow/requirements.txt
                        done <<< "${ADD_REQUIREMENT}"
                        '''
                    }
                    sh "cp -r /var/lib/jenkins/Docker-Kubernetes/ipro-airflow/. ./Docker/"
                    // docker.build("ipro-airflow:latest", "-f Docker/Dockerfile .")
                    sh "pwd"
                    sh "ls -la"                    
                    sh "ls -la ./Docker"
                    docker.build("ipro-airflow:latest", "-f Docker/Dockerfile ./Docker") 
               }
           
           }
        
         }

        //  stage('Pushing docker image') { 

        //     when {
        //         expression{ params.REQUIREMENT == true }
        //     }

        //     steps { 

        //         script
        //         {
        //             sh '''aws ecr get-login-password --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" | docker login --username AWS --password-stdin "${AWS_ECR_ACCOUNT}"
        //                 docker tag ipro-airflow:latest "${AWS_ECR_ACCOUNT}"/"${IPRO_AIRFLOW_REPOSITORY}":"${TAG}"
        //                 docker push ${AWS_ECR_ACCOUNT}/"${IPRO_AIRFLOW_REPOSITORY}":"${TAG}"
        //                 MANIFEST=$(aws ecr batch-get-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${IPRO_AIRFLOW_REPOSITORY}" --image-ids imageTag="${TAG}" --query 'images[].imageManifest' --output text)
        //                 aws ecr put-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${IPRO_AIRFLOW_REPOSITORY}" --image-tag "${BUILD_NUMBER}" --image-manifest "$MANIFEST"
        //                 docker rmi ipro-airflow
        //                 docker rmi ${AWS_ECR_ACCOUNT}/"${IPRO_AIRFLOW_REPOSITORY}"'''

        //         }
        //     }
        // }
         
		stage('Pushing docker image') {
            
            when {
                expression{ params.REQUIREMENT == true }
            }
			steps {
                git branch: '${BRANCH}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/ss-ops.git'
				script {
                    sh """
                        curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-337.0.0-linux-x86_64.tar.gz
                        tar -xvf google-cloud-sdk-337.0.0-linux-x86_64.tar.gz
                        ./google-cloud-sdk/install.sh
                        export PATH="$PATH:$WORKSPACE/google-cloud-sdk/bin"
                        echo "${SVC_ACCOUNT_KEY}" | base64 -d > gcp-sa.json
                        gcloud auth activate-service-account --key-file=gcp-sa.json
                        gcloud auth configure-docker us-east4-docker.pkg.dev
                        docker tag ipro-airflow:latest us-east4-docker.pkg.dev/experiencedotcom-devops/experiencedotcom-dev/"${IPRO_AIRFLOW_REPOSITORY}":"${TAG}"
                        docker push us-east4-docker.pkg.dev/experiencedotcom-devops/experiencedotcom-dev/"${IPRO_AIRFLOW_REPOSITORY}":"${TAG}"
                        gcloud container clusters get-credentials "airflow-gke-dev" --region "us-east4" --project "experiencedotcom-dev"
                        ls -la ${env.WORKSPACE}/
                        cd ${env.WORKSPACE}/deployment_pipelines/airflow-eks
                        ls -la
                        helm upgrade --install airflow apache-airflow/airflow -n "${IPRO_AIRFLOW_NAMESPACE}" -f values-ipro.yaml 
                        helm ls -n "${IPRO_AIRFLOW_NAMESPACE}"
                    """
				}
			}
		}   
        
        
        // stage('Get the  files') { 
         
        //    when {
        //         expression{ params.ROLLBACK == false }
        //     }

        //     steps { 
                
        //         sh''' aws eks update-kubeconfig --name "${AIRFLOW_CLUSTER_NAME_NEW}" --profile "${CLUSTER_PROFILE}" --region "${CLUSTER_REGION}" 
        //           cd /var/lib/jenkins/Docker-Kubernetes/ipro-airflow/
        //           sed -i 's/branch:.*/'"branch: $BRANCH"'/g' values.yaml
        //           helm upgrade --install airflow apache-airflow/airflow -n "${IPRO_AIRFLOW_NAMESPACE}" -f values.yaml 
        //           helm ls -n "${IPRO_AIRFLOW_NAMESPACE}"

        //           '''
        //     }

        // }
        
        stage('Rolling back to a previous image') { 

            when {
                expression{ params.ROLLBACK == true }
            }

            steps { 

                script
                {
                    sh '''
                        helm rollback airflow -n "${IPRO_AIRFLOW_NAMESPACE}"
                        helm ls -n "${IPRO_AIRFLOW_NAMESPACE}"
                        '''

                }

            }

        }
        
        
    }
    post {
        always {
            script {
                // Delete the current workspace
                sh "rm -rf ${env.WORKSPACE}/google-cloud-sdk"
                sh "rm -rf ${env.WORKSPACE}/gcp-sa.json"
            }
        }
    }
  }