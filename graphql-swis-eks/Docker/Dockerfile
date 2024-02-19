FROM us-east4-docker.pkg.dev/experiencedotcom-devops/experiencedotcom-dev/node-v17.8-alpine:v2
WORKDIR /var/lib/swis-graphql

COPY ./ /var/lib/swis-graphql
#COPY ./Docker/swis.env /var/lib/swis-graphql/.env

RUN npm install

CMD ["yarn", "start"]
