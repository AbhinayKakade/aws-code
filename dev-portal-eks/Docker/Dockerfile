FROM ruby:2.7.1-buster
ARG RAILS_ENV
ARG RAILS_MIGRATIONS
ARG RAILS_SEED
ARG SECRET_KEY_BASE


RUN apt-get update 
RUN apt update && curl -sL https://deb.nodesource.com/setup_12.x | bash  && apt install -y nodejs
RUN apt-get install -y apt-utils
RUN apt-get install -y --no-install-recommends bison dpkg-dev libgdbm-dev
RUN apt-mark hold ruby
RUN apt-get upgrade -y
RUN apt-get install -y --only-upgrade mariadb-*
ENV RAILS_ENV=${RAILS_ENV}
ENV RAILS_MIGRATIONS=${RAILS_MIGRATIONS}
ENV RAILS_SEED=${RAILS_SEED}
ENV RAILS_LOG_TO_STDOUT=true
WORKDIR /var/lib/dev_portal/
COPY ./dev_portal /var/lib/dev_portal

RUN bundle update 
RUN bundle install
RUN gem install execjs
RUN npm install --global yarn

COPY ./Docker/dev-portal.env /var/lib/dev_portal
COPY ./Docker/dev-portal.sh /var/lib/dev_portal

RUN chmod +x dev-portal.sh
RUN bash dev-portal.sh

RUN RAILS_ENV=${RAILS_ENV} rails assets:precompile --trace

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]
