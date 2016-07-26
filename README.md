## Elasticsearch and Kibana in one container

Simple and lightweight docker image for previewing Elasticsearch and Kibana.

### Usage

    docker run -d -p 9200:9200 -p 5601:5601 nshou/elasticsearch-kibana

Then you can connect to Elasticsearch by `localhost:9200` and its Kibana front-end by `localhost:5601`.

### Tags

* latest

    Elasticsearch-2.3.4 Kibana-4.5.3

* kibana3

    Elasticsearch-1.7.4 Kibana-3.1.3

### Tips

* Install plugins

    `docker exec -u elasticsearch CONTAINER elasticsearch/bin/plugin install PLUGIN_NAME`
