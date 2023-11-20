#!/usr/bin/bash

# Script to list present kafka topics as plain list, without partitions info and other infromation.
# See also _kafkacat.list-topics.sh for more detailed information

source "$(dirname $0)/.shared.sh"

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}

source "$(dirname $0)/_kafkacat.list-topics.sh" | jq -r '.topic'
