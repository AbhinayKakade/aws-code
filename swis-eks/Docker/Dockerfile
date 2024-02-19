# Used for m2-swis only
FROM us-east4-docker.pkg.dev/experiencedotcom-devops/experiencedotcom-dev/node-v17.8-alpine:v2

WORKDIR /var/lib/swis-api

COPY ./ /var/lib/swis-api
COPY ./Docker/swis.env /var/lib/swis-api

# nginx configuration
RUN mkdir /root/.ssh /root/.aws /var/lib/swis-api/sitemap/
ADD --chown=root ./Docker/nginx.conf /etc/nginx/nginx.conf
COPY --chown=root ./Docker/.aws /root/.aws/

# for enabling 15 mins cron
ADD --chown=root ./Docker/sitemapscript /etc/periodic/15min/sitemapscript
RUN chmod 755 /etc/periodic/15min/sitemapscript

# RUN chmod -R 755 /var/lib/swis-api
RUN chmod 644 /var/lib/swis-api/swis.env
RUN ln -sf /dev/stderr /var/log/nginx/error.log
RUN yarn cache clean && yarn install --production=true
RUN source swis.env && yarn build 

RUN cat /etc/nginx/nginx.conf
# need to check this line
#EXPOSE 8080

CMD nginx && crond && yarn start
