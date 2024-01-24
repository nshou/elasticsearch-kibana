## Elasticsearch and Kibana in one container

Simple and lightweight docker image for previewing Elasticsearch and Kibana.

You can connect to Elasticsearch through https://localhost:9200 and explore Kibana via https://localhost:5601

The password for the instance will be output to the console at first launch.

### Usage
*Dockerhub*
```bash
# No persistence
docker run -d -p 9200:9200 -p 5601:5601 nshou/elasticsearch-kibana

# Persistent data (named: ek_data)
docker run -d -v ek_data:/home/elastic -p 9200:9200 -p 5601:5601 nshou/elasticsearch-kibana
```

*Github Container Registry*
```bash
# No persistence
docker run -d -p 9200:9200 -p 5601:5601 ghcr.io/nshou/elasticsearch-kibana

# Persistent data
docker run -d -v ek_data:/home/elastic -p 9200:9200 -p 5601:5601 ghcr.io/nshou/elasticsearch-kibana
```


---

### `ENV` Mutable Variables

|           Name            |    Type   |                                  Description                                    |
|---------------------------|-----------|---------------------------------------------------------------------------------|
| `SSL_MODE`                | `boolean` | Toggles between SSL / TLS Modes for Elasticsearch + Kibana. *(default: `true`)* |
| `RANDOM_PASSWORD_ON_BOOT` | `boolean` | Sets a random password on boot. Overrides `ELASTIC_PASSWORD_RESET` if enabled.  |
| `ELASTIC_PASSWORD_RESET`  | `string`  | Set a manual password on boot to use for the `elastic` superuser.               |
| `ELASTIC_VERSION`         | `string`  | Elasticsearch Version to use for downloading.                                   |
| `KIBANA_VERSION`          | `string`  | Kibana Version to use for downloading.                                          |


---

### Resetting `elastic` user password
If for some reason your password does not get shows as being reset in the console you can run the following command inside of the container.
```bash
elasticsearch/bin/elasticsearch-reset-password \
      -v \
      --url "https://localhost:9200" \
      -u elastic \
      -b \
      -i \
      -E xpack.security.http.ssl.enabled=true \
      -E xpack.security.http.ssl.certificate=/home/elastic/elasticsearch/config/certs/instance/instance.crt \
      -E xpack.security.http.ssl.key=/home/elastic/elasticsearch/config/certs/instance/instance.key \
      -E xpack.security.http.ssl.certificate_authorities=/home/elastic/elasticsearch/config/certs/ca/ca.crt
```

### Tags
Tag     | Elasticsearch | Kibana
------- | ------------- | ------
latest  | 8.10.4        | 8.10.4
kibana7 | 7.17.9        | 7.17.9
kibana6 | 6.5.4         | 6.5.4
kibana5 | 5.6.6         | 5.6.6
kibana4 | 2.4.1         | 4.6.2
kibana3 | 1.7.4         | 3.1.3
