#!/usr/bin/bash

# Script to obtain topic offsets (effectively amount of messages in it)

source "$(dirname $0)/.shared.sh"

# By https://stackoverflow.com/questions/28579948/java-how-to-get-number-of-messages-in-a-topic-in-apache-kafka/50083376#50083376

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}
: ${TOPIC?"Not enough vars set: TOPIC required. Script to count amount of messages in topic.  Example: TOPIC=topic1 $0"}

podman exec -it $(kafka_exec_cache) kafka-run-class kafka.tools.GetOffsetShell --broker-list ${KAFKA_BOOTSTRAP_SERVERS} \
	--topic $TOPIC \
		"$@" 2>&1
