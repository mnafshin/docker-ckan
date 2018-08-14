#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

CONFIG="${CKAN_CONFIG}/production.ini"

abort () {
  echo "$@" >&2
  exit 1
}

set_environment () {
  #export CKAN_SITE_ID=${CKAN_SITE_ID}
  export CKAN_SITE_URL=${CKAN_SITE_URL}
  export CKAN_SQLALCHEMY_URL=${CKAN_SQLALCHEMY_URL}
  export CKAN_SOLR_URL=${CKAN_SOLR_URL}
  export CKAN_REDIS_URL=${CKAN_REDIS_URL}
  export CKAN_STORAGE_PATH=/var/lib/ckan
  #export CKAN_DATAPUSHER_URL=${CKAN_DATAPUSHER_URL}
  #export CKAN_DATASTORE_WRITE_URL=${CKAN_DATASTORE_WRITE_URL}
  #export CKAN_DATASTORE_READ_URL=${CKAN_DATASTORE_READ_URL}
  #export CKAN_SMTP_SERVER=${CKAN_SMTP_SERVER}
  #export CKAN_SMTP_STARTTLS=${CKAN_SMTP_STARTTLS}
  #export CKAN_SMTP_USER=${CKAN_SMTP_USER}
  #export CKAN_SMTP_PASSWORD=${CKAN_SMTP_PASSWORD}
  #export CKAN_SMTP_MAIL_FROM=${CKAN_SMTP_MAIL_FROM}
  #export CKAN_MAX_UPLOAD_SIZE_MB=${CKAN_MAX_UPLOAD_SIZE_MB}
}

write_config () {
  ckan-paster make-config --no-interactive ckan "$CONFIG"
}

# If we don't already have a config file, bootstrap
if [ ! -e "$CONFIG" ]; then
  write_config
fi

sed -i "/ckan.site_url/c ckan.site_url=$CKAN_SITE_URL" $CONFIG
sed -i "/sqlalchemy.url/c sqlalchemy.url=$CKAN_SQLALCHEMY_URL" $CONFIG
sed -i "/solr_url/c solr_url=$CKAN_SOLR_URL" $CONFIG
sed -i "/ckan.redis.url/c ckan.redis.url=$CKAN_REDIS_URL" $CONFIG

if [ ! -z "$CKAN_RECAPTCHA_PUBLICKEY" ]; then 
  if [ ! -z "$CKAN_RECAPTCHA_PRIVATEKEY" ]; then 
    sed -i "/ckan.recaptcha.publickey/c ckan.recaptcha.publickey=$CKAN_RECAPTCHA_PUBLICKEY" $CONFIG
    sed -i "/ckan.recaptcha.privatekey/c ckan.recaptcha.privatekey=$CKAN_RECAPTCHA_PRIVATEKEY" $CONFIG
  fi
else 
  echo "Recaptcha private/public keys are not set. Ignoring."
fi

export ORIGINAL_CKAN_PLUGINS="stats text_view image_view recline_view"

sed -i "/ckan.plugins/c ckan.plugins=$ORIGINAL_CKAN_PLUGINS $ADDITIONAL_CKAN_PLUGINS" $CONFIG

# add harvest configuration
sed -i "/\[app:main\]/a ckan.harvest.mq.type = redis" $CONFIG
sed -i "/\[app:main\]/a ckan.harvest.mq.hostname = $REDIS_HOSTNAME" $CONFIG

#sed -i "/ckan.datapusher.url/c ckan.datapusher.url=$CKAN_DATAPUSHER_URL" $CONFIG
#sed -i "/ckan.datastore.write_url/c ckan.datastore.write_url=$CKAN_DATASTORE_WRITE_URL" $CONFIG
#sed -i "/ckan.datastore.read_url/c ckan.datastore.read_url=$CKAN_DATASTORE_READ_URL" $CONFIG

set_environment
ckan-paster --plugin=ckan db init -c "${CKAN_CONFIG}/production.ini"
ckan-paster --plugin=ckanext-harvest harvester initdb -c "${CKAN_CONFIG}/production.ini"
exec "$@"
