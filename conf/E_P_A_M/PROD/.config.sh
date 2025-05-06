#!/bin/bash

#set -x

[ "$0" = "${BASH_SOURCE[0]}" ] && echo 'Config file must be sourced!' && exit 1

ENV=PROD

: ${KERBEROS_USER:=Pavel_Alexeev@PETERSBURG.EPAM.COM}
: ${KERBEROS_KEYTAB_FILE:="conf/${ENV}/${KERBEROS_USER}.keytab"}

: ${KAFKA_BOOTSTRAP_SERVERS:=kafka.epm-eco.projects.epam.com:9095}

: ${SCHEMA_REGISTRY:=http://schema-registry.epm-eco.projects.epam.com:8081}

# -J for JSON. Or you may provide format as you wish
: ${KAFKACAT_CONSUME_TOPIC_FORMAT=-J}
#: ${KAFKACAT_CONSUME_TOPIC_FORMAT='-f --\nKey (%K bytes): %k\nValue (%S bytes): %s\n\Partition: %p\tOffset: %o\nHeaders: %h\n'}
# Without value itself:
#: ${KAFKACAT_CONSUME_TOPIC_FORMAT='-f --\nKey (%K bytes): %k\t\nValue %S bytes\n\Partition: %p\tOffset: %o\nHeaders: %h\n'}

_conf_dir=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

CONTAINER_CACHE_EXTRA_OPTIONS_kafkacat=('-v.:/host' "-v${_conf_dir}:/conf:Z,ro" "-v${_conf_dir}/krb5.conf:/etc/krb5.conf:Z,ro")
# Note! For Kerberos auth you need also configure
CONTAINER_CACHE_EXTRA_OPTIONS_confluent=('--network=host' '-v.:/host' "-v${_conf_dir}:/conf:Z,ro" "-v${_conf_dir}/krb5.conf:/etc/krb5.conf:Z,ro" '--env=KAFKA_HEAP_OPTS=-Xmx4096M' '--env=KAFKA_OPTS=-Djava.security.auth.login.config=/conf/jaas.conf -Djava.security.krb5.conf=/etc/krb5.conf')

# In command below we mount /conf for holds certificates and keystores. File paswd also must contain password for kerberos account,
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

CONSUMER_GROUP_ID=epm-ddo.consumer.$(hostname).$(date --iso-8601=s)
