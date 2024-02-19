# Dockerizing the application

### Prerequisite

1. Install docker in your system

2. **These files should be inside the [Docker](.) directory**

    1. A [.env](.env.example) file with the required environment variables for the corresponding environment
    2. Mongo DB pem key for the environment with filename __*mongodb.pem*__
    3. RootCA pem key for the environment with filename __*rootCA.pem*__
    4. RDS pem key for the environment with filename __*rds-combined-ca-bundle.pem*__
    5. SSH key for the required environment with filename __*id_rsa*__
    6. common_credentials.txt file with required credentials which are common for the application
    7. env_credentials.txt file with required credentials for the corresponding environment.
    8. A [.aws](.aws) folder with required files in it
    9. A [credentials.sh](credentials.sh) script with required values.


### How to build the docker image

1. Make sure you have all the above requirements with the corresponding values for the environment you are trying to create the image.
2. clone the repo `git@github.com:BuyersRoad/v2-ror-api-backend.git`
3. Checkout to the branch you want to build
4. Go to the [Docker](.) directory
5. Run the command `docker-compose -f docker-compose.yaml up`, this will build and run the appliction in the machine.
6. Got to __*localhost:3000*__ to check whether the application is running.
  
