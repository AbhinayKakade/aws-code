# Dockerizing the application

### Prerequisite

1. Install docker in your system

2. **These files should be inside the [Docker](.) directory**

    1. A [.env](.env.example) file with the required environment variables for the corresponding environment
    2. Mongo DB pem key for the environment with filename __*mongodb.pem*__
    3. RootCA pem key for the environment with filename __*rootCA.pem*__
    4. A [survey-taker.env](survey-taker.env.example) file with the required environment variables for the corresponding environment


### How to build the docker image and run it in local

1. Make sure you have all the above requirements with the corresponding values for the environment you are trying to create the image.
2. clone the repo `git@github.com:BuyersRoad/v2-survey-client.git`
3. Checkout to the branch you want to build
4. Go to the [Docker](.) directory
5. Run the command `docker-compose -f docker-compose.yaml up`, this will build and run the appliction in the machine.
6. Got to __*localhost:8080*__ to check whether the application is running.