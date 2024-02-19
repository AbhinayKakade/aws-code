pipeline { 

    agent any 

    stages { 

        stage('Get the Deployment files') { 


            steps { 
                git branch: '${SS_OPS_DEPLOYMENT_BRANCH}', credentialsId: 'v2-sandbox-jenkins', url: 'git@bitbucket.org:experience-com/ss-ops.git'
                fileOperations([folderCreateOperation('Docker'), folderCreateOperation('Kubernetes'), folderCopyOperation(destinationFolderPath: 'Docker', sourceFolderPath: 'deployment_pipelines/worker4-eks/Docker'), folderCopyOperation(destinationFolderPath: 'Kubernetes', sourceFolderPath: 'deployment_pipelines/worker4-eks/Kubernetes')])
            }

        }

        stage('Checkout to branch') { 

            when {
                expression{ params.ROLLBACK == false }
            }

            steps { 
                git branch: '${BRANCH}', credentialsId: 'v2-sandbox-jenkins', url: 'git@bitbucket.org:experience-com/v2-ror-api-backend.git'
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
                            sed -i "/^$p:/d" /var/lib/jenkins/Docker-Kubernetes/delayed-jobs/delayed-jobs.env
                        done <<< "${DEL_ENV_VAR}"
                        '''
                    }  

                    if ( params.ADD_ENV_VAR != "" ) {

                        sh '''#!/bin/bash
                        while read -r p; do
                            echo "$p" | awk -F '=' '{printf $1": "}' | tee -a /var/lib/jenkins/Docker-Kubernetes/delayed-jobs/delayed-jobs.env
                            echo "$p" | awk -F '"' '{print $2}' | tee -a /var/lib/jenkins/Docker-Kubernetes/delayed-jobs/delayed-jobs.env
                        done <<< "${ADD_ENV_VAR}"
                        '''
                    }  
                    sh '''COUNT=$(ls /var/lib/jenkins/Docker-Kubernetes/credentials/worker/delayed-jobs* | wc -l)
                        if [ "${COUNT}" -gt 30 ]; then
                            rm "$(ls -t /var/lib/jenkins/Docker-Kubernetes/credentials/worker/delayed-jobs* | tail -1)"
                        fi
                        cp /var/lib/jenkins/Docker-Kubernetes/delayed-jobs/delayed-jobs.env /var/lib/jenkins/Docker-Kubernetes/credentials/worker/"delayed-jobs-${BUILD_NUMBER}.env"
                    '''     
                    sh "cp -r /var/lib/jenkins/Docker-Kubernetes/delayed-jobs/. ./Docker/"
                    withCredentials([usernamePassword(credentialsId: 'EKS_DEVTEST_RAILS_SECRET_KEY_BASE', passwordVariable: 'RAILS_SECRET_KEY_BASE', usernameVariable: 'DEVTEST_RAILS_SECRET_KEY_BASE')]) {
                            docker.build("worker4-rails-api:latest", "--build-arg RAILS_ENV=${env.DEVTEST_RAILS_ENV} --build-arg SECRET_KEY_BASE=${RAILS_SECRET_KEY_BASE} -f Docker/Dockerfile .")
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
                        docker tag worker4-rails-api:latest "${AWS_ECR_ACCOUNT}"/"${WORKER_REPOSITORY}":"${TAG}"
                        docker push ${AWS_ECR_ACCOUNT}/"${WORKER_REPOSITORY}":"${TAG}"
                        MANIFEST=$(aws ecr batch-get-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${WORKER_REPOSITORY}" --image-ids imageTag="${TAG}" --query 'images[].imageManifest' --output text)
                        aws ecr put-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${WORKER_REPOSITORY}" --image-tag "${BUILD_NUMBER}" --image-manifest "$MANIFEST"
                        docker rmi worker4-rails-api
                        docker rmi ${AWS_ECR_ACCOUNT}/"${WORKER_REPOSITORY}"'''

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
                        if kubectl get namespace "${WORKER_RAILSAPI_NAMESPACE}"; then
                            envsubst < ./Kubernetes/collector.yaml  | kubectl rollout restart -f -
                            envsubst < ./Kubernetes/dispacher.yaml  | kubectl rollout restart -f -
                            #envsubst < ./Kubernetes/dispatcher_zero.yaml  | kubectl rollout restart -f -
                            #envsubst < ./Kubernetes/dispatcher_one.yaml  | kubectl rollout restart -f -
                            #envsubst < ./Kubernetes/dispatcher_two.yaml  | kubectl rollout restart -f -
                            #envsubst < ./Kubernetes/dispatcher_three.yaml  | kubectl rollout restart -f -
                            envsubst < ./Kubernetes/surveypull.yaml  | kubectl rollout restart -f -
                            envsubst < ./Kubernetes/social_post_reminder.yaml  |  kubectl rollout restart -f -
                            envsubst < ./Kubernetes/non_survey_campaign.yaml  |  kubectl rollout restart -f -
                        else
                            envsubst < ./Kubernetes/worker_deploy.yaml | kubectl apply -f -
                            envsubst < ./Kubernetes/collector.yaml  | kubectl apply -f -
                            envsubst < ./Kubernetes/dispacher.yaml  | kubectl apply -f -
                            #envsubst < ./Kubernetes/dispatcher_zero.yaml  | kubectl apply -f -
                            #envsubst < ./Kubernetes/dispatcher_one.yaml  | kubectl apply -f -
                            #envsubst < ./Kubernetes/dispatcher_two.yaml  | kubectl apply -f -
                            #envsubst < ./Kubernetes/dispatcher_three.yaml  | kubectl apply -f -
                            envsubst < ./Kubernetes/surveypull.yaml  | kubectl apply -f -
                            envsubst < ./Kubernetes/social_post_reminder.yaml  | kubectl apply -f -
                            envsubst < ./Kubernetes/non_survey_campaign.yaml  | kubectl apply -f -
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
