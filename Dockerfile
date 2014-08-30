FROM ubuntu:latest

MAINTAINER nshou <nshou@coronocoya.net>

RUN apt-get update -q

RUN apt-get install -yq wget default-jre-headless mini-httpd

RUN cd /tmp && \
    wget -nv https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.2.tar.gz && \
    tar zxf elasticsearch-1.3.2.tar.gz && \
    rm -f elasticsearch-1.3.2.tar.gz && \
    mv /tmp/elasticsearch-1.3.2 /elasticsearch

RUN cd /tmp && \
    wget -nv https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz && \
    tar zxf kibana-3.1.0.tar.gz && \
    rm -f kibana-3.1.0.tar.gz && \
    mv /tmp/kibana-3.1.0 /kibana

CMD /elasticsearch/bin/elasticsearch -Des.logger.level=OFF & mini-httpd -d /kibana -h `hostname` -r -D

EXPOSE 80 9200
