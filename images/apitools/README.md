# API Tools is an image related to API DB deployment and maintenance routines

This image is used to create a container that is used to perform tasks related to the deployment of the API DB and perform operations to maintain it in an up-to-date state.


The created container allows:
- populate a fresh database with data from data extracts
- update the DB with diffs from planet.osm.org on a regular basis
- create a dump from the local database in the form of a  `*.osm.pbf` file

```text
apitools
├ apidb-tools.sh
├ docker-compose.yml
├ Dockerfile
└ README.md
```

The image is based on `debian:stable-slim` and contains:

- **[osmosis](https://wiki.openstreetmap.org/wiki/Osmosis)** – is a command line Java application for processing OSM data. This is the only one tool that allows to deploy API DB ([.deb](https://packages.debian.org/en/bullseye/osmosis)).
- **osmctools** [^1] [^2] [^3] – Small collection of basic OpenStreetMap tools, include converter, filter and updater files ([.deb](https://packages.debian.org/en/bullseye/osmctools)).
- **[osmium-tool](https://packages.debian.org/en/bullseye/osmium-tool)** – a multipurpose command line tool based on the Osmium library ([.deb](https://packages.debian.org/en/bullseye/osmium-tool)).

## Environment variables

This container requires environment variables from the [apidb.env](../../env/apidb.env) file to access API DB; [popdb.env](../../env/popdb.env) – to configure the parameters for obtaining a regional extract for uploading to the database; [repapidb.env](../../env/repapidb.env) – to configure parameters to receive diffs to keep the local DB up-to-date.

You may adjust their value if needed.

## Running DB container

### Docker compose

The best way to run the container is to use `docker compose` command in the `apitools` dir:

```sh
docker compose up
```

or if you already have a created container

```sh
docker compose run apitools
```

---

[^1]: https://wiki.openstreetmap.org/wiki/Osmupdate
[^2]: https://wiki.openstreetmap.org/wiki/Osmconvert
[^3]: https://wiki.openstreetmap.org/wiki/Osmfilter