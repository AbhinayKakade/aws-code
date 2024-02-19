FROM 387102133919.dkr.ecr.us-east-1.amazonaws.com/rails-2.7.1-nginx-passenger:latest
ARG RAILS_ENV
ARG RAILS_MIGRATIONS
ARG RAILS_SEED
ARG SECRET_KEY_BASE

ENV RAILS_ENV=${RAILS_ENV}
ENV RAILS_MIGRATIONS=${RAILS_MIGRATIONS}
ENV RAILS_SEED=${RAILS_SEED}
ENV RAILS_LOG_TO_STDOUT=true

# using ubuntu for running the app
RUN apt-get update
RUN apt-get install libnginx-mod-http-headers-more-filter imagemagick -y
RUN groupadd ubuntu && useradd -rm -d /home/ubuntu -s /bin/bash -g ubuntu -G sudo -u 1001 ubuntu
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER ubuntu

ADD --chown=ubuntu ./Docker/mod-http-passenger.conf /etc/nginx/conf.d/mod-http-passenger.conf
ADD --chown=ubuntu ./Docker/nginx.conf /etc/nginx/nginx.conf
RUN sudo rm -rf /var/log/nginx/ && sudo mkdir /var/log/nginx/ && sudo chown www-data:adm /var/log/nginx/

RUN mkdir /home/ubuntu/.ssh /home/ubuntu/.aws
WORKDIR /var/lib/v2-api
COPY --chown=ubuntu ./v2-api /var/lib/v2-api

# to fix write permission inside /var/lib/v2-api
RUN sudo chown ubuntu:ubuntu /var/lib/v2-api

RUN bundle update

COPY --chown=ubuntu ./Docker/rails-api.env /var/lib/v2-api
COPY --chown=ubuntu ./Docker/rails-api.sh /var/lib/v2-api
COPY --chown=ubuntu ./Docker/rds-combined-ca-bundle.pem /var/lib/v2-api/ssl/
COPY --chown=ubuntu ./Docker/rootCA.pem /var/lib/v2-api/ssl/
COPY --chown=ubuntu ./Docker/mongodb.pem /var/lib/v2-api/ssl/
COPY --chown=ubuntu ./Docker/prd1-surveysdb-mongodb.pem /var/lib/v2-api/ssl/
COPY --chown=ubuntu ./Docker/prd1-surveysdb-rootCA.pem /var/lib/v2-api/ssl/
COPY --chown=ubuntu ./Docker/prd1-socialmonitordb-mongodb.pem /var/lib/v2-api/ssl/
COPY --chown=ubuntu ./Docker/prd1-socialmonitordb-rootCA.pem /var/lib/v2-api/ssl/
COPY --chown=ubuntu ./Docker/.aws /var/lib/v2-api/.aws
COPY --chown=ubuntu ./Docker/.aws /home/ubuntu/.aws/

# no need this file id_rsa file in production. So skipping this step
# COPY --chown=ubuntu ./Docker/id_rsa /var/lib/v2-api/.ssh/
# COPY --chown=ubuntu ./Docker/id_rsa /home/ubuntu/.ssh/

RUN chmod +x rails-api.sh
RUN bash rails-api.sh

# running install
RUN sudo bundle install
EXPOSE 3000

CMD sudo /etc/init.d/nginx restart && tail -f /var/log/nginx/error.log