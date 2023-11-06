## Elasticsearch and Kibana in one container

Simple and lightweight docker image for previewing Elasticsearch and Kibana.

### Usage
```bash
docker run -d -p 9200:9200 -p 5601:5601 nshou/elasticsearch-kibana
```

### SSL / TLS Mode
You can toggle SSL/TLS mode with the `SSL_MODE` ENV parameter. **(Enabled by default)**
```bash
docker run -d -p 9200:9200 -p 5601:5601 -e SSL_MODE=false nshou/elasticsearch-kibana
```

You can connect to Elasticsearch through `localhost:9200` and explore Kibana via `localhost:5601`.

The password for the instance will be output to the console at first launch.

### Tags

Tag     | Elasticsearch | Kibana
------- | ------------- | ------
latest  | 8.10.4        | 8.10.4
kibana7 | 7.17.9        | 7.17.9
kibana6 | 6.5.4         | 6.5.4
kibana5 | 5.6.6         | 5.6.6
kibana4 | 2.4.1         | 4.6.2
kibana3 | 1.7.4         | 3.1.3
