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

# Flag to stop our loop once Elastic starts and the password is reset
password_reset_elastic=false

# Check if certificates have already been generated
if [[ ! -f /home/elastic/cert_bundle.zip ]]; then

  # ----------------------------
  # CERTIFICATE GENERATION
  # ----------------------------
  
  # Generate CA HTTP Certs
  elasticsearch/bin/elasticsearch-certutil ca --silent --pem --out /home/elastic/ca_bundle.zip
  unzip -qq /home/elastic/ca_bundle.zip -d /home/elastic/elasticsearch/config/certs/

  # Elastic/Kibana HTTPS SSL Certificates
  elasticsearch/bin/elasticsearch-certutil cert \
    --silent \
    --pem \
    --out /home/elastic/cert_bundle.zip \
    --ca-cert /home/elastic/elasticsearch/config/certs/ca/ca.crt \
    --ca-key /home/elastic/elasticsearch/config/certs/ca/ca.key \
    --dns localhost \
    --dns ${HOSTNAME} \
    --ip 127.0.0.1;

  # Kibana SSL CSR Self-Signer
  elasticsearch/bin/elasticsearch-certutil csr \
    --silent \
    -dns ${HOSTNAME} \
    -name ${HOSTNAME} \
    --out /home/elastic/csr_bundle.zip;

  # Extract all certificates
  unzip -qq /home/elastic/cert_bundle.zip -d /home/elastic/elasticsearch/config/certs/
  unzip -qq /home/elastic/cert_bundle.zip -d /home/elastic/kibana/
  unzip -qq /home/elastic/csr_bundle.zip  -d /home/elastic/kibana/

  # ----------------------------
  # AUTHENTICATION SETUP
  # ----------------------------

  # Set the kibana system user password to the `.env` file
  PWK=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16 ;)
  KIBANA_PASSWORD="${KIBANA_PASSWORD:-$PWK}"
  echo "KIBANA_PASSWORD=$KIBANA_PASSWORD" >> /home/elastic/.env
  export KIBANA_PASSWORD

  # Generate new token
  KIBANA_SERVICE_TOKEN=$(elasticsearch/bin/elasticsearch-service-tokens create elastic/kibana default | cut -d '=' -f2 | tr -d ' ')

  # ----------------------------
fi

  echo "+---------------------------------------------------+"
  echo "|      Elastic/Kibana stack is now [STARTING]       |"
  echo "|---------------------------------------------------|"
printf "|     SSL ENABLED: %-32s |\n" "'${SSL_MODE}'"
printf "| RANDOM PASSWORD: %-32s |\n" "'${RANDOM_PASSWORD_ON_BOOT}'"
  echo "+---------------------------------------------------+"


