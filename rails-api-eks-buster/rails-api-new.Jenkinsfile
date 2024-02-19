pipeline { 

    agent any 

    stages { 
         
        /* 
        stage('SonarQube-Scanning') { 
            steps { 
                git branch: '${BRANCH}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/v2-ror-api-backend.git'
                script {
                    def scannerHome = tool 'sonar_scanner';
                        withSonarQubeEnv("Prod-SonarQube") {
                        sh "/opt/sonar-scanner/bin/sonar-scanner \
                        -Dsonar.projectKey=v2-ror-api-backend \
                        -Dsonar.sources=. \
                        -Dsonar.css.node=. \
                        -Dsonar.host.url=http://192.168.5.130:9000"
                        }
                cleanWs()
            }
          }

        }
        */
        /*
        stage("Quality Gate") {
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
                fileOperations([folderCreateOperation('Docker'), folderCreateOperation('Kubernetes'), folderCopyOperation(destinationFolderPath: 'Docker', sourceFolderPath: 'deployment_pipelines/rails-api-eks-buster/Docker'), folderCopyOperation(destinationFolderPath: 'Kubernetes', sourceFolderPath: 'deployment_pipelines/rails-api-eks-buster/Kubernetes')])
            }

        }

        stage('Checkout to branch') { 

            when {
                expression{ params.ROLLBACK == false }
            }

            steps { 
                git branch: '${BRANCH}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/v2-ror-api-backend.git'
            }

        }

        // stage('Building Buster Docker image') { 

        //     when {
        //         expression{ params.ROLLBACK == false }
        //     }

        //     steps{

        //         script {  

        //             if ( params.DEL_ENV_VAR != "" ) {

        //                 sh '''#!/bin/bash
        //                 while read -r p; do
        //                     sed -i "/^$p:/d" /var/lib/jenkins/Docker-Kubernetes/rails-api/rails-api.env
        //                 done <<< "${DEL_ENV_VAR}"
        //                 '''
        //             }  

        //             if ( params.ADD_ENV_VAR != "" ) {

        //                 sh '''#!/bin/bash
        //                 while read -r p; do
        //                     echo "$p" | awk -F '=' '{printf $1": "}' | tee -a /var/lib/jenkins/Docker-Kubernetes/rails-api/rails-api.env
        //                     echo "$p" | awk -F '"' '{print $2}' | tee -a /var/lib/jenkins/Docker-Kubernetes/rails-api/rails-api.env
        //                 done <<< "${ADD_ENV_VAR}"
        //                 '''
        //             }  
        //             sh '''COUNT=$(ls /var/lib/jenkins/Docker-Kubernetes/credentials/rails-api/rails-api-main* | wc -l)
        //                 if [ "${COUNT}" -gt 30 ]; then
        //                     rm "$(ls -t /var/lib/jenkins/Docker-Kubernetes/credentials/rails-api/rails-api-main*  | tail -1)"
        //                 fi
        //                 cp /var/lib/jenkins/Docker-Kubernetes/rails-api/rails-api.env /var/lib/jenkins/Docker-Kubernetes/credentials/rails-api/"rails-api-main-${BUILD_NUMBER}.env"
        //                 aws ecr get-login-password --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" | docker login --username AWS --password-stdin "${AWS_ECR_ACCOUNT}"
        //             '''     
        //             sh "cp -r /var/lib/jenkins/Docker-Kubernetes/rails-api/. ./Docker/"
        //             withCredentials([usernamePassword(credentialsId: 'EKS_DEVTEST_RAILS_SECRET_KEY_BASE', passwordVariable: 'RAILS_SECRET_KEY_BASE', usernameVariable: 'DEVTEST_RAILS_SECRET_KEY_BASE')]) {
        //                     docker.build("rails-api-buster:latest", "--build-arg RAILS_ENV=${env.DEVTEST_RAILS_ENV} --build-arg SECRET_KEY_BASE=${RAILS_SECRET_KEY_BASE} --build-arg RAILS_MIGRATIONS=${RAILS_MIGRATIONS} --build-arg RAILS_SEED=${RAILS_SEED} -f Docker/Dockerfile-buster .")
        //                 }
        //             }
                
        //         }

        // } 

        // stage('Pushing Buster docker image') { 

        //     when {
        //         expression{ params.ROLLBACK == false }
        //     }

        //     steps { 

        //         script
        //         {
        //             sh '''aws ecr get-login-password --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" | docker login --username AWS --password-stdin "${AWS_ECR_ACCOUNT}"
        //                 docker tag rails-api-buster:latest "${AWS_ECR_ACCOUNT}"/"${RAILS_API_REPOSITORY_BUSTER}":"${TAG}"
        //                 docker push ${AWS_ECR_ACCOUNT}/"${RAILS_API_REPOSITORY_BUSTER}":"${TAG}"
        //                 MANIFEST=$(aws ecr batch-get-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${RAILS_API_REPOSITORY_BUSTER}" --image-ids imageTag="${TAG}" --query 'images[].imageManifest' --output text)
        //                 aws ecr put-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${RAILS_API_REPOSITORY_BUSTER}" --image-tag "${BUILD_NUMBER}" --image-manifest "$MANIFEST"
        //                 docker rmi rails-api-buster
        //                 docker rmi ${AWS_ECR_ACCOUNT}/"${RAILS_API_REPOSITORY_BUSTER}"'''

        //         }
        //     }
        // } 

        stage('Building Ubuntu Docker image') { 

            when {
                expression{ params.ROLLBACK == false }
            }

            steps{

                script {  

                    if ( params.DEL_ENV_VAR != "" ) {

                        sh '''#!/bin/bash
                        while read -r p; do
                            sed -i "/^$p:/d" /var/lib/jenkins/Docker-Kubernetes/rails-api/rails-api.env
                        done <<< "${DEL_ENV_VAR}"
                        '''
                    }  

                    if ( params.ADD_ENV_VAR != "" ) {

                        sh '''#!/bin/bash
                        while read -r p; do
                            echo "$p" | awk -F '=' '{printf $1": "}' | tee -a /var/lib/jenkins/Docker-Kubernetes/rails-api/rails-api.env
                            echo "$p" | awk -F '"' '{print $2}' | tee -a /var/lib/jenkins/Docker-Kubernetes/rails-api/rails-api.env
                        done <<< "${ADD_ENV_VAR}"
                        '''
                    }  
                    sh '''COUNT=$(ls /var/lib/jenkins/Docker-Kubernetes/credentials/rails-api-ubuntu/rails-api* | wc -l)
                        if [ "${COUNT}" -gt 30 ]; then
                            rm "$(ls -t /var/lib/jenkins/Docker-Kubernetes/credentials/rails-api-ubuntu/rails-api* | tail -1)"
                        fi
                        cp /var/lib/jenkins/Docker-Kubernetes/rails-api/rails-api.env /var/lib/jenkins/Docker-Kubernetes/credentials/rails-api-ubuntu/"rails-api-${BUILD_NUMBER}.env"
                        aws ecr get-login-password --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" | docker login --username AWS --password-stdin "${AWS_ECR_ACCOUNT}"
                    '''     
                    sh "cp -r /var/lib/jenkins/Docker-Kubernetes/rails-api/. ./Docker/"
                    withCredentials([usernamePassword(credentialsId: 'EKS_DEVTEST_RAILS_SECRET_KEY_BASE', passwordVariable: 'RAILS_SECRET_KEY_BASE', usernameVariable: 'DEVTEST_RAILS_SECRET_KEY_BASE')]) {
                            docker.build("rails-api-ubuntu:latest", "--build-arg RAILS_ENV=${env.DEVTEST_RAILS_ENV} --build-arg SECRET_KEY_BASE=${RAILS_SECRET_KEY_BASE} --build-arg RAILS_MIGRATIONS=${RAILS_MIGRATIONS} --build-arg RAILS_SEED=${RAILS_SEED} -f Docker/Dockerfile-ubuntu .")
                        }
                    }
                
                }

        } 

        stage('Pushing Ubuntu docker image') { 

            when {
                expression{ params.ROLLBACK == false }
            }

            steps { 

                script
                {
                    sh '''aws ecr get-login-password --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" | docker login --username AWS --password-stdin "${AWS_ECR_ACCOUNT}"
                        docker tag rails-api-ubuntu:latest "${AWS_ECR_ACCOUNT}"/"${RAILS_API_REPOSITORY_UBUNTU}":"${TAG}"
                        docker push ${AWS_ECR_ACCOUNT}/"${RAILS_API_REPOSITORY_UBUNTU}":"${TAG}"
                        MANIFEST=$(aws ecr batch-get-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${RAILS_API_REPOSITORY_UBUNTU}" --image-ids imageTag="${TAG}" --query 'images[].imageManifest' --output text)
                        aws ecr put-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${RAILS_API_REPOSITORY_UBUNTU}" --image-tag "${BUILD_NUMBER}" --image-manifest "$MANIFEST"
                        docker rmi rails-api-ubuntu
                        docker rmi ${AWS_ECR_ACCOUNT}/"${RAILS_API_REPOSITORY_UBUNTU}"'''

                }
            }
        } 

        // stage('Deploying Buster image') { 

        //     when {
        //         expression{ params.ROLLBACK == false }
        //     }

        //     steps { 

        //         script
        //         {
        //             sh '''aws eks update-kubeconfig --name "${CLUSTER_NAME_PROD}" --profile "${CLUSTER_PROFILE}" --region "${CLUSTER_REGION}"
        //                 set +x
        //                 . /var/lib/jenkins/Docker-Kubernetes/kubernetes_rails.env
        //                 set -x
        //                 if kubectl get svc "${RAILS_API_SERVICE_NAME_MAIN}" -n "${RAILS_API_NAMESPACE}"; then
        //                     envsubst < ./Kubernetes/deploy-buster.yaml   | kubectl rollout restart -f -
        //                 else
        //                     envsubst < ./Kubernetes/namespace.yaml  | kubectl apply -f -
        //                     envsubst < ./Kubernetes/rails-deploy-buster.yaml   | kubectl apply -f -
        //                 fi
        //                 '''

        //         }

        //     }

        // } 

        stage('Deploying Ubuntu image') { 

            when {
                expression{ params.ROLLBACK == false }
            }

            steps { 

                script
                {
                    sh '''aws eks update-kubeconfig --name "${CLUSTER_NAME_PROD}" --profile "${CLUSTER_PROFILE}" --region "${CLUSTER_REGION}"
                        set +x
                        . /var/lib/jenkins/Docker-Kubernetes/kubernetes_rails.env
                        set -x
                        if kubectl get svc "${RAILS_API_SERVICE_NAME_UBUNTU}" -n "${RAILS_API_NAMESPACE}"; then
                            envsubst < ./Kubernetes/deploy-ubuntu.yaml   | kubectl rollout restart -f -
                            envsubst < ./Kubernetes/deploy-buster.yaml   | kubectl rollout restart -f -
                        else
                            envsubst < ./Kubernetes/namespace.yaml  | kubectl apply -f -
                            envsubst < ./Kubernetes/rails-deploy-ubuntu.yaml   | kubectl apply -f -
                            envsubst < ./Kubernetes/rails-deploy-buster.yaml   | kubectl apply -f -
                        fi
                        '''

                }

            }

        }

        // stage('Rolling back to a previous Buster image') { 

        //     when {
        //         expression{ params.ROLLBACK == true }
        //     }

        //     steps { 

        //         script
        //         {
        //             sh '''aws eks update-kubeconfig --name "${CLUSTER_NAME_PROD}" --profile "${CLUSTER_PROFILE}" --region "${CLUSTER_REGION}"
        //                 set +x
        //                 . /var/lib/jenkins/Docker-Kubernetes/kubernetes_rails.env
        //                 set -x
        //                 export TAG="${ROLLBACK_BUILD_NO}"
        //                 envsubst < ./Kubernetes/deploy-buster.yaml | kubectl rollout restart -f -
        //                 '''

        //         }

        //     }

        // }

        stage('Rolling back to a previous Ubuntu image') { 

            when {
                expression{ params.ROLLBACK == true }
            }

            steps { 

                script
                {
                    sh '''aws eks update-kubeconfig --name "${CLUSTER_NAME_PROD}" --profile "${CLUSTER_PROFILE}" --region "${CLUSTER_REGION}"
                        set +x
                        . /var/lib/jenkins/Docker-Kubernetes/kubernetes_rails.env
                        set -x
                        export TAG="${ROLLBACK_BUILD_NO}"
                        envsubst < ./Kubernetes/deploy-ubuntu.yaml | kubectl rollout restart -f -
                        envsubst < ./Kubernetes/deploy-buster.yaml | kubectl rollout restart -f -
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

