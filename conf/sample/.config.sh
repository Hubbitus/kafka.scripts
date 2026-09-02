#!/bin/bash

[ "$0" = "${BASH_SOURCE[0]}" ] && echo 'Config file must be sourced!' && exit 1

# Default env name, if not set is parent dir name:
infer_ENV


#? : ${KERBEROS_USER:=Pavel_Alexeev@PETERSBURG.??.COM}
#?: ${KERBEROS_KEYTAB_FILE:="conf/${ENV}/${KERBEROS_USER}.keytab"}

: ${KAFKA_BOOTSTRAP_SERVERS:=kafaka1.host:39091,kafaka2.host:39092,kafaka3.host:39093}
: ${SCHEMA_REGISTRY:=http://kafaka1.host:8081}
#: ${KEY_SERIALIZATION:=-s key=avro}
: ${KEY_SERIALIZATION:=-s key=s}

# -J for JSON. Or you may provide format as you wish
: ${KAFKACAT_CONSUME_TOPIC_FORMAT=-J}
#: ${KAFKACAT_CONSUME_TOPIC_FORMAT='-f --\nKey (%K bytes): %k\t\nValue (%S bytes): %s\n\Partition: %p\tOffset: %o\nHeaders: %h\n'}
# Without value itself:
#: ${KAFKACAT_CONSUME_TOPIC_FORMAT='-f --\nKey (%K bytes): %k\t\nValue %S bytes)\n\Partition: %p\tOffset: %o\nHeaders: %h\n'}

_conf_dir=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
# "

CONTAINER_CACHE_EXTRA_OPTIONS_kafkacat=('-v.:/host' "-v${_conf_dir}:/conf:z,ro" --network=host)
CONTAINER_CACHE_EXTRA_OPTIONS_confluent=('-v.:/host' "-v${_conf_dir}:/conf:z,ro" '--env=KAFKA_HEAP_OPTS=-Xmx2048M')

# In command below we mount /conf for holds certificates and keystores. File paswd also must contain password for kerberos account,
# provided in sasl.kerberos.kinit.cmd line. Please be careful and NEVER commit sensitive information into git!!!
KAFKACAT_SECURE_OPTIONS=(
	'-Xssl.ca.location=/conf/truststore.cer.pem'
	'-Xsecurity.protocol=SASL_SSL'
	'-Xsasl.mechanisms=SCRAM-SHA-512'
	'-Xsasl.username=data-receiver'
	'-Xsasl.password=super-pass'
)
#	'-Xdebug=all'

CONFLUENT_EXTRA_COMMON_OPTIONS=(
#	'--consumer.config=/conf/confluent.properties'
	'--command-config=/conf/confluent.properties'
)

CONSUMER_GROUP_ID=kafkacat.$(hostname).$(date --iso-8601=s)

: ${KAFKA_CONNECT_HOST:=https://kafka-connect.host}
#? : ${KSQLDB_SERVER:=http://ksqldb.host}
