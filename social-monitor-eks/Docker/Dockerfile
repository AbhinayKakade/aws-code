#FROM 387102133919.dkr.ecr.us-east-1.amazonaws.com/node-v19.6.1:latest

FROM 387102133919.dkr.ecr.us-east-1.amazonaws.com/node-v20.3.1:latest

WORKDIR /var/lib/social-monitor-api

COPY ./social-monitor /var/lib/social-monitor-api/
COPY ./Docker/mongodb.pem /var/lib/social-monitor/ssl/mongodb.pem
COPY ./Docker/social-monitor.env /var/lib/social-monitor-api/
COPY ./Docker/rootCA.pem /var/lib/social-monitor/ssl/rootCA.pem

RUN chmod -R 755 /var/lib/social-monitor-api
RUN chmod 644 /var/lib/social-monitor/ssl/* /var/lib/social-monitor-api/social-monitor.env
RUN npm install -g prisma
RUN source social-monitor.env && npx prisma db pull
RUN npx prisma generate
RUN source social-monitor.env && yarn

CMD ["yarn", "start"]
