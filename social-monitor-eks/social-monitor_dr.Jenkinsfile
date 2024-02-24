pipeline { 

    agent any

    stages { 

        stage('Get the Deployment files') { 

            steps { 
                git branch: '${SS_OPS_DEPLOYMENT_BRANCH}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/ss-ops.git'
                fileOperations([folderCreateOperation('Docker'), folderCreateOperation('Kubernetes'), folderCreateOperation('social-monitor'), folderCopyOperation(destinationFolderPath: 'Docker', sourceFolderPath: 'deployment_pipelines/social-monitor-eks/Docker'), folderCopyOperation(destinationFolderPath: 'Kubernetes', sourceFolderPath: 'deployment_pipelines/social-monitor-eks/Kubernetes')])
            }
        }

        stage('Checkout to branch') { 

            steps { 
                dir("${env.WORKSPACE}/social-monitor") {
                    git branch: '${BRANCH}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/social-monitor.git'
                }
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
                            sed -i "/^$p=/d" /var/lib/jenkins/Docker-Kubernetes/social-monitor/social-monitor-secret.env
                            sed -i "/^export $p=/d" /var/lib/jenkins/Docker-Kubernetes/social-monitor/social-monitor.env
                        done <<< "${DEL_ENV_VAR}"
                        '''
                    } 

                    if ( params.ADD_ENV_VAR != "" ) {
                        sh '''#!/bin/bash
                        while read -r p; do
                            echo "$p" | awk -F '=' '{printf $1"="}' | tee -a /var/lib/jenkins/Docker-Kubernetes/social-monitor/social-monitor-secret.env
                            echo "$p" | awk -F '"' '{print $2}' | tee -a /var/lib/jenkins/Docker-Kubernetes/social-monitor/social-monitor-secret.env
                            echo "$p" | awk -F '=' '{printf "export "$1"="}' | tee -a /var/lib/jenkins/Docker-Kubernetes/social-monitor/social-monitor.env
                            echo "$p" | awk -F '"' '{print $2}' | tee -a /var/lib/jenkins/Docker-Kubernetes/social-monitor/social-monitor.env
                        done <<< "${ADD_ENV_VAR}"
                        '''
                    } 
                    sh '''COUNT=$(ls /var/lib/jenkins/Docker-Kubernetes/credentials/social-monitor/social-monitor-secret* | wc -l)
                        if [ "${COUNT}" -gt 10 ]; then
                            rm "$(ls -t /var/lib/jenkins/Docker-Kubernetes/credentials/social-monitor/social-monitor-secret* | tail -1)"
                        fi
                        cp /var/lib/jenkins/Docker-Kubernetes/social-monitor/social-monitor-secret.env /var/lib/jenkins/Docker-Kubernetes/credentials/social-monitor/"social-monitor-secret-${BUILD_NUMBER}.env"
                    '''    
                    sh '''cp -r /var/lib/jenkins/Docker-Kubernetes/social-monitor/. ./Docker/
                    docker build -t social-monitor:latest -f Docker/Dockerfile .
                    '''
                    
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
                        docker tag social-monitor:latest "${AWS_ECR_ACCOUNT}"/"${SOCIAL_MONITOR_REPOSITORY}":"${TAG}"
                        docker push ${AWS_ECR_ACCOUNT}/"${SOCIAL_MONITOR_REPOSITORY}":"${TAG}"
                        MANIFEST=$(aws ecr batch-get-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${SOCIAL_MONITOR_REPOSITORY}" --image-ids imageTag="${TAG}" --query 'images[].imageManifest' --output text)
                        aws ecr put-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${SOCIAL_MONITOR_REPOSITORY}" --image-tag "${BUILD_NUMBER}" --image-manifest "$MANIFEST"
                        docker rmi social-monitor
                        docker rmi ${AWS_ECR_ACCOUNT}/"${SOCIAL_MONITOR_REPOSITORY}"'''

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
                        if kubectl get namespace "${SOCIAL_MONITOR_NAMESPACE}"; then
                            kubectl delete secrets/"${SOCIAL_MONITOR_SECRET}" -n "${SOCIAL_MONITOR_NAMESPACE}" || echo "Secret is not present in the name space "
                            kubectl create secret generic "${SOCIAL_MONITOR_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/social-monitor/social-monitor-secret.env -n "${SOCIAL_MONITOR_NAMESPACE}"
                            envsubst < ./Kubernetes/deploy.yaml   | kubectl rollout restart -f -
                        else
                            envsubst < ./Kubernetes/namespace.yaml  | kubectl apply -f -
                            kubectl create secret generic "${SOCIAL_MONITOR_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/social-monitor/social-monitor-secret.env -n "${SOCIAL_MONITOR_NAMESPACE}"
                            envsubst < ./Kubernetes/social_monitor_deploy.yaml   | kubectl apply -f -
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
                        kubectl delete secrets/"${SOCIAL_MONITOR_SECRET}" -n "${SOCIAL_MONITOR_NAMESPACE}" || echo "Secret is not present in the name space "
                        kubectl create secret generic "${SOCIAL_MONITOR_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/credentials/social-monitor/"social-monitor-secret-${ROLLBACK_BUILD_NO}.env" -n "${SOCIAL_MONITOR_NAMESPACE}"
                        envsubst < ./Kubernetes/deploy.yaml | kubectl rollout restart -f -
                        '''

                }

            }

        }

        stage('ZAP Full Scan') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh '''docker run -t owasp/zap2docker-stable zap-baseline.py -t https://socialmonitor.devtest.experience.com
                       exit 1
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
