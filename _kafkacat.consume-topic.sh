#!/usr/bin/bash

# Script to print messages from topic.
# F.e. to list last 10 messages (with offsets -O) and exit:
# TOPIC=topic1 ./_kafkacat.consume-topic.sh -Oe -o-10 -c10

source "$(dirname $0)/.config.sh"

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}
: ${TOPIC?"Not enough vars set: TOPIC required. F.e. to list last 10 messages (with offsets -O) and exit:
TOPIC=topic1 $0 -Oe -o-10 -c10
See also _kafkacat.consume-topic.lastN.sh script for simplicity"}

source "$(dirname $0)/_kafkacat.sh" \
	-C -t ${TOPIC} \
	-u \
	"${KAFKACAT_CONSOME_TOPIC_FORMAT}" \
		"$@"
