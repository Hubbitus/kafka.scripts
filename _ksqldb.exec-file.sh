#!/bin/bash

source "$(dirname $0)/.config.sh"


: ${KSQLDB_SERVER?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}
: ${KSQL_FILE?"Not enough vars set: KSQL_FILE required. Example: KSQL_FILE='SHOW STREAMS' $0"}

# By: https://docs.ksqldb.io/en/latest/tutorials/examples/#run-ksqldb-statements-from-the-command-line
# podman does not work with master server
#podman run --network host --name ksqldb-cli -it --rm docker.io/confluentinc/ksqldb-cli:0.13.0

/home/pasha/@Projects/@Experiments/ksqlDB/confluent/ksql/bin/ksql ${KSQLDB_SERVER} --file "${KSQL_FILE}"
