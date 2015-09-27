## Elasticsearch and Kibana in one container

Simple and lightweight docker image to run Elasticsearch server and Kibana front-end.

### Usage

    docker run -d -p 9200:9200 -p 5601:5601 nshou/elasticsearch-kibana

Now you can connect to Elasticsearch by `localhost:9200` and its Kibana front-end by `localhost:5601`.

### Tags

* latest: Elasticsearch-1.7.2 Kibana-4.1.2
* kibana3: Elasticsearch-1.7.2 Kibana-3.1.2
