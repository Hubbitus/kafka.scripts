#!/usr/bin/bash

set -e

source ../../.shared.sh
source .config.sh

SSL_CA_LOCATION=$(printf '%s\n' "${KAFKACAT_SECURE_OPTIONS[@]}" | sed -n 's@^-Xssl\.ca\.location=/conf/@./@p')
USERNAME=$(printf '%s\n' "${KAFKACAT_SECURE_OPTIONS[@]}" | sed -n 's@^-Xsasl\.username=@@p')
PASSWORD=$(printf '%s\n' "${KAFKACAT_SECURE_OPTIONS[@]}" | sed -n 's@^-Xsasl\.password=@@p')


TOPIC=marketplace.dwh.application KAFKA_BOOTSTRAP_SERVERS="${KAFKA_BOOTSTRAP_SERVERS}" SASL_USERNAME="${USERNAME}" SASL_PASSWORD="${PASSWORD}" SSL_CA_LOCATION="${SSL_CA_LOCATION}" GROUP_ID="${CONSUMER_GROUP_ID}" \
	timeout 25 \
		uv run --with confluent-kafka \
			python sample-consumer.SASL_SSL.py
