#!/bin/bash

source "$(dirname $0)/.config.sh"


: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}
: ${TOPIC?"Not enough vars set: TOPIC required. Example: TOPIC=topic1 $0"}


docker exec -it $(kafka_exec_cache) kafka-console-consumer --bootstrap-server $KAFKA_BOOTSTRAP_SERVERS \
	--from-beginning \
	--property print.key=true \
	--topic ${TOPIC} 2>&1 \
		"$@"
