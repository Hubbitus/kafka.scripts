#!/usr/bin/bash

# Script to show current logging settings of kafka-connect cluster
# API detailed description: https://docs.confluent.io/platform/current/connect/logging.html
# Example:
# LOGGER=io.confluent.connect.jdbc LEVEL=TRACE ./_kafka-connect.admin.logger.put.sh

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}
: ${LOGGER?"Not enough vars set: LOGGER required. Example: LOGGER=io.confluent.connect.jdbc LEVEL=TRACE $0"}
: ${LEVEL?"Not enough vars set: LEVEL required. Example: LOGGER=io.confluent.connect.jdbc LEVEL=TRACE $0"}

http PUT ${KAFKA_CONNECT_HOST}/admin/loggers/$LOGGER level=$LEVEL
