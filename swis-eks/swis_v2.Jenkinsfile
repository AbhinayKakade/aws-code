pipeline { 

    agent any

    stages { 

         stage('SonarQube-Scanning') { 
             steps { 
                 git branch: '${BRANCH}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/v2-swis.git'
                 script {
                     def scannerHome = tool 'sonar_scanner';
                         withSonarQubeEnv("Prod-SonarQube") {
                         sh "/opt/sonar-scanner/bin/sonar-scanner \
                         -Dsonar.projectKey=v2-swis \
                         -Dsonar.sources=. \
                         -Dsonar.css.node=. \
                         -Dsonar.host.url=http://192.168.5.130:9000"
                         }
                 cleanWs()
             }
             }

         }
        
        // stage("Quality Gate") {
        //     steps {
        //       timeout(time: 1, unit: 'HOURS') {
        //         waitForQualityGate abortPipeline: false
        //       }
        //     }
        //   }       
        
        stage('Get the Deployment files') { 

            steps { 
                git branch: '${SS_OPS_DEPLOYMENT_BRANCH}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/ss-ops.git'
                fileOperations([folderCreateOperation('Docker'), folderCreateOperation('Kubernetes'), folderCopyOperation(destinationFolderPath: 'Docker', sourceFolderPath: 'deployment_pipelines/swis-eks/Docker'), folderCopyOperation(destinationFolderPath: 'Kubernetes', sourceFolderPath: 'deployment_pipelines/swis-eks/Kubernetes')])
            }

        }

        stage('Checkout to branch') { 

            steps { 
                git branch: '${BRANCH}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/v2-swis.git'
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
                            sed -i "/^$p=/d" /var/lib/jenkins/Docker-Kubernetes/swis/swis-secret.env
                            sed -i "/^export $p=/d" /var/lib/jenkins/Docker-Kubernetes/swis/swis.env
                        done <<< "${DEL_ENV_VAR}"
                        '''
                    } 

                    if ( params.ADD_ENV_VAR != "" ) {
                        sh '''#!/bin/bash
                        while read -r p; do
                            echo "$p" | awk -F '=' '{printf $1"="}' | tee -a /var/lib/jenkins/Docker-Kubernetes/swis/swis-secret.env
                            echo "$p" | awk -F '"' '{print $2}' | tee -a /var/lib/jenkins/Docker-Kubernetes/swis/swis-secret.env
                            echo "$p" | awk -F '=' '{printf "export "$1"="}' | tee -a /var/lib/jenkins/Docker-Kubernetes/swis/swis.env
                            echo "$p" | awk -F '"' '{print $2}' | tee -a /var/lib/jenkins/Docker-Kubernetes/swis/swis.env
                        done <<< "${ADD_ENV_VAR}"
                        '''
                    } 
                    sh '''COUNT=$(ls /var/lib/jenkins/Docker-Kubernetes/credentials/swis/swis-secret* | wc -l)
                        if [ "${COUNT}" -gt 10 ]; then
                            rm "$(ls -t /var/lib/jenkins/Docker-Kubernetes/credentials/swis/swis-secret* | tail -1)"
                        fi
                        cp /var/lib/jenkins/Docker-Kubernetes/swis/swis-secret.env /var/lib/jenkins/Docker-Kubernetes/credentials/swis/"swis-secret-${BUILD_NUMBER}.env"
                    '''    
                    sh "cp -r /var/lib/jenkins/Docker-Kubernetes/swis/. ./Docker/"
                    docker.build("swis:latest", "-f Docker/Dockerfile .")
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
                        docker tag swis:latest "${AWS_ECR_ACCOUNT}"/"${SWIS_REPOSITORY}":"${TAG}"
                        docker push ${AWS_ECR_ACCOUNT}/"${SWIS_REPOSITORY}":"${TAG}"
                        MANIFEST=$(aws ecr batch-get-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${SWIS_REPOSITORY}" --image-ids imageTag="${TAG}" --query 'images[].imageManifest' --output text)
                        aws ecr put-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${SWIS_REPOSITORY}" --image-tag "${BUILD_NUMBER}" --image-manifest "$MANIFEST"
                        docker rmi swis
                        docker rmi ${AWS_ECR_ACCOUNT}/"${SWIS_REPOSITORY}"'''

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
                    sh '''aws eks update-kubeconfig --name "${CLUSTER_NAME}" --profile "${CLUSTER_PROFILE}" --region "${CLUSTER_REGION}"
                        set +x
                        . /var/lib/jenkins/Docker-Kubernetes/kubernetes.env
                        set -x
                        if kubectl get namespace "${SWIS_NAMESPACE}"; then
                            kubectl delete secrets/"${SWIS_SECRET}" -n "${SWIS_NAMESPACE}" || echo "Secret is not present in the name space "
                            kubectl create secret generic "${SWIS_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/swis/swis-secret.env -n "${SWIS_NAMESPACE}"
                            envsubst < ./Kubernetes/deploy.yaml   | kubectl rollout restart -f -
                        else
                            envsubst < ./Kubernetes/namespace.yaml  | kubectl apply -f -
                            kubectl create secret generic "${SWIS_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/swis/swis-secret.env -n "${SWIS_NAMESPACE}"
                            envsubst < ./Kubernetes/swis_deploy.yaml   | kubectl apply -f -
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
                    sh '''aws eks update-kubeconfig --name "${CLUSTER_NAME}" --profile "${CLUSTER_PROFILE}" --region "${CLUSTER_REGION}"
                        set +x
                        . /var/lib/jenkins/Docker-Kubernetes/kubernetes.env
                        set -x
                        export TAG="${ROLLBACK_BUILD_NO}"
                        kubectl delete secrets/"${SWIS_SECRET}" -n "${SWIS_NAMESPACE}" || echo "Secret is not present in the name space "
                        kubectl create secret generic "${SWIS_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/credentials/swis/"swis-secret-${ROLLBACK_BUILD_NO}.env" -n "${SWIS_NAMESPACE}"
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
