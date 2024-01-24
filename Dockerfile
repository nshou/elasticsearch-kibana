FROM ubuntu:latest

LABEL maintainer "nshou <nshou@coronocoya.net>"

# Elasticsearch / Kibana Settings
ENV ELASTIC_VERSION=8.10.4
ENV KIBANA_VERSION=8.10.4
ENV SSL_MODE=true
ENV RANDOM_PASSWORD_ON_BOOT=true
ENV ELASTIC_PASSWORD_RESET=mysupersecretpassword


RUN apt-get update -qq >/dev/null 2>&1 \
    && apt-get install wget unzip curl sudo -qqy >/dev/null 2>&1 \
    && useradd -m -s /bin/bash elastic \
    && echo elastic ALL=NOPASSWD: ALL >/etc/sudoers.d/elastic \
    && chmod 440 /etc/sudoers.d/elastic

USER elastic

WORKDIR /home/elastic

# Create working data directories
RUN mkdir -p /home/elastic/elasticsearch
RUN mkdir -p /home/elastic/kibana

# Disable Legacy OpenSSL Providers
RUN echo "--openssl-legacy-provider"

# Download assets from `elastic.co`
RUN wget --show-progress -q -O - https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTIC_VERSION}-linux-x86_64.tar.gz | tar -zx -C /home/elastic/elasticsearch --strip-components=1
RUN wget --show-progress -q -O - https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz | tar -zx -C /home/elastic/kibana --strip-components=1

COPY entrypoint.sh .

ENTRYPOINT ["bash", "entrypoint.sh"]

EXPOSE 9200 5601