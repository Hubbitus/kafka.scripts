#!/usr/bin/bash

#set -x

[ "$0" = "$BASH_SOURCE" ] && echo 'Config file must be sourced!' && exit 1

set -ueo pipefail

#: ${KAFKA_BOOTSTRAP_SERVERS:=PLAINTEXT://ecsc00a060af.epam.com:9092,PLAINTEXT://ecsc00a060b0.epam.com:9092,PLAINTEXT://ecsc00a060b1.epam.com:9092,PLAINTEXT://ecsc00a060b2.epam.com:9092,PLAINTEXT://ecsc00a060b3.epam.com:9092}
: ${KAFKA_BOOTSTRAP_SERVERS:=PLAINTEXT://kafka-sbox.epm-eco.projects.epam.com:9092}

: ${SCHEMA_REGISTRY:=schema-registry-sbox.epm-eco.projects.epam.com:8081}

# -J for JSON. Or you may provide format as you wish
: ${KAFKACAT_CONSOME_TOPIC_FORMAT=-J}
#: ${KAFKACAT_CONSOME_TOPIC_FORMAT='-f --\nKey (%K bytes): %k\t\nValue (%S bytes): %s\n\Partition: %p\tOffset: %o\nHeaders: %h\n'}
# Without value itself:
#: ${KAFKACAT_CONSOME_TOPIC_FORMAT='-f --\nKey (%K bytes): %k\t\nValue %S bytes)\n\Partition: %p\tOffset: %o\nHeaders: %h\n'}


_conf_dir=$(dirname $(realpath "$BASH_SOURCE"))

KAFKACAT_EXEC_CACHE_NAME='kafkacat-exec-cache-SBOX'
CONTAINER_CACHE_EXTRA_OPTIONS=()
# In command below we mount /conf for holds certificates and keystores. Paswd file allso must contain password for kerberos account,
# provided in sasl.kerberos.kinit.cmd line. Please be careful and NEVER commit sensitive information into git!!!
KAFKACAT_SECURE_OPTIONS=()



: ${KAFKA_CONNECT_HOST:=localhost:8083}
#: ${KSQLDB_SERVER:=http://localhost:8088}
: ${KSQLDB_SERVER:=http://ksqldb-2-epm-ssdl-ksqldb.by.paas.epam.com}
