pipeline { 

    agent any 

    stages { 

        stage('SonarQube-Scanning') { 
            steps { 
                git branch: '${BRANCH}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/v2-dev-portal.git'
                script {
                    def scannerHome = tool 'sonar_scanner';
                        withSonarQubeEnv("Prod-SonarQube") {
                        sh "/opt/sonar-scanner/bin/sonar-scanner \
                        -Dsonar.projectKey=v2-dev-portal \
                        -Dsonar.sources=. \
                        -Dsonar.css.node=. \
                        -Dsonar.host.url=http://192.168.5.130:9000"
                        }
                cleanWs()
            }
            }

        }
        
        
      /*  stage("Quality Gate") {
            steps {
              timeout(time: 1, unit: 'HOURS') {
                waitForQualityGate abortPipeline: false
              }
            }
          }
        */
        stage('Get the Deployment files') { 


            steps { 
                git branch: '${SS_OPS_DEPLOYMENT_BRANCH}', credentialsId: 'test-cred', url: 'https://github.com/BuyersRoad/ss-ops.git'
                fileOperations([folderCreateOperation('Docker'), folderCreateOperation('Kubernetes'), folderCopyOperation(destinationFolderPath: 'Docker', sourceFolderPath: 'deployment_pipelines/dev-portal-eks/Docker'), folderCopyOperation(destinationFolderPath: 'Kubernetes', sourceFolderPath: 'deployment_pipelines/dev-portal-eks/Kubernetes')])
            }

        }

        stage('Checkout to branch') { 

            when {
                expression{ params.ROLLBACK == false }
            }

            steps { 
                git branch: '${BRANCH}', credentialsId: 'test-cred', url: 'https://github.com/BuyersRoad/v2-dev-portal.git'
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
                            sed -i "/^$p:/d" /var/lib/jenkins/Docker-Kubernetes/dev-portal/dev-portal.env
                        done <<< "${DEL_ENV_VAR}"
                        '''
                    }  

                    if ( params.ADD_ENV_VAR != "" ) {

                        sh '''#!/bin/bash
                        while read -r p; do
                            echo "$p" | awk -F '=' '{printf $1": "}' | tee -a /var/lib/jenkins/Docker-Kubernetes/dev-portal/dev-portal.env
                            echo "$p" | awk -F '"' '{print $2}' | tee -a /var/lib/jenkins/Docker-Kubernetes/dev-portal/dev-portal.env
                        done <<< "${ADD_ENV_VAR}"
                        '''
                    }  
                    sh '''COUNT=$(ls /var/lib/jenkins/Docker-Kubernetes/credentials/dev-portal/dev-portal* | wc -l)
                        if [ "${COUNT}" -gt 30 ]; then
                            rm "$(ls -t /var/lib/jenkins/Docker-Kubernetes/credentials/dev-portal/dev-portal* | tail -1)"
                        fi
                        cp /var/lib/jenkins/Docker-Kubernetes/dev-portal/dev-portal.env /var/lib/jenkins/Docker-Kubernetes/credentials/dev-portal/"dev-portal-${BUILD_NUMBER}.env"
                    '''     
                    sh "cp -r /var/lib/jenkins/Docker-Kubernetes/dev-portal/. ./Docker/"
                    withCredentials([usernamePassword(credentialsId: 'EKS_DEVTEST_RAILS_SECRET_KEY_BASE', passwordVariable: 'RAILS_SECRET_KEY_BASE', usernameVariable: 'DEVTEST_RAILS_SECRET_KEY_BASE')]) {
                            docker.build("dev-portal:latest", "--build-arg RAILS_ENV=${env.DEVTEST_RAILS_ENV} --build-arg SECRET_KEY_BASE=${RAILS_SECRET_KEY_BASE} -f Docker/Dockerfile .")
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
                        docker tag dev-portal:latest "${AWS_ECR_ACCOUNT}"/"${DEV_PORTAL_REPOSITORY}":"${TAG}"
                        docker push ${AWS_ECR_ACCOUNT}/"${DEV_PORTAL_REPOSITORY}":"${TAG}"
                        MANIFEST=$(aws ecr batch-get-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${DEV_PORTAL_REPOSITORY}" --image-ids imageTag="${TAG}" --query 'images[].imageManifest' --output text)
                        aws ecr put-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${DEV_PORTAL_REPOSITORY}" --image-tag "${BUILD_NUMBER}" --image-manifest "$MANIFEST"
                        docker rmi dev-portal
                        docker rmi ${AWS_ECR_ACCOUNT}/"${DEV_PORTAL_REPOSITORY}"'''

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
                        if kubectl get namespace "${DEV_PORTAL_NAMESPACE}"; then
                            envsubst < ./Kubernetes/deploy.yaml   | kubectl rollout restart -f -
                        else
                            envsubst < ./Kubernetes/namespace.yaml  | kubectl apply -f -
                            envsubst < ./Kubernetes/dev_portal_deploy.yaml   | kubectl apply -f -
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
