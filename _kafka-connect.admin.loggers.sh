#!/usr/bin/bash

# Script to show current logging settings of kafka-connect cluster
# API detailed description: https://docs.confluent.io/platform/current/connect/logging.html

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}

http ${KAFKA_CONNECT_HOST}/admin/loggers
