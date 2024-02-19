FROM node:17.8-alpine
RUN apk add --update --no-cache curl py-pip make g++ nginx
RUN apk update
RUN apk add aws-cli
WORKDIR /var/lib/swis-graphql
COPY ./ /var/lib/swis-graphql
COPY ./Docker/global-bundle.pem /var/lib/swis-graphql/global-bundle.pem
RUN npm install
CMD ["yarn", "start"]