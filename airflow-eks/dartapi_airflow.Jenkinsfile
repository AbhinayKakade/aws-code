pipeline { 
    agent any 
    environment {
        SVC_ACCOUNT_KEY = credentials('gcp-devops-sa')
    }
    
     stages { 
        
          stage('SonarQube-Scanning') { 
             steps { 
                 git branch: '${BRANCH_FOR_SONARQUBE}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/v2-dart-airflow.git'
                 script {
                    def scannerHome = tool 'sonar_scanner';
                         withSonarQubeEnv("Prod-SonarQube") {
                         sh "/opt/sonar-scanner/bin/sonar-scanner \
                         -Dsonar.projectKey=dart-api-airflow \
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
                            echo "$p" | awk -F '=' '{print $1}' | tee -a /var/lib/jenkins/Docker-Kubernetes/dartapi-airflow/requirements.txt
                        done <<< "${ADD_REQUIREMENT}"
                        '''
                    }
                    sh "cp -r /var/lib/jenkins/Docker-Kubernetes/dartapi-airflow/. ./Docker/"
                    docker.build("dart-api-airflow:latest", "-f Docker/Dockerfile ./Docker")
               }
           
           }
        
         }
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
                        docker tag dart-api-airflow:latest us-east4-docker.pkg.dev/experiencedotcom-devops/experiencedotcom-dev/"${DARTAPI_AIRFLOW_REPOSITORY}":"${TAG}"
                        docker push us-east4-docker.pkg.dev/experiencedotcom-devops/experiencedotcom-dev/"${DARTAPI_AIRFLOW_REPOSITORY}":"${TAG}"
                        gcloud container clusters get-credentials "airflow-gke-dev" --region "us-east4" --project "experiencedotcom-dev"
                        ls -la ${env.WORKSPACE}/
                        cd ${env.WORKSPACE}/deployment_pipelines/airflow-eks
                        ls -la
                        helm version
                        helm upgrade --install airflow apache-airflow/airflow -n "${DARTAPI_AIRFLOW_NAMESPACE}" -f values-dart-api.yaml --debug 
                        helm version
                        helm ls -n "${DARTAPI_AIRFLOW_NAMESPACE}"
                    """
				}
			}
		}
        // stage('Get the  files') { 
         
        //    when {
        //         expression{ params.ROLLBACK == false }
        //     }
        //     steps { 
                
        //         sh'''aws eks update-kubeconfig --name "${AIRFLOW_CLUSTER_NAME_NEW}" --profile "${CLUSTER_PROFILE}" --region "${CLUSTER_REGION}"  
        //           cd /var/lib/jenkins/Docker-Kubernetes/dartapi-airflow/
        //           sed -i 's/branch:.*/'"branch: $BRANCH"'/g' values.yaml
        //           helm upgrade --install airflow apache-airflow/airflow -n "${DARTAPI_AIRFLOW_NAMESPACE}" -f values.yaml 
        //           helm ls -n "${DARTAPI_AIRFLOW_NAMESPACE}"
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
                        helm rollback airflow -n "${DARTAPI_AIRFLOW_NAMESPACE}"
                        helm ls -n "${DARTAPI_AIRFLOW_NAMESPACE}"
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