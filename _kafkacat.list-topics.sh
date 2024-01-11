#!/usr/bin/bash

# Script to list present kafka topics.
# Unlike _kafka.list-topics.sh will show also partitions
# See also _kafkacat.list-topics.plain-list.sh

source "$(dirname $0)/.shared.sh"

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}

# SASL error filter is just workaround of https://github.com/confluentinc/confluent-kafka-dotnet/issues/1422 - there always error produced, but all works as expected
source "$(dirname $0)/_kafkacat.sh" -J -L "$@" 2> >(grep -Fv 'SASL authentication error: SaslAuthenticateRequest failed: Local: Broker handle destroyed' >/dev/stderr) | jq '.topics[]'
