#! /bin/bash

mkdir -p config/credentials
cd config/credentials
cat /var/lib/dev_portal/dev-portal.env | RAILS_ENV=${RAILS_ENV} EDITOR='tee -a' rails credentials:edit --environment ${RAILS_ENV} >> /dev/null 2>&1
cd /var/lib/dev_portal

if [[ "$RAILS_MIGRATIONS" == "yes" ]]; then
RAILS_ENV=${RAILS_ENV} rails db:migrate 
echo "Migrations completed"
fi
if [[ "$RAILS_SEED" == "yes" ]]; then
RAILS_ENV=${RAILS_ENV} rails db:seed
echo "Seed completed"
fi
