#!/usr/bin/bash

# Script  to list present kafka topics.
# Unlike _kafka.list-topics.sh will show also partitions

source "$(dirname $0)/.config.sh"

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}

source "$(dirname $0)/_kafkacat.sh" -L "$@"
