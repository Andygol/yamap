#!/bin/bash
set -e

# Create 'openstreetmap' user
# Password and superuser privilege are needed to successfully run test suite
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;
EOSQL
