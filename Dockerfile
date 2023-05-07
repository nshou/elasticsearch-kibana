FROM openjdk:11-jre-slim

LABEL maintainer "nshou <nshou@coronocoya.net>"

ENV EK_VERSION=7.17.9
ENV ES_JAVA_HOME=/usr/local/openjdk-11

RUN apt-get update -qq >/dev/null 2>&1 \
 && apt-get install wget sudo -qqy >/dev/null 2>&1 \
 && useradd -m -s /bin/bash elastic \
 && echo elastic ALL=NOPASSWD: ALL >/etc/sudoers.d/elastic \
 && chmod 440 /etc/sudoers.d/elastic

USER elastic

WORKDIR /home/elastic

RUN wget -q -O - https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${EK_VERSION}-no-jdk-linux-x86_64.tar.gz | tar -zx \
 && mkdir -p elasticsearch-${EK_VERSION}/data \
 && wget -q -O - https://artifacts.elastic.co/downloads/kibana/kibana-${EK_VERSION}-linux-x86_64.tar.gz | tar -zx

CMD elasticsearch-${EK_VERSION}/bin/elasticsearch -E http.host=0.0.0.0 --quiet & kibana-${EK_VERSION}-linux-x86_64/bin/kibana --allow-root --host 0.0.0.0 -Q

EXPOSE 9200 5601
