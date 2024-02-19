# Dockerizing the application

### Prerequisite

1. Install docker in your system

2. **These files should be inside the [Docker](.) directory**

    1. A [.env](.env.example) file with the required environment variables for the corresponding environment
    6. dev_portal.env file with required credentials which are common for the application
    9. A [dev_portal.sh](dev_portal.sh) script with required values.


### How to build the docker image

1. Make sure you have all the above requirements with the corresponding values for the environment you are trying to create the image.
2. clone the repo `git@github.com:BuyersRoad/v2-dev-portal.git`
3. Checkout to the branch you want to build
4. Go to the [Docker](.) directory
5. Run the command `docker-compose -f docker-compose.yaml up`, this will build and run the appliction in the machine.
6. Got to __*localhost:3000*__ to check whether the application is running.
  
