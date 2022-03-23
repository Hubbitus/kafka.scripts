#!/usr/bin/bash

# Script to general purpose call kafkactl from podman-container. All arguments passed directly to it
# See https://github.com/deviceinsight/kafkactl for kafkactl doc

source $(dirname $0)/.shared.sh

podman exec -i $(kafkactl_exec_cache) kafkactl \
	"$@"
