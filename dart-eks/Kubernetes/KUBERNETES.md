# Deploying docker image to EKS

### Prerequisite

1. Install **kubectl** in your system, refer [here](https://buyersroad.atlassian.net/wiki/spaces/DEV/pages/1899888641/Install+and+Configure+kubectl)
2. Install **eksctl** in your system, refer [here](https://buyersroad.atlassian.net/wiki/spaces/DEV/pages/1897562602/Install+and+setup+eksctl)
3. Install **aws cli** in your system, refer [here](https://buyersroad.atlassian.net/wiki/spaces/DEV/pages/1897627992/Install+and+Setup+AWS+cli)
4. Install **jq** in your system, run `brew install jq`


### How to push  docker image to ECR and deploy image to EKS

1. Create and push the docker image

    1. Make sure you have all the above requirements met.
    2. clone the repo `git@github.com:BuyersRoad/v2-dart.git`
    3. clone the repo `git@github.com:BuyersRoad/ss-ops.git`
    4. Copy the directories `deployment_pipelines/dart-eks/Kubernetes` and `deployment_pipelines/dart-eks/Docker` to root directory of dart repo
    5. Run the command `cd v2-dart/Docker/`
    6. Checkout to the branch you want to build
    7. Build the docker image, before you build make sure all prerequisites described in [DOCKER.md](../Docker/DOCKER.md) is met.
        1. If you are using Mac or any devices with x86 processors(eg: machines with intel or amd chips),run `docker build -t dart -f Dockerfile .. `
        2. If you are using Mac or any devices with ARM-based processor(eg: New mac's with M1 chip), run `docker buildx build --platform linux/amd64 -t dart -f Dockerfile ..  `
    8. Set up aws configuration for the required environment, run `aws configure`, enter the required values
    9. To list all the EKS cluster names in your environment run ` aws eks list-clusters | jq -r '.clusters[]' `
    10. Select the desired cluster in which you want to deploy your application and run ` aws eks update-kubeconfig --name <cluster name>`
    11. List all the ECR repositories run `aws ecr describe-repositories | jq -r '.repositories[].repositoryUri' `, Choose the dart repository you want to push your docker image. 
    12. Retrieve an authentication token and authenticate your Docker client to your registry run ` aws ecr get-login-password | docker login --username AWS --password-stdin <enter the dart repository> `
    13. Tag your image to push to repository, run ` docker tag dart:<enter tag> <enter the dart repository>:<enter tag> `
    14. To push to repository, run ` docker push <enter the dart repository>:<enter tag>`


2. To deploy the application to EKS

    1. `cd v2-dart/Docker/` [Kubernetes](.) directory and make sure all the variables in YAML files are substituted with required values.
    2. To deploy the application run `kubectl apply -f namespace.yaml`
    3. Add a `kubernetes.env` file in the current folder and add the required env variables in the file.(Note: Format to add env variables `VAR_NAME=VAR_VALUE` Dont use double quotes for values) 
    4. Run `kubectl create secret generic <enter the dart-secret-name> --from-env-file=./kubernetes.env -n <enter the dart namespace>`
    5. Edit the deploy.yaml file and run `kubectl apply -f deploy.yaml`
    6. Run `kubectl apply -f autoscale.yaml`
    7. Run `kubectl apply -f setup.yaml`