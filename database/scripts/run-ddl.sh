#!/bin/bash

set -euo pipefail

# PSQL_ARGS+=" --echo-errors"
PSQL_ARGS+=" --echo-all"
PSQL_ARGS+=" --set=ON_ERROR_STOP=on"

RUN_COUNT=0
run() {
    RUN_COUNT=$((RUN_COUNT+1))
    echo "Apply ${RUN_COUNT}: $1"
    psql ${PSQL_ARGS} --file $1
}

core() {
    run ./schema/core.sql
}

core

echo "Schema application completed"
