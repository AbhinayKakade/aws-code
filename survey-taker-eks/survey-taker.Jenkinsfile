pipeline { 

    agent any 

    environment {
        SVC_ACCOUNT_KEY = credentials('gcp-devops-sa')
    }

    stages { 

    //     stage('SonarQube-Scanning') { 
    //         steps { 
    //             git branch: '${BRANCH}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/v2-survey-client.git'
    //             script {
    //                 def scannerHome = tool 'sonar_scanner';
    //                     withSonarQubeEnv("Prod-SonarQube") {
    //                     sh "/opt/sonar-scanner/bin/sonar-scanner \
    //                     -Dsonar.projectKey=v2-survey-client \
    //                     -Dsonar.sources=. \
    //                     -Dsonar.css.node=. \
    //                     -Dsonar.host.url=http://192.168.5.130:9000"
    //                     }
    //             cleanWs()
    //         }
    //      }
    //    }
        
        //stage("Quality Gate") {
          //  steps {
            //  timeout(time: 1, unit: 'HOURS') {
                //waitForQualityGate abortPipeline: false
              //}
            //}
          //}
        
        stage('Get the Deployment files') { 

            // steps { 
            //     git branch: '${SS_OPS_DEPLOYMENT_BRANCH}', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/ss-ops.git'
            //     fileOperations([folderCreateOperation('Docker'), folderCreateOperation('Kubernetes'), folderCopyOperation(destinationFolderPath: 'Docker', sourceFolderPath: 'deployment_pipelines/survey-taker-eks/Docker'), folderCopyOperation(destinationFolderPath: 'Kubernetes', sourceFolderPath: 'deployment_pipelines/survey-taker-eks/Kubernetes')])
            // }

            steps { 
                git branch: 'cwx-gcp-migration-prod-eks', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/ss-ops.git'
                fileOperations([folderCreateOperation('Docker'), folderCreateOperation('Kubernetes'), folderCopyOperation(destinationFolderPath: 'Docker', sourceFolderPath: 'deployment_pipelines/survey-taker-eks/Docker'), folderCopyOperation(destinationFolderPath: 'Kubernetes', sourceFolderPath: 'deployment_pipelines/survey-taker-eks/Kubernetes')])
            }

        } 

        stage('Checkout to branch') { 

            steps { 
                git branch: 'cwx-gcp-migration', credentialsId: 'test-cred', url: 'git@bitbucket.org:experience-com/v2-survey-client.git'
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
                            sed -i "/^$p=/d" /var/lib/jenkins/Docker-Kubernetes/survey-taker/survey-taker-secret.env
                            sed -i "/^export $p=/d" /var/lib/jenkins/Docker-Kubernetes/survey-taker/survey-taker.env
                        done <<< "${DEL_ENV_VAR}"
                        '''
                    }  

                    if ( params.ADD_ENV_VAR != "" ) {

                        sh '''#!/bin/bash
                        while read -r p; do
                            echo "$p" | awk -F '=' '{printf $1"="}' | tee -a /var/lib/jenkins/Docker-Kubernetes/survey-taker/survey-taker-secret.env
                            echo "$p" | awk -F '"' '{print $2}' | tee -a /var/lib/jenkins/Docker-Kubernetes/survey-taker/survey-taker-secret.env
                            echo "$p" | awk -F '=' '{printf "export "$1"="}' | tee -a /var/lib/jenkins/Docker-Kubernetes/survey-taker/survey-taker.env
                            echo "$p" | awk -F '"' '{print $2}' | tee -a /var/lib/jenkins/Docker-Kubernetes/survey-taker/survey-taker.env
                        done <<< "${ADD_ENV_VAR}"
                        '''
                    }  
                    sh '''COUNT=$(ls /var/lib/jenkins/Docker-Kubernetes/credentials/survey-taker/survey-taker-secret* | wc -l)
                        if [ "${COUNT}" -gt 20 ]; then
                            rm "$(ls -t /var/lib/jenkins/Docker-Kubernetes/credentials/survey-taker/survey-taker-secret* | tail -1)"
                        fi
                        cp /var/lib/jenkins/Docker-Kubernetes/survey-taker/survey-taker-secret.env /var/lib/jenkins/Docker-Kubernetes/credentials/survey-taker/"survey-taker-secret-${BUILD_NUMBER}.env"
                    '''     
                    sh "cp -r /var/lib/jenkins/Docker-Kubernetes/survey-taker/. ./Docker/"
                    env.PATH = "/var/lib/jenkins/google-cloud-sdk/bin:$PATH"
                    sh '''
                        echo ${SVC_ACCOUNT_KEY} | base64 -d > gcp-sa.json
                        gcloud auth activate-service-account --key-file=gcp-sa.json
                        gcloud auth configure-docker us-east4-docker.pkg.dev
                        docker-credential-gcr configure-docker
                        docker build -t survey-taker:latest -f Docker/Dockerfile .
                    '''
                    // docker.build("survey-taker:latest", "-f Docker/Dockerfile .")
                    }
                }

        } 

        stage('Pushing docker image & Deploying the new image') {
            when {
                expression { params.ROLLBACK == false }
            }
            steps {
                script {
                    env.PATH = "/var/lib/jenkins/google-cloud-sdk/bin:$PATH"
                    sh '''
                        echo \${SVC_ACCOUNT_KEY} | base64 -d > gcp-sa.json
                        gcloud auth activate-service-account --key-file=gcp-sa.json
                        gcloud auth configure-docker us-east4-docker.pkg.dev
                        docker tag survey-taker:latest us-east4-docker.pkg.dev/experiencedotcom-devops/experiencedotcom-dev/"${SURVEY_TAKER_REPOSITORY}":"${TAG}"
                        docker push us-east4-docker.pkg.dev/experiencedotcom-devops/experiencedotcom-dev/"${SURVEY_TAKER_REPOSITORY}":"${TAG}"
                        gcloud container clusters get-credentials "experiencedotcom-gke-dev" --region "us-east4-a" --project "experiencedotcom-dev"
                        set +x
                        . /var/lib/jenkins/Docker-Kubernetes/kubernetes.env
                        set -x
                        if kubectl get namespace "${SURVEY_TAKER_NAMESPACE}"; then
                            kubectl delete secrets/"${SURVEY_TAKER_SECRET}" -n "${SURVEY_TAKER_NAMESPACE}" || echo "Secret is not present in the name space "
                            kubectl create secret generic "${SURVEY_TAKER_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/survey-taker/survey-taker-secret.env -n "${SURVEY_TAKER_NAMESPACE}"
                            envsubst < ./Kubernetes/deploy.yaml   | kubectl rollout restart -f -
                        else
                            envsubst < ./Kubernetes/namespace.yaml  | kubectl apply -f -
                            kubectl create secret generic "${SURVEY_TAKER_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/survey-taker/survey-taker-secret.env -n "${SURVEY_TAKER_NAMESPACE}"
                            envsubst < ./Kubernetes/survey_taker_shorturl_deploy.yaml   | kubectl apply -f -
                            envsubst < ./Kubernetes/survey_taker_deploy.yaml   | kubectl apply -f -  
                        fi               
                    '''
                }
            }
        }



        // stage('Pushing docker image') { 

        //     when {
        //         expression{ params.ROLLBACK == false }
        //     }

        //     steps { 

        //         script
        //         {
        //             sh '''aws ecr get-login-password --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" | docker login --username AWS --password-stdin "${AWS_ECR_ACCOUNT}"
        //                 docker tag survey-taker:latest "${AWS_ECR_ACCOUNT}"/"${SURVEY_TAKER_REPOSITORY}":"${TAG}"
        //                 docker push ${AWS_ECR_ACCOUNT}/"${SURVEY_TAKER_REPOSITORY}":"${TAG}"
        //                 MANIFEST=$(aws ecr batch-get-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${SURVEY_TAKER_REPOSITORY}" --image-ids imageTag="${TAG}" --query 'images[].imageManifest' --output text)
        //                 aws ecr put-image --region "${CLUSTER_REGION}" --profile "${CLUSTER_PROFILE}" --repository-name "${SURVEY_TAKER_REPOSITORY}" --image-tag "${BUILD_NUMBER}" --image-manifest "$MANIFEST"
        //                 docker rmi survey-taker
        //                 docker rmi ${AWS_ECR_ACCOUNT}/"${SURVEY_TAKER_REPOSITORY}"'''

        //         }
        //     }
        // } 

        // stage('Deploying the new image') { 

        //     when {
        //         expression{ params.ROLLBACK == false }
        //     }

        //     steps { 

        //         script
        //         {
        //             sh '''aws eks update-kubeconfig --name "${CLUSTER_NAME_PROD}" --profile "${CLUSTER_PROFILE}" --region "${CLUSTER_REGION}"
        //                 set +x
        //                 . /var/lib/jenkins/Docker-Kubernetes/kubernetes.env
        //                 set -x
        //                 if kubectl get namespace "${SURVEY_TAKER_NAMESPACE}"; then
        //                     kubectl delete secrets/"${SURVEY_TAKER_SECRET}" -n "${SURVEY_TAKER_NAMESPACE}" || echo "Secret is not present in the name space "
        //                     kubectl create secret generic "${SURVEY_TAKER_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/survey-taker/survey-taker-secret.env -n "${SURVEY_TAKER_NAMESPACE}"
        //                     envsubst < ./Kubernetes/deploy.yaml   | kubectl rollout restart -f -
        //                 else
        //                     envsubst < ./Kubernetes/namespace.yaml  | kubectl apply -f -
        //                     kubectl create secret generic "${SURVEY_TAKER_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/survey-taker/survey-taker-secret.env -n "${SURVEY_TAKER_NAMESPACE}"
        //                     envsubst < ./Kubernetes/survey_taker_shorturl_deploy.yaml   | kubectl apply -f -
        //                     envsubst < ./Kubernetes/survey_taker_deploy.yaml   | kubectl apply -f -
        //                 fi
        //                 '''

        //         }

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
                        gcloud container clusters get-credentials "${GKE_CLUSTER_NAME}" --region "${GKE_CLUSTER_REGION}" --project "${GCP_PROJECT_ID}"
                        set +x
                        . /var/lib/jenkins/Docker-Kubernetes/kubernetes.env
                        set -x
                        export TAG=${ROLLBACK_BUILD_NO}
                        kubectl delete secrets/"${SURVEY_TAKER_SECRET}" -n "${SURVEY_TAKER_NAMESPACE}" || echo "Secret is not present in the name space "
                        kubectl create secret generic "${SURVEY_TAKER_SECRET}" --from-env-file=/var/lib/jenkins/Docker-Kubernetes/credentials/survey-taker/"survey-taker-secret-${ROLLBACK_BUILD_NO}.env" -n "${SURVEY_TAKER_NAMESPACE}"
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
                    docker rmi survey-taker:latest || echo "Image gcp-swis:latest not found"
                    docker images
                   '''
            }
            cleanWs()
        } 
    }

}
