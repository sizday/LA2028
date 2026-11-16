#!/bin/bash

/liquibase/migrate.sh update --url "$POSTGRES_HOST:$POSTGRES_PORT" --db "$POSTGRES_DB" --user "$POSTGRES_USER" --password "$POSTGRES_PASSWORD"
