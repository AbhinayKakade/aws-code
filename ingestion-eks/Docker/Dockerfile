FROM 387102133919.dkr.ecr.us-east-1.amazonaws.com/python-v3.7-slim:latest

ARG USERNAME
ARG PASSWORD
WORKDIR /var/lib/integration-api

# COPY ./pkg /var/lib/pkg
COPY ./ss-integration-api /var/lib/integration-api
COPY ./Docker/git_credentials.exp /var/lib/integration-api
COPY ./Docker/git_credentials.sh /var/lib/integration-api
COPY ./Docker/newrelic.ini /var/lib/integration-api

RUN chmod -R 755 /var/lib/integration-api

RUN cat requirements.txt | grep -v "-e git+git@bitbucket.org:experience-com/buyersroad-sdk-python.git#egg=buyersroad" | tee requirements.txt
RUN pip install -r requirements.txt

RUN chmod 755 git_credentials.sh git_credentials.exp
RUN bash git_credentials.sh 
RUN pip install -r ./src/buyersroad/requirements.txt
RUN pip install redis==4.0.2

CMD ["python", "wsgi.py"]
