#! /bin/bash
mv .aws ~/
mv .ssh ~/

# cd config/
# cat /var/lib/v2-api/rails-common-credentials.txt | EDITOR='tee -a' rails credentials:edit
mkdir -p /var/lib/v2-api/config/credentials || echo "Folder already exist"
cat /dev/null | RAILS_ENV=development EDITOR="tee -a" /usr/local/bundle/bin/rails credentials:edit
cd /var/lib/v2-api/config/credentials
cat /var/lib/v2-api/worker.env | RAILS_ENV=${RAILS_ENV} EDITOR='tee -a' /usr/local/bundle/bin/rails credentials:edit --environment ${RAILS_ENV} >> /dev/null 2>&1
cd /var/lib/v2-api
