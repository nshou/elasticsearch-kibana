FROM ubuntu:latest

MAINTAINER nshou <nshou@coronocoya.net>

RUN apt-get update -q

RUN apt-get install -yq wget default-jre-headless

ENV ES_VERSION 1.7.2

RUN cd /tmp && \
    wget -nv https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-${ES_VERSION}.tar.gz && \
    tar zxf elasticsearch-${ES_VERSION}.tar.gz && \
    rm -f elasticsearch-${ES_VERSION}.tar.gz && \
    mv /tmp/elasticsearch-${ES_VERSION} /elasticsearch

ENV KIBANA_VERSION 4.1.2

RUN cd /tmp && \
    wget -nv https://download.elastic.co/kibana/kibana/kibana-${KIBANA_VERSION}-linux-x64.tar.gz && \
    tar zxf kibana-${KIBANA_VERSION}-linux-x64.tar.gz && \
    rm -f kibana-${KIBANA_VERSION}-linux-x64.tar.gz && \
    mv /tmp/kibana-${KIBANA_VERSION}-linux-x64 /kibana

CMD /elasticsearch/bin/elasticsearch -Des.logger.level=OFF & /kibana/bin/kibana -q

EXPOSE 9200 5601
