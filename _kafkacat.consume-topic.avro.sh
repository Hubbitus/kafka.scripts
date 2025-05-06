#!/bin/bash

# Script to print messages from topic.
# F.e. to list last 10 messages (with offsets -O) and exit:
# TOPIC=topic1 ./_kafkacat.consume-topic.sh -Oe -o-10 -c10

source "$(dirname $0)/.shared.sh"

: ${SCHEMA_REGISTRY?"Not enough vars set: SCHEMA_REGISTRY required"}
: "${KEY_SERIALIZATION:=-s key=avro}"

source "$(dirname $0)/_kafkacat.consume-topic.sh" \
	-s value=avro ${KEY_SERIALIZATION} -r "${SCHEMA_REGISTRY}" \
		"$@" | \
			jq --unbuffered -c ". += { \"_schema_url_value\": (\"${SCHEMA_REGISTRY}/schemas/ids/\" + (.value_schema_id|tostring)) } + if .key_schema_id then { \"_schema_url_key\": (\"${SCHEMA_REGISTRY}/schemas/ids/\" + (.key_schema_id|tostring)) } else null end"
