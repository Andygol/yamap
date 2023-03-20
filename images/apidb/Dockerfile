FROM postgres:alpine

ARG POSTGRES_DB_SCHEMA

ENV POSTGRES_DB_SCHEMA=${POSTGRES_DB_SCHEMA}

# Add db init script to init OSM-specific Postgres user and DB structure.
ADD ./init/10-openstreetmap-apidb-init.sh /docker-entrypoint-initdb.d/
ADD ${POSTGRES_DB_SCHEMA} /docker-entrypoint-initdb.d/20-apidb-init.sql
RUN chmod 644 /docker-entrypoint-initdb.d/20-apidb-init.sql