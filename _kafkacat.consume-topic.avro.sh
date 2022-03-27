#!/usr/bin/bash

# Script to print messages from topic.
# F.e. to list last 10 messages (with offsets -O) and exit:
# TOPIC=topic1 ./_kafkacat.consume-topic.sh -Oe -o-10 -c10

source "$(dirname $0)/.shared.sh"

: ${SCHEMA_REGISTRY?"Not enough vars set: SCHEMA_REGISTRY required"}

source "$(dirname $0)/_kafkacat.consume-topic.sh" \
	-s value=avro -r "${SCHEMA_REGISTRY}" \
		"$@"