if [[ "${SSL_MODE}" == "true" ]]; then
  # ----------------------------
  # Start Elastic / Kibana [SSL]
  # ----------------------------
  
  elasticsearch/bin/elasticsearch \
    --quiet \
    -E http.host=0.0.0.0 \
    -E xpack.security.enabled=true \
    -E xpack.monitoring.collection.enabled=true \
    -E xpack.security.http.ssl.enabled=true \
    -E xpack.security.http.ssl.certificate=/home/elastic/elasticsearch/config/certs/instance/instance.crt \
    -E xpack.security.http.ssl.key=/home/elastic/elasticsearch/config/certs/instance/instance.key \
    -E xpack.security.http.ssl.certificate_authorities=/home/elastic/elasticsearch/config/certs/ca/ca.crt \
    -E xpack.security.transport.ssl.enabled=true \
    -E xpack.security.transport.ssl.verification_mode=certificate \
    -E xpack.security.transport.ssl.certificate=/home/elastic/elasticsearch/config/certs/instance/instance.crt \
    -E xpack.security.transport.ssl.key=/home/elastic/elasticsearch/config/certs/instance/instance.key \
    -E xpack.security.transport.ssl.certificate_authorities=/home/elastic/elasticsearch/config/certs/ca/ca.crt \
    -E xpack.license.self_generated.type=basic & 

  while [ "$password_reset_elastic" = false ]; do
    if check_elasticsearch_running; then
      sleep 5
      if [ "$RANDOM_PASSWORD_ON_BOOT" = true ]; then
        ELASTIC_PASSWORD_RESET=$(
          elasticsearch/bin/elasticsearch-reset-password \
          --url "https://localhost:9200" \
          -u elastic \
          -b \
          -E xpack.security.http.ssl.enabled=true \
          -E xpack.security.http.ssl.certificate=/home/elastic/elasticsearch/config/certs/instance/instance.crt \
          -E xpack.security.http.ssl.key=/home/elastic/elasticsearch/config/certs/instance/instance.key \
          -E xpack.security.http.ssl.certificate_authorities=/home/elastic/elasticsearch/config/certs/ca/ca.crt \
          | awk '/New value:/ {print $3}'
        );
      else
        printf "$ELASTIC_PASSWORD_RESET\n$ELASTIC_PASSWORD_RESET" | elasticsearch/bin/elasticsearch-reset-password \
        --url "https://localhost:9200" \
        -u elastic \
        -i \
        -b \
        -E xpack.security.http.ssl.enabled=true \
        -E xpack.security.http.ssl.certificate=/home/elastic/elasticsearch/config/certs/instance/instance.crt \
        -E xpack.security.http.ssl.key=/home/elastic/elasticsearch/config/certs/instance/instance.key \
        -E xpack.security.http.ssl.certificate_authorities=/home/elastic/elasticsearch/config/certs/ca/ca.crt >/dev/null 2>&1
      fi
      if [ $? -eq 0 ]; then

        # Output password details to console post-start
        echo "+------------------------------------------------------+"
        echo "| Your stack is now [RUNNING] you may access it below. |"
        echo "|------------------------------------------------------|"
        echo "|  SSL Enabled?: 'true'                                |"
        echo "| Elasticsearch: https://localhost:9200/               |"
        echo "|        Kibana: https://localhost:5601/               |"
        echo "|          User: 'elastic'                             |";
        echo "|      Password: '$ELASTIC_PASSWORD_RESET'";
        echo "+------------------------------------------------------+"
        password_reset_elastic=true
      fi
    else
      sleep 1
    fi
  done &

  kibana/bin/kibana \
    -Q \
    --allow-root \
    --host 0.0.0.0 \
    --server.ssl.enabled=true \
    --server.publicBaseUrl https://localhost.local \
    --server.ssl.certificate=/home/elastic/kibana/instance/instance.crt \
    --server.ssl.key=/home/elastic/kibana/instance/instance.key \
    --elasticsearch.hosts https://localhost:9200 \
    --elasticsearch.ssl.certificateAuthorities=/home/elastic/elasticsearch/config/certs/ca/ca.crt \
    --elasticsearch.ssl.certificate=/home/elastic/elasticsearch/config/certs/instance/instance.crt \
    --elasticsearch.ssl.key=/home/elastic/elasticsearch/config/certs/instance/instance.key \
    --elasticsearch.ssl.verificationMode=certificate \
    --elasticsearch.serviceAccountToken=${KIBANA_SERVICE_TOKEN}

elif [[ "${SSL_MODE}" == "false" ]]; then
  # ----------------------------
  # Start Elastic / Kibana [NO-SSL]
  # ----------------------------
  echo "+------------------------------------------------------+"
  echo "| Your stack is now [RUNNING] you may access it below. |"
  echo "|------------------------------------------------------|"
  echo "|  SSL Enabled?: 'false'                               |"
  echo "| Elasticsearch: http://localhost:9200/                |"
  echo "|        Kibana: http://localhost:5601/                |"
  echo "|          User: 'elastic'                             |"
  echo "|      Password: '$ELASTIC_PASSWORD_RESET'"
  echo "+------------------------------------------------------+"

  elasticsearch/bin/elasticsearch \
    -E http.host=0.0.0.0 \
    -E xpack.security.enabled=false \
    --quiet &
  kibana/bin/kibana \
    --allow-root \
    --host 0.0.0.0 \
    -Q
fi
