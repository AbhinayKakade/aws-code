FROM 387102133919.dkr.ecr.us-east-1.amazonaws.com/rails-2.7.1-nginx-passenger:ubuntu-jobs
ARG RAILS_ENV
ARG SECRET_KEY_BASE
RUN apt-get update

RUN groupadd ubuntu && useradd -rm -d /home/ubuntu -s /bin/bash -g ubuntu -G sudo -u 1001 ubuntu
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER ubuntu

RUN mkdir /home/ubuntu/.ssh /home/ubuntu/.aws

WORKDIR /var/lib/v2-api
COPY --chown=ubuntu ./v2-api /var/lib/v2-api

# to fix write permission inside /var/lib/v2-api
RUN sudo chown ubuntu:ubuntu /var/lib/v2-api

RUN bundle update

COPY --chown=ubuntu ./Docker/worker.env /var/lib/v2-api/
COPY --chown=ubuntu ./Docker/ubuntu-delayed-jobs.sh /var/lib/v2-api/
COPY --chown=ubuntu ./Docker/rds-combined-ca-bundle.pem /var/lib/v2-api/ssl/
COPY --chown=ubuntu ./Docker/rootCA.pem /var/lib/v2-api/ssl/
COPY --chown=ubuntu ./Docker/mongodb.pem /var/lib/v2-api/ssl/
COPY --chown=ubuntu ./Docker/.aws /var/lib/v2-api/.aws
COPY --chown=ubuntu ./Docker/.aws /home/ubuntu/.aws
# COPY ./Docker/id_rsa /var/lib/v2-api/.ssh/
COPY --chown=ubuntu ./Docker/prd1-surveysdb-mongodb.pem /var/lib/v2-api/ssl/
COPY --chown=ubuntu ./Docker/prd1-surveysdb-rootCA.pem /var/lib/v2-api/ssl/
COPY --chown=ubuntu ./Docker/prd1-socialmonitordb-mongodb.pem /var/lib/v2-api/ssl/
COPY --chown=ubuntu ./Docker/prd1-socialmonitordb-rootCA.pem /var/lib/v2-api/ssl/

RUN sudo bundle install

RUN chmod 755 ubuntu-delayed-jobs.sh ssl /home/ubuntu/.aws && chmod 644 ssl/* /home/ubuntu/.aws/config /home/ubuntu/.aws/credentials
RUN bash ubuntu-delayed-jobs.sh
