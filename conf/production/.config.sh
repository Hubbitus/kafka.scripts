#!/usr/bin/bash

#set -x

[ "$0" = "$BASH_SOURCE" ] && echo 'Config file must be sourced!' && exit 1

set -ueo pipefail

: ${KAFKA_BOOTSTRAP_SERVERS:=kafka.epm-eco.projects.epam.com:9095}

: ${SCHEMA_REGISTRY:=schema-registry.epm-eco.projects.epam.com:8081}

# -J for JSON. Or you may provide format as you wish
: ${KAFKACAT_CONSOME_TOPIC_FORMAT:=-J}
#: ${KAFKACAT_CONSOME_TOPIC_FORMAT:='-f --\nKey (%K bytes): %k\t\nValue (%S bytes): %s\n\Partition: %p\tOffset: %o\nHeaders: %h\n'}


_conf_dir=$(dirname $(realpath "$BASH_SOURCE"))

CONTAINER_CACHE_EXTRA_OPTIONS=("-v${_conf_dir}:/conf" "-v${_conf_dir}/krb5.conf:/etc/krb5.conf")

# In command below we mount /conf for holds certificates and keystores. Paswd file allso must contain password for kerberos account,
# provided in sasl.kerberos.kinit.cmd line. Please be careful and NEVER commit sensitive information into git!!!
KAFKACAT_SECURE_OPTIONS=(
	'-Xssl.ca.location=/conf/epm-eco-prod.ca.crt'
	'-Xsecurity.protocol=SASL_SSL'
	'-Xsasl.mechanisms=GSSAPI'
	'-Xsasl.kerberos.principal=kafkaclient'
	'-Xsasl.kerberos.kinit.cmd=/usr/bin/kinit --password-file=/conf/paswd Pavel_Alexeev@PETERSBURG.EPAM.COM'
)

: ${KAFKA_CONNECT_HOST:=localhost:8083}

: ${KSQLDB_SERVER:=http://localhost:8088}

source "$(dirname $0)/.shared.sh"
