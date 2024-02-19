#! /bin/bash
mv .aws ~/
mv .ssh ~/

# cd config/
# cat /var/lib/v2-api/rails-common-credentials.txt | EDITOR='tee -a' rails credentials:edit
mkdir -p config/credentials || echo "Folder already exist"
cd config/credentials
cat /var/lib/v2-api/rails-api.env | RAILS_ENV=${RAILS_ENV} EDITOR='tee -a' rails credentials:edit --environment ${RAILS_ENV}
cd /var/lib/v2-api

if [[ "$RAILS_MIGRATIONS" == "yes" ]]; then
RAILS_ENV=${RAILS_ENV} rails db:migrate 
echo "Migrations completed"
fi
if [[ "$RAILS_SEED" == "yes" ]]; then
RAILS_ENV=${RAILS_ENV} rails db:seed
echo "Seed completed"
fi