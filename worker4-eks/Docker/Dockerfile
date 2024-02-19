FROM ruby:2.7.1-buster
ARG RAILS_ENV
ARG SECRET_KEY_BASE

RUN apt-get update && apt-get install -y daemonize
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf \
        awscliv2.zip
ENV RAILS_ENV=${RAILS_ENV}
ENV RAILS_LOG_TO_STDOUT=true
RUN mkdir ~/.ssh
WORKDIR /var/lib/v2-api
COPY ./v2-api /var/lib/v2-api
# RUN chmod -R 755 /var/lib/v2-api

RUN bundle update
RUN bundle install

COPY ./Docker/worker.env /var/lib/v2-api
COPY ./Docker/delayed-jobs.sh /var/lib/v2-api
COPY ./Docker/rds-combined-ca-bundle.pem /var/lib/v2-api/ssl/
COPY ./Docker/rootCA.pem /var/lib/v2-api/ssl/
COPY ./Docker/mongodb.pem /var/lib/v2-api/ssl/
COPY ./Docker/.aws /root/.aws
# COPY ./Docker/id_rsa /var/lib/v2-api/.ssh/
COPY ./Docker/prd1-surveysdb-mongodb.pem /var/lib/v2-api/ssl/
COPY ./Docker/prd1-surveysdb-rootCA.pem /var/lib/v2-api/ssl/
COPY ./Docker/prd1-socialmonitordb-mongodb.pem /var/lib/v2-api/ssl/
COPY ./Docker/prd1-socialmonitordb-rootCA.pem /var/lib/v2-api/ssl/
RUN chmod 755 delayed-jobs.sh ssl /root/.aws && chmod 644 ssl/* worker.env /root/.aws/config /root/.aws/credentials
RUN bash delayed-jobs.sh

#CMD bundle exec sidekiq -e devtest && RAILS_ENV=devtest bin/delayed_job run 
