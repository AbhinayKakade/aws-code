pipeline { 

    agent any 

    stages { 

        stage('SonarQube-Scanning') { 
            steps { 
                git branch: '${BRANCH}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/ipro.git'
                script {
                    def scannerHome = tool 'sonar_scanner';
                        withSonarQubeEnv("Prod-SonarQube") {
                        sh "/opt/sonar-scanner/bin/sonar-scanner \
                        -Dsonar.projectKey=integrations \
                        -Dsonar.sources=. \
                        -Dsonar.css.node=. \
                        -Dsonar.host.url=http://192.168.5.130:9000"
                        }
                cleanWs()
            }
            }

        }
        
     /*   stage("Quality Gate") {
            steps {
              timeout(time: 1, unit: 'HOURS') {
                waitForQualityGate abortPipeline: false
              }
            }
          }
        */
        stage('Get the Deployment files') { 

            steps { 
                git branch: '${SS_OPS_DEPLOYMENT_BRANCH}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/ss-ops.git'
                fileOperations([folderCreateOperation('Docker'), folderCreateOperation('Kubernetes'), folderCopyOperation(destinationFolderPath: 'Docker', sourceFolderPath: 'deployment_pipelines/ingestion-eks/Docker'), folderCopyOperation(destinationFolderPath: 'Kubernetes', sourceFolderPath: 'deployment_pipelines/ingestion-eks/Kubernetes')])
            }

        }

        stage('Checkout to branch') { 

            steps { 
                git branch: '${BRANCH}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/ipro.git'
            }

        } 

        stage('Building Docker image') { 

            when {
                expression{ params.ROLLBACK == false }
            }

            steps{

                script {  

                    if ( params.DEL_ENV_VAR != "" ) {

                        sh '''#!/bin/bash
                        while read -r p; do
                            sed -i "/^$p=/d" /var/lib/jenkins/Docker-Kubernetes/ingestion/ingestion-secret.env
                        done <<< "${DEL_ENV_VAR}"
                        '''
                    }  

                    if ( params.ADD_ENV_VAR != "" ) {

                        sh '''#!/bin/bash
                        while read -r p; do
                            echo "$p" | awk -F '=' '{printf $1"="}' | tee -a /var/lib/jenkins/Docker-Kubernetes/ingestion/ingestion-secret.env
                            echo "$p" | awk -F '"' '{print $2}' | tee -a /var/lib/jenkins/Docker-Kubernetes/ingestion/ingestion-secret.env
                        done <<< "${ADD_ENV_VAR}"
                        '''
                    }  
                    sh '''COUNT=$(ls /var/lib/jenkins/Docker-Kubernetes/credentials/ingestion/ingestion-secret* | wc -l)
                        if [ "${COUNT}" -gt 30 ]; then
                            rm "$(ls -t /var/lib/jenkins/Docker-Kubernetes/credentials/ingestion/ingestion-secret* | tail -1)"
                        fi
                        cp /var/lib/jenkins/Docker-Kubernetes/ingestion/ingestion-secret.env /var/lib/jenkins/Docker-Kubernetes/credentials/ingestion/"ingestion-secret-${BUILD_NUMBER}.env"
                    '''     
                    sh "cp -r /var/lib/jenkins/Docker-Kubernetes/ingestion/. ./Docker/"
                    withCredentials([usernamePassword(credentialsId: 'BIT_BUCKET_IPRO_CREDENTIALSID', passwordVariable: 'BIT_BUCKET_IPRO_PASSWORD', usernameVariable: 'BIT_BUCKET_IPRO_USERNAME')]) {
                            docker.build("ingestion:latest", "--build-arg USERNAME=${BIT_BUCKET_IPRO_USERNAME} --build-arg PASSWORD=${BIT_BUCKET_IPRO_PASSWORD} -f Docker/Dockerfile .")
                        }
                    }
                
                }

        } 

        stage('Pushing docker image') { 

            when {
                expression{ params.ROLLBACK == false }
            }

            steps { 

                script
                {
                    sh '''aws ecr get-login-password --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" | docker login --username AWS --password-stdin "${AWS_ECR_ACCOUNT}"
                        docker tag ingestion:latest "${AWS_ECR_ACCOUNT}"/"${INGESTION_REPOSITORY}":"${TAG}"
                        docker push ${AWS_ECR_ACCOUNT}/"${INGESTION_REPOSITORY}":"${TAG}"
                        MANIFEST=$(aws ecr batch-get-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${INGESTION_REPOSITORY}" --image-ids imageTag="${TAG}" --query 'images[].imageManifest' --output text)
                        aws ecr put-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${INGESTION_REPOSITORY}" --image-tag "${BUILD_NUMBER}" --image-manifest "$MANIFEST"
                        docker rmi ingestion
                        docker rmi ${AWS_ECR_ACCOUNT}/"${INGESTION_REPOSITORY}"'''

                }
            }
        } 

        stage('Deploying the new image') { 

            when {
                expression{ params.ROLLBACK == false }
            }

            steps { 

                script
                {
                    sh '''aws eks update-kubeconfig --name "${CLUSTER_NAME_PROD}" --profile "${CLUSTER_PROFILE}" --region "${CLUSTER_REGION}"
                        set +x
                        . /var/lib/jenkins/Docker-Kubernetes/kubernetes.env
                        set -x
                        if kubectl get namespace "${INGESTION_NAMESPACE}"; then
                            kubectl delete secrets/"${INGESTION_SECRET}" -n "${INGESTION_NAMESPACE}" || echo "Secret is not present in the name space "
                            kubectl create secret generic "${INGESTION_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/ingestion/ingestion-secret.env -n "${INGESTION_NAMESPACE}"
                            envsubst < ./Kubernetes/deploy.yaml   | kubectl rollout restart -f -
                        else
                            envsubst < ./Kubernetes/namespace.yaml  | kubectl apply -f -
                            kubectl create secret generic "${INGESTION_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/ingestion/ingestion-secret.env -n "${INGESTION_NAMESPACE}"
                            envsubst < ./Kubernetes/ingestion_deploy.yaml   | kubectl apply -f -
                        fi
                        '''

                }

            }

        } 

        stage('Rolling back to a previous image') { 

            when {
                expression{ params.ROLLBACK == true }
            }

            steps { 

                script
                {
                    sh '''aws eks update-kubeconfig --name "${CLUSTER_NAME_PROD}" --profile "${CLUSTER_PROFILE}" --region "${CLUSTER_REGION}"
                        set +x
                        . /var/lib/jenkins/Docker-Kubernetes/kubernetes.env
                        set -x
                        export TAG="${ROLLBACK_BUILD_NO}"
                        kubectl delete secrets/"${INGESTION_SECRET}" -n "${INGESTION_NAMESPACE}" || echo "Secret is not present in the name space "
                        kubectl create secret generic "${INGESTION_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/credentials/ingestion/"ingestion-secret-${ROLLBACK_BUILD_NO}.env" -n "${INGESTION_NAMESPACE}"
                        envsubst < ./Kubernetes/deploy.yaml | kubectl rollout restart -f -
                        '''

                }

            }

        }  

    }

    post {
        always {
            script {
                sh '''
                    docker container prune -f || echo "No running containers"
                    docker rmi $(docker images -f "dangling=true" -q) || echo "No dangling images"
                   '''
            }
            cleanWs()
        } 
    }

}
