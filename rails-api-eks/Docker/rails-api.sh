#! /bin/bash

mkdir -p config/credentials || echo "Folder already exist"
cat /dev/null | RAILS_ENV=development EDITOR="tee -a" /usr/local/bundle/bin/rails credentials:edit

cd /var/lib/v2-api/config/credentials
cat /var/lib/v2-api/rails-api.env | RAILS_ENV=${RAILS_ENV} EDITOR='tee -a' /usr/local/bundle/bin/rails credentials:edit --environment ${RAILS_ENV} >> /dev/null 2>&1
cd /var/lib/v2-api

if [[ "$RAILS_MIGRATIONS" == "yes" ]]; then
RAILS_ENV=${RAILS_ENV} rails db:migrate 
echo "Migrations completed"
fi
if [[ "$RAILS_SEED" == "yes" ]]; then
RAILS_ENV=${RAILS_ENV} rails db:seed
echo "Seed completed"
fi
