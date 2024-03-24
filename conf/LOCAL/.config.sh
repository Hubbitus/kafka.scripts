#!/usr/bin/bash

#set -x

[ "$0" = "${BASH_SOURCE[0]}" ] && echo 'Config file must be sourced!' && exit 1

# Default env name, if not set is parent dir name:
infer_ENV


set -ueo pipefail

: ${KAFKA_BOOTSTRAP_SERVERS:=PLAINTEXT://localhost:9092}
: ${SCHEMA_REGISTRY:=localhost:8081}
#: ${KEY_SERIALIZATION:=-s key=avro}
: ${KEY_SERIALIZATION:=-s key=s}

# -J for JSON. Or you may provide format as you wish
: ${KAFKACAT_CONSUME_TOPIC_FORMAT:=-J}
#: ${KAFKACAT_CONSUME_TOPIC_FORMAT:='-f --\nKey (%K bytes): %k\t\nValue (%S bytes): %s\n\Partition: %p\tOffset: %o\nHeaders: %h\n'}


_conf_dir=$(dirname $(realpath "$BASH_SOURCE"))

CONTAINER_CACHE_EXTRA_OPTIONS_kafkacat=('-v.:/host' "-v${_conf_dir}:/conf:z,ro")
CONTAINER_CACHE_EXTRA_OPTIONS_confluent=('-v.:/host' "-v${_conf_dir}:/conf:z,ro" '--env=KAFKA_HEAP_OPTS=-Xmx2048M')

# In command below we mount /conf for holds certificates and keystores. Paswd file allso must contain password for kerberos account,
# provided in sasl.kerberos.kinit.cmd line. Please be careful and NEVER commit sensitive information into git!!!
KAFKACAT_SECURE_OPTIONS=()



: ${KAFKA_CONNECT_HOST:=http://localhost:8083}
#: ${KSQLDB_SERVER:=http://localhost:8088}
: ${KSQLDB_SERVER:=http://ksqldb-2-epm-ssdl-ksqldb.by.paas.epam.com}

