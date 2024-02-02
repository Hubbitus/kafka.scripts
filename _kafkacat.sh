#!/usr/bin/bash

# Script to general purpose call kafkacat from podman-container. All arguments passed directly to it
# See https://github.com/edenhill/kafkacat for kafkacat doc

source $(dirname $0)/.shared.sh

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}

# To do that work possibly you need configure resolved (https://fedoramagazine.org/systemd-resolved-introduction-to-split-dns/):
# sudo resolvectl dns gpd0 10.66.110.11 10.66.110.10
podman exec -i $(kafkacat_exec_cache) \
	-b "${KAFKA_BOOTSTRAP_SERVERS}" "${KAFKACAT_SECURE_OPTIONS[@]}" \
		-m30 "$@"
