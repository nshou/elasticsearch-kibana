#!/bin/bash

# Set BASH to exit upon error
set -e

# Function to check if Elasticsearch is running
check_elasticsearch_running() {
  if curl -s --insecure "https://localhost:9200" -o /dev/null; then
    return 0  # Elasticsearch is running
  else
    return 1  # Elasticsearch is not running
  fi
}

password_reset_elastic=false

# Check if certificates have already been generated
if [[ ! -f /home/elastic/cert_bundle.zip ]]; then

  # ----------------------------
  # CERTIFICATE GENERATION
  # ----------------------------
  
  # Generate CA HTTP Certs
  elasticsearch-${EK_VERSION}/bin/elasticsearch-certutil ca --silent --pem -out /home/elastic/ca_bundle.zip
  unzip -qq /home/elastic/ca_bundle.zip -d /home/elastic/elasticsearch-${EK_VERSION}/config/certs/ #unzips as 'ca/'

  # Generate SSL HTTP Certs
  elasticsearch-${EK_VERSION}/bin/elasticsearch-certutil cert \
    --silent \
    --pem \
    -out /home/elastic/cert_bundle.zip \
    --ca-cert /home/elastic/elasticsearch-${EK_VERSION}/config/certs/ca/ca.crt \
    --ca-key /home/elastic/elasticsearch-${EK_VERSION}/config/certs/ca/ca.key \
    --dns localhost \
    --dns ${HOSTNAME} \
    --ip 127.0.0.1;
  unzip -qq /home/elastic/cert_bundle.zip -d /home/elastic/elasticsearch-${EK_VERSION}/config/certs/ #unzips as 'instance/'


  # Kibana SSL HTTP CSR Generation
  elasticsearch-${EK_VERSION}/bin/elasticsearch-certutil csr \
    --silent \
    -dns ${HOSTNAME} \
    -name ${HOSTNAME} \
    -out /home/elastic/kibana_csr_bundle.zip;
  unzip -qq /home/elastic/kibana_csr_bundle.zip -d /home/elastic/kibana-${EK_VERSION}/ #unzips as '${HOSTNAME}/ca/'

  # Setup Kibana HTTP SSL Certs
  elasticsearch-${EK_VERSION}/bin/elasticsearch-certutil cert \
    --silent \
    --pem \
    -out /home/elastic/kibana_cert_bundle.zip \
    --dns localhost \
    --dns ${HOSTNAME} \
    --ca-cert /home/elastic/elasticsearch-${EK_VERSION}/config/certs/ca/ca.crt \
    --ca-key /home/elastic/elasticsearch-${EK_VERSION}/config/certs/ca/ca.key \
    --ip 127.0.0.1;
  unzip -qq /home/elastic/kibana_cert_bundle.zip -d /home/elastic/kibana-${EK_VERSION}/ #unzips as 'ca/'

  # ----------------------------

  # ----------------------------
  # AUTHENTICATION SETUP
  # ----------------------------

  # Set the kibana system user password to the `.env` file
  PWK=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16 ;)
  KIBANA_PASSWORD="${KIBANA_PASSWORD:-$PWK}"
  echo "KIBANA_PASSWORD=$KIBANA_PASSWORD" >> /home/elastic/.env
  export KIBANA_PASSWORD

  # Generate new token
  KIBANA_SERVICE_TOKEN=$(elasticsearch-${EK_VERSION}/bin/elasticsearch-service-tokens create elastic/kibana default | cut -d '=' -f2 | tr -d ' ')

  # ----------------------------
fi

echo "----------------------------------------------------------------------------------"
echo "------------------------- STARTING ELASTIC/KIBANA --------------------------------"
echo "----------------------------------------------------------------------------------"

# Start Elasticsearch in SSL mode
elasticsearch-${EK_VERSION}/bin/elasticsearch \
  --quiet \
  -E http.host=0.0.0.0 \
  -E xpack.security.enabled=true \
  -E xpack.security.http.ssl.enabled=true \
  -E xpack.security.http.ssl.certificate=/home/elastic/elasticsearch-${EK_VERSION}/config/certs/instance/instance.crt \
  -E xpack.security.http.ssl.key=/home/elastic/elasticsearch-${EK_VERSION}/config/certs/instance/instance.key \
  -E xpack.security.http.ssl.certificate_authorities=/home/elastic/elasticsearch-${EK_VERSION}/config/certs/ca/ca.crt \
  -E xpack.security.transport.ssl.enabled=true \
  -E xpack.security.transport.ssl.verification_mode=certificate \
  -E xpack.security.transport.ssl.certificate=/home/elastic/elasticsearch-${EK_VERSION}/config/certs/instance/instance.crt \
  -E xpack.security.transport.ssl.key=/home/elastic/elasticsearch-${EK_VERSION}/config/certs/instance/instance.key \
  -E xpack.security.transport.ssl.certificate_authorities=/home/elastic/elasticsearch-${EK_VERSION}/config/certs/instance/instance.crt \
  -E xpack.license.self_generated.type=basic & 

while [ "$password_reset_elastic" = false ]; do
  if check_elasticsearch_running; then
    sleep 5;
    ELASTIC_RANDOM_PASSWORD=$(
      elasticsearch-${EK_VERSION}/bin/elasticsearch-reset-password \
      -v \
      --url "https://localhost:9200" \
      -u elastic \
      -b \
      -E xpack.security.http.ssl.enabled=true \
      -E xpack.security.http.ssl.certificate=/home/elastic/elasticsearch-${EK_VERSION}/config/certs/instance/instance.crt \
      -E xpack.security.http.ssl.key=/home/elastic/elasticsearch-${EK_VERSION}/config/certs/instance/instance.key \
      -E xpack.security.http.ssl.certificate_authorities=/home/elastic/elasticsearch-${EK_VERSION}/config/certs/ca/ca.crt
    );
    exit_code=$?
    if [ $exit_code -eq 0 ]; then

      # Generate new password and grab the value from 'awk'
      ELASTIC_NEW_PASSWORD=$(echo "$ELASTIC_RANDOM_PASSWORD" | awk '/New value:/ {print $3}');    

      clear
      echo "----------------------------------------------------------------------------------"
      echo "------------------- RESETTING 'elastic' USER PASSWORD ----------------------------"
      echo "----------------------------------------------------------------------------------"
      echo "Password reset successful. '$ELASTIC_NEW_PASSWORD'"
      echo "----------------------------------------------------------------------------------"

      # Flip global check value to stop this loop
      password_reset_elastic=true  
    fi
  else
    sleep 1
  fi
done &

# Start Kibana in SSL mode
kibana-${EK_VERSION}/bin/kibana \
  -Q \
  --allow-root \
  --host 0.0.0.0 \
  --server.ssl.enabled=true \
  --server.ssl.certificate=/home/elastic/kibana-${EK_VERSION}/instance/instance.crt \
  --server.ssl.key=/home/elastic/kibana-${EK_VERSION}/instance/instance.key \
  --elasticsearch.hosts https://localhost:9200 \
  --elasticsearch.ssl.certificateAuthorities=/home/elastic/elasticsearch-${EK_VERSION}/config/certs/ca/ca.crt \
  --elasticsearch.ssl.certificate=/home/elastic/elasticsearch-${EK_VERSION}/config/certs/instance/instance.crt \
  --elasticsearch.ssl.key=/home/elastic/elasticsearch-${EK_VERSION}/config/certs/instance/instance.key \
  --elasticsearch.ssl.verificationMode=certificate \
  --elasticsearch.serviceAccountToken=${KIBANA_SERVICE_TOKEN}