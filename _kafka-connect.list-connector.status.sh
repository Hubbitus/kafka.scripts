#!/usr/bin/bash

# Script to list present kafka topics.
# Unlike _kafka.list-topics.sh will show also partitions

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}
: ${CONNECTOR?"Please ptovide CONNECTOR variable"}

http ${KAFKA_CONNECT_HOST}/connectors/${CONNECTOR}/status
