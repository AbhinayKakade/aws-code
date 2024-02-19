# Deploying docker image to EKS

### Prerequisite

1. Install **kubectl** in your system, refer [here](https://buyersroad.atlassian.net/wiki/spaces/DEV/pages/1899888641/Install+and+Configure+kubectl)
2. Install **eksctl** in your system, refer [here](https://buyersroad.atlassian.net/wiki/spaces/DEV/pages/1897562602/Install+and+setup+eksctl)
3. Install **aws cli** in your system, refer [here](https://buyersroad.atlassian.net/wiki/spaces/DEV/pages/1897627992/Install+and+Setup+AWS+cli)
4. Install **jq** in your system, run `brew install jq`


### How to push  docker image to ECR and deploy image to EKS

1. Create and push the docker image

    1. Make sure you have all the above requirements met.
    2. clone the repo `git@github.com:BuyersRoad/v2-ror-api-backend.git`
    3. Run the command `cd v2-ror-api-backend/Docker/`
    4. Checkout to the branch you want to build
    5. Build the docker image, before you build make sure all prerequisites described in [DOCKER.md](../Docker/DOCKER.md) is met.
        1. If you are using Mac or any devices with x86 processors(eg: machines with intel or amd chips),run `docker build -t rails-api -f Dockerfile --build-arg RAILS_ENV=<env name> --build-arg SECRET_KEY_BASE=<env name>  .. `
        2. If you are using Mac or any devices with ARM-based processor(eg: New mac's with M1 chip), run `docker buildx build --platform linux/amd64 -t rails-api -f Dockerfile --build-arg RAILS_ENV=<env name> --build-arg SECRET_KEY_BASE=<env name>  ..  `
    6. Set up aws configuration for the required environment, run `aws configure`, enter the required values
    7. To list all the EKS cluster names in your environment run ` aws eks list-clusters | jq -r '.clusters[]' `
    8. Select the desired cluster in which you want to deploy your application and run ` aws eks update-kubeconfig --name <cluster name>`
    9. List all the ECR repositories run `aws ecr describe-repositories | jq -r '.repositories[].repositoryUri' `, Choose the rails-api repository you want to push your docker image. 
    10. Retrieve an authentication token and authenticate your Docker client to your registry run ` aws ecr get-login-password | docker login --username AWS --password-stdin <enter the rails-api repository> `
    11. Tag your image to push to repository, run ` docker tag rails-api:<enter tag> <enter the rails-api repository>:<enter tag> `
    12. To push to repository, run ` docker push <enter the rails-api repository>:<enter tag>`

2. To deploy the application to EKS

    1. `cd ` to [Kubernetes directory](.)
    2. Make sure all the variables in YAML files are substituted with required values.
    3. To deploy the application run
        1. To deploy the application run `kubectl apply -f namespace.yaml`
        2. Edit the deploy.yaml file and run `kubectl apply -f deploy.yaml`
        3. Run `kubectl apply -f autoscale.yaml`
        4. Run `kubectl apply -f setup.yaml`
        
        1. `kubectl apply -f workflow.yaml`
        2. `kubectl apply -f collector-deployment.yaml`
        3. `kubectl apply -f dispatcher-deployment.yaml`

    