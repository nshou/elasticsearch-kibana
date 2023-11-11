FROM ubuntu:latest

LABEL maintainer "nshou <nshou@coronocoya.net>"

# Elasticsearch / Kibana Stack version.
ENV EK_VERSION=8.10.4

# Enable Security for Elasticsearch / Kibana
ENV SSL_MODE=true

RUN apt-get update -qq >/dev/null 2>&1 \
    && apt-get install wget unzip curl sudo -qqy >/dev/null 2>&1 \
    && useradd -m -s /bin/bash elastic \
    && echo elastic ALL=NOPASSWD: ALL >/etc/sudoers.d/elastic \
    && chmod 440 /etc/sudoers.d/elastic

USER elastic

WORKDIR /home/elastic

RUN wget -q -O - https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${EK_VERSION}-linux-x86_64.tar.gz | tar -zx \
    && mkdir -p elasticsearch-${EK_VERSION}/data

RUN wget -q -O - https://artifacts.elastic.co/downloads/kibana/kibana-${EK_VERSION}-linux-x86_64.tar.gz | tar -zx

COPY entrypoint.sh .

ENTRYPOINT ["bash", "entrypoint.sh"]

EXPOSE 9200 5601