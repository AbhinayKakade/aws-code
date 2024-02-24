pipeline { 

    agent any 

    stages { 

        stage('Get the Deployment files') { 


            // steps { 
            //     git branch: '${SS_OPS_DEPLOYMENT_BRANCH}', credentialsId: 'v2-sandbox-jenkins', url: 'git@bitbucket.org:experience-com/ss-ops.git'
            //     fileOperations([folderCreateOperation('Docker'), folderCreateOperation('Kubernetes'), folderCopyOperation(destinationFolderPath: 'Docker', sourceFolderPath: 'deployment_pipelines/delayed-jobs-eks/Docker'), folderCopyOperation(destinationFolderPath: 'Kubernetes', sourceFolderPath: 'deployment_pipelines/delayed-jobs-eks/Kubernetes')])
            // }

            steps { 
                git branch: 'cwx-gcp-migration-prod-eks', credentialsId: 'v2-sandbox-jenkins', url: 'git@bitbucket.org:experience-com/ss-ops.git'
                fileOperations([folderCreateOperation('Docker'), folderCreateOperation('Kubernetes'), folderCopyOperation(destinationFolderPath: 'Docker', sourceFolderPath: 'deployment_pipelines/delayed-jobs-eks/Docker'), folderCopyOperation(destinationFolderPath: 'Kubernetes', sourceFolderPath: 'deployment_pipelines/delayed-jobs-eks/Kubernetes')])
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
                    sh '''COUNT=$(ls /var/lib/jenkins/Docker-Kubernetes/credentials/delayed-jobs/delayed-jobs* | wc -l)
                        if [ "${COUNT}" -gt 30 ]; then
                            rm "$(ls -t /var/lib/jenkins/Docker-Kubernetes/credentials/delayed-jobs/delayed-jobs* | tail -1)"
                        fi
                        cp /var/lib/jenkins/Docker-Kubernetes/delayed-jobs/delayed-jobs.env /var/lib/jenkins/Docker-Kubernetes/credentials/delayed-jobs/"delayed-jobs-${BUILD_NUMBER}.env"
                    '''
                    sh "cp -r /var/lib/jenkins/Docker-Kubernetes/delayed-jobs/. ./Docker/"
                    env.PATH = "/var/lib/jenkins/google-cloud-sdk/bin:$PATH"
                    sh '''
                        echo ${SVC_ACCOUNT_KEY} | base64 -d > gcp-sa.json
                        gcloud auth activate-service-account --key-file=gcp-sa.json
                        gcloud auth configure-docker us-east4-docker.pkg.dev
                        docker-credential-gcr configure-docker
                        docker build -t delayed-jobs:latest --build-arg RAILS_ENV=${env.DEVTEST_RAILS_ENV} --build-arg SECRET_KEY_BASE=${RAILS_SECRET_KEY_BASE} -f Docker/Ubuntu.DockerFile .
                    '''
                    }
                }
        } 

        stage('Pushing docker image') { 

            when {
                expression{ params.ROLLBACK == false }
            }

                script
                {
                    env.PATH = "/var/lib/jenkins/google-cloud-sdk/bin:$PATH"

                    sh '''
                        echo \${SVC_ACCOUNT_KEY} | base64 -d > gcp-sa.json
                        gcloud auth activate-service-account --key-file=gcp-sa.json
                        gcloud auth configure-docker us-east4-docker.pkg.dev
                        docker tag delayed-jobs:latest us-east4-docker.pkg.dev/experiencedotcom-devops/experiencedotcom-dev/"${RAILS_DELAYED_JOBS_REPOSITORY}":"${TAG}"
                        docker tag delayed-jobs:latest us-east4-docker.pkg.dev/experiencedotcom-devops/experiencedotcom-dev/"${RAILS_DELAYED_JOBS_REPOSITORY}":"${BUILD_NUMBER}"
                        docker push us-east4-docker.pkg.dev/experiencedotcom-devops/experiencedotcom-dev/"${WORKER_REPOSITORY}:${TAG}" us-east4-docker.pkg.dev/experiencedotcom-devops/experiencedotcom-dev/"${WORKER_REPOSITORY}:${BUILD_NUMBER}"
                        docker rmi rails-api-ubuntu
                        docker rmi us-east4-docker.pkg.dev/experiencedotcom-devops/experiencedotcom-dev/"${WORKER_REPOSITORY}"
                        gcloud container clusters get-credentials "experiencedotcom-gke-dev" --region "us-east4-a" --project "experiencedotcom-dev"
                        set +x
                        . /var/lib/jenkins/Docker-Kubernetes/kubernetes.env
                        set -x
                        if kubectl get namespace "${RAILS_DELAYED_JOBS_NAMESPACE}"; then
                            envsubst < ./Kubernetes/deploy.yaml   | kubectl rollout restart -f -
                        else
                            envsubst < ./Kubernetes/delayed_jobs_deploy.yaml   | kubectl apply -f -
                        fi
                    '''
                }
            }
        } 

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
        //                 if kubectl get namespace "${RAILS_DELAYED_JOBS_NAMESPACE}"; then
        //                     envsubst < ./Kubernetes/deploy.yaml   | kubectl rollout restart -f -
        //                 else
        //                     envsubst < ./Kubernetes/delayed_jobs_deploy.yaml   | kubectl apply -f -
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

                script {
                    env.PATH = "/var/lib/jenkins/google-cloud-sdk/bin:$PATH"
                    sh '''
                        echo \${SVC_ACCOUNT_KEY} | base64 -d > gcp-sa.json
                        gcloud auth activate-service-account --key-file=gcp-sa.json
                        gcloud container clusters get-credentials "experiencedotcom-gke-dev" --region "us-east4-a" --project "experiencedotcom-dev"
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
