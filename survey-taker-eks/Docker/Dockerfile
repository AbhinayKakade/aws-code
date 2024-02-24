FROM us-east4-docker.pkg.dev/experiencedotcom-devops/experiencedotcom-dev/node-18.17.1-alpine3.18:latest
WORKDIR /var/lib/survey-client

COPY . /var/lib/survey-client
COPY ./Docker/mongodb.pem /var/lib/survey-client/ssl/mongodb.pem
COPY ./Docker/rootCA.pem /var/lib/survey-client/ssl/rootCA.pem
COPY ./Docker/survey-taker.env /var/lib/survey-client

RUN chmod -R 755 /var/lib/survey-client
RUN chmod 644 /var/lib/survey-client/ssl/* /var/lib/survey-client/survey-taker.env
RUN yarn install --ignore-engines
RUN source survey-taker.env && yarn build

CMD ["yarn", "start"]
