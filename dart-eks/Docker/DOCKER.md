# Dockerizing the application

### Prerequisite

1. Install docker in your system

2. **These files should be inside the [Docker](.) directory**

    1. A [.env](.env.example) file with the required environment variables for the corresponding environment
    2. Newrelic config for the environment with filename __*newrelic.ini*__


### How to build the docker image and run it in local

1. Make sure you have all the above requirements with the corresponding values for the environment you are trying to create the image.
2. clone the repo `git@github.com:BuyersRoad/v2-dart.git`
3. clone the repo `git@github.com:BuyersRoad/ss-ops.git`
4. Copy the directories `deployment_pipelines/dart-eks/Kubernetes` and `deployment_pipelines/dart-eks/Docker` to root directory of v2-dart repo
5. Checkout to the branch you want to build
6. Go to the [Docker](.) directory
7. Run the command `cd v2-dart/Docker/`
8. Run the command `docker-compose -f docker-compose.yaml up`, this will build and run the appliction in the machine.
9. Got to __*localhost:5000*__ to check whether the application is running.