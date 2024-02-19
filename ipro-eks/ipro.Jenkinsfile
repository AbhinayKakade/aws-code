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
                        -Dsonar.projectKey=ipro \
                        -Dsonar.sources=. \
                        -Dsonar.css.node=. \
                        -Dsonar.host.url=http://192.168.5.130:9000"
                        }
                cleanWs()
            }
          }

        }
        
        
        //stage("Quality Gate") {
          //  steps {
            //  timeout(time: 1, unit: 'HOURS') {
              //  waitForQualityGate abortPipeline: false
              //}
            //}
          //}
        
        stage('Get the Deployment files') { 


            steps { 
                git branch: '${SS_OPS_DEPLOYMENT_BRANCH}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/ss-ops.git'
                fileOperations([folderCreateOperation('Docker'), folderCreateOperation('Kubernetes'), folderCopyOperation(destinationFolderPath: 'Docker', sourceFolderPath: 'deployment_pipelines/ipro-eks/Docker'), folderCopyOperation(destinationFolderPath: 'Kubernetes', sourceFolderPath: 'deployment_pipelines/ipro-eks/Kubernetes')])
            }

        }

        stage('Checkout to branch') { 

            when {
                expression{ params.ROLLBACK == false }
            }

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
                            sed -i "/^$p=/d" /var/lib/jenkins/Docker-Kubernetes/ipro/ipro-secret.env
                        done <<< "${DEL_ENV_VAR}"
                        '''
                    }  

                    if ( params.ADD_ENV_VAR != "" ) {

                        sh '''#!/bin/bash
                        while read -r p; do
                            echo "$p" | awk -F '=' '{printf $1"="}' | tee -a /var/lib/jenkins/Docker-Kubernetes/ipro/ipro-secret.env
                            echo "$p" | awk -F '"' '{print $2}' | tee -a /var/lib/jenkins/Docker-Kubernetes/ipro/ipro-secret.env
                        done <<< "${ADD_ENV_VAR}"
                        '''
                    }  
                    sh '''COUNT=$(ls /var/lib/jenkins/Docker-Kubernetes/credentials/ipro/ipro-secret* | wc -l)
                        if [ "${COUNT}" -gt 30 ]; then
                            rm "$(ls -t /var/lib/jenkins/Docker-Kubernetes/credentials/ipro/ipro-secret* | tail -1)"
                        fi
                        cp /var/lib/jenkins/Docker-Kubernetes/ipro/ipro-secret.env /var/lib/jenkins/Docker-Kubernetes/credentials/ipro/"ipro-secret-${BUILD_NUMBER}.env"
                    '''     
                    sh "cp -r /var/lib/jenkins/Docker-Kubernetes/ipro/. ./Docker/"
                    withCredentials([usernamePassword(credentialsId: 'BIT_BUCKET_IPRO_CREDENTIALSID', passwordVariable: 'BIT_BUCKET_IPRO_PASSWORD', usernameVariable: 'BIT_BUCKET_IPRO_USERNAME')]) {
                            docker.build("ipro:latest", "--build-arg USERNAME=${BIT_BUCKET_IPRO_USERNAME} --build-arg PASSWORD=${BIT_BUCKET_IPRO_PASSWORD} -f Docker/Dockerfile .")
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
                        docker tag ipro:latest "${AWS_ECR_ACCOUNT}"/"${IPRO_REPOSITORY}":"${TAG}"
                        docker push ${AWS_ECR_ACCOUNT}/"${IPRO_REPOSITORY}":"${TAG}"
                        MANIFEST=$(aws ecr batch-get-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${IPRO_REPOSITORY}" --image-ids imageTag="${TAG}" --query 'images[].imageManifest' --output text)
                        aws ecr put-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${IPRO_REPOSITORY}" --image-tag "${BUILD_NUMBER}" --image-manifest "$MANIFEST"
                        docker rmi ipro
                        docker rmi ${AWS_ECR_ACCOUNT}/"${IPRO_REPOSITORY}"'''

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
                        if kubectl get namespace "${IPRO_NAMESPACE}"; then
                            kubectl delete secrets/"${IPRO_SECRET}" -n "${IPRO_NAMESPACE}" || echo "Secret is not present in the name space "
                            kubectl create secret generic "${IPRO_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/ipro/ipro-secret.env -n "${IPRO_NAMESPACE}"
                            envsubst < ./Kubernetes/deploy.yaml   | kubectl rollout restart -f -
                        else
                            envsubst < ./Kubernetes/namespace.yaml  | kubectl apply -f -
                            kubectl create secret generic "${IPRO_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/ipro/ipro-secret.env -n "${IPRO_NAMESPACE}"
                            envsubst < ./Kubernetes/ipro_deploy.yaml   | kubectl apply -f -
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
                        kubectl delete secrets/"${IPRO_SECRET}" -n "${IPRO_NAMESPACE}" || echo "Secret is not present in the name space "
                        kubectl create secret generic "${IPRO_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/credentials/ipro/"ipro-secret-${ROLLBACK_BUILD_NO}.env" -n "${IPRO_NAMESPACE}"
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
