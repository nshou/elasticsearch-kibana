## Elasticsearch and Kibana in one container

Simple and lightweight docker image to run Elasticsearch and Kibana.

### Usage

    docker run -d -p 9200:9200 -p 5601:5601 nshou/elasticsearch-kibana

Then you can connect to Elasticsearch by `localhost:9200` and its Kibana front-end by `localhost:5601`.

### Tags

* latest

    Elasticsearch-2.4.1 Kibana-4.6.2

* kibana3

    Elasticsearch-1.7.4 Kibana-3.1.3