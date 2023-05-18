#!/usr/bin/bash

#set -x

[ "$0" = "$BASH_SOURCE" ] && echo 'Config file must be sourced!' && exit 1

set -ueo pipefail

: ${KAFKA_BOOTSTRAP_SERVERS:=PLAINTEXT://localhost:9092}

: ${SCHEMA_REGISTRY:=localhost:8081}

# -J for JSON. Or you may provide format as you wish
: ${KAFKACAT_CONSUME_TOPIC_FORMAT:=-J}
#: ${KAFKACAT_CONSUME_TOPIC_FORMAT:='-f --\nKey (%K bytes): %k\t\nValue (%S bytes): %s\n\Partition: %p\tOffset: %o\nHeaders: %h\n'}


_conf_dir=$(dirname $(realpath "$BASH_SOURCE"))

CONTAINER_CACHE_EXTRA_OPTIONS_kafkacat=('--network host')
# In command below we mount /conf for holds certificates and keystores. Paswd file allso must contain password for kerberos account,
# provided in sasl.kerberos.kinit.cmd line. Please be careful and NEVER commit sensitive information into git!!!
KAFKACAT_SECURE_OPTIONS=()



: ${KAFKA_CONNECT_HOST:=localhost:8083}
#: ${KSQLDB_SERVER:=http://localhost:8088}
: ${KSQLDB_SERVER:=http://ksqldb-2-epm-ssdl-ksqldb.by.paas.epam.com}

source "$(dirname $0)/.shared.sh"
