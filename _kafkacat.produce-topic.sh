#!/usr/bin/bash


source "$(dirname $0)/.shared.sh"

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required."}
: ${TOPIC?"Not enough vars set: TOPIC required."}

#source "$(dirname $0)/_kafkacat.sh" -P -K: "$@"

#echo 'key1:{"one": 1}' | podman exec -i $(kafkacat_exec_cache) cat -
#exit

echo 'key1:{"one": 1}' | podman exec -i $(kafkacat_exec_cache) kafkacat \
	-b "${KAFKA_BOOTSTRAP_SERVERS}" "${KAFKACAT_SECURE_OPTIONS[@]}" \
		-P -e -t ${TOPIC} -K: \
			"$@"
