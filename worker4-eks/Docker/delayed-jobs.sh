#! /bin/bash
apt -y install vim
mv .aws ~/
mv .ssh ~/

# cd config/
# cat /var/lib/v2-api/rails-common-credentials.txt | EDITOR='tee -a' rails credentials:edit
mkdir -p config/credentials || echo "Folder already exist"
cd config/credentials
cat /var/lib/v2-api/worker.env | RAILS_ENV=${RAILS_ENV} EDITOR='tee -a' rails credentials:edit --environment ${RAILS_ENV} >> /dev/null 2>&1
cd /var/lib/v2-api

