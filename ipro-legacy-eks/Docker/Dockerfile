FROM 387102133919.dkr.ecr.us-east-1.amazonaws.com/python-v3.7-slim:latest

ARG USERNAME
ARG PASSWORD
WORKDIR /var/lib/ipro-api

COPY ./api /var/lib/ipro-api
COPY ./Docker/newrelic.ini /var/lib/ipro-api
COPY ./Docker/git_credentials.exp /var/lib/ipro-api
COPY ./Docker/git_credentials.sh /var/lib/ipro-api

RUN chmod -R 755 /var/lib/ipro-api && chmod 644 /var/lib/ipro-api/newrelic.ini

RUN cat requirements.txt | grep -v "-e git+git@bitbucket.org:experience-com/buyersroad-sdk-python.git#egg=buyersroad" | tee requirements.txt

RUN pip install -r requirements.txt
RUN pip install Jinja2==3.0.3
RUN chmod 755 git_credentials.sh git_credentials.exp
RUN bash git_credentials.sh 
RUN pip install -r ./src/buyersroad/requirements.txt

CMD ["python", "legacy_wsgi.py"]
