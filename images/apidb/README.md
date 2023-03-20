# API DB initialization

The API DB is used to store data as they are in <https://openstreetmap.org/>. This is the same DB that is used by the main OSM API to store raw OSM data. You may ingest data from <https://planet.osm.org/> and/or store data for your own API instance; generate data damp and diff for further replication in other OSM related services.

```text
apidb
├ init
│ └ 10-openstreetmap-apidb-init.sh
├ docker-compose.yml
├ Dockerfile
└ README.md
```

The image is based on `postgres:alpine`.

- `10-openstreetmap-apidb-init.sh` grants permission on `$POSTGRES_DB` to `$POSTGRES_USER` [^1] 


## Environment variables

This container requires next environment variables:

- `POSTGRES_HOST=apidb`
- `POSTGRES_DB=openstreetmap`
- `POSTGRES_USER=openstreetmap`
- `POSTGRES_PASSWORD=1234`

The vars are in the [apidb.env](../../env/apidb.env) file. You may adjust their value if needed.

## Running DB container

### Docker compose

The best way to run the container is to use `docker compose` command in the `apidb` dir:

```sh
docker compose up
```

or if you already have a created container

```sh
docker compose run apidb
```

### Docker

In case you want to run only the API DB instance using docker, build image

```sh
docker build -t apidb --no-cache .
```

and run container with

```sh
docker run \
--name apidb \
--env-file ${PWD}/../../env/apidb.env \ 
-v  ${PWD}/../../data/apidb/:/var/lib/postgresql/data \
-p "5432:5432" \
-t apidb
```

## Troubleshooting

In case you failed to init DB, check that your `data/apid` dir is empty, else clean it up.

```sh
if [ -d ../../data/apidir ]; then
  if [ "$(ls -A ../../data/apidb)" ]; then
    rm -rf ../../data/apidb/*
  else
    echo "Dir is empty"
  fi
else
    echo "Dir not found"
fi
```

After that, initialize the container with db again (from scratch).

---

[^1]: **Warning**: scripts in `/docker-entrypoint-initdb.d` are only run if you start the container with a data directory that is empty; any pre-existing database will be left untouched on container startup. One common problem is that if one of your `/docker-entrypoint-initdb.d` scripts fails (which will cause the entrypoint script to exit) and your orchestrator restarts the container with the already initialized data directory, it will not continue on with your scripts. See <https://github.com/docker-library/docs/blob/master/postgres/README.md#initialization-scripts>
