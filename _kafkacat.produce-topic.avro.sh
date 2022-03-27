#!/usr/bin/bash

### !WARNING! Kcat have no builtin possibility to produce in AVRO. See https://github.com/edenhill/kcat/issues/226
### That example by https://forum.confluent.io/t/can-you-produce-avro-data-with-kafkacat/384/3
### Also very helpfull DOC for understanding CLI and format: https://www.michael-noll.com/blog/2013/03/17/reading-and-writing-avro-files-from-the-command-line/

source "$(dirname $0)/.shared.sh"

function usage(){
cat <<EOF


To produce with AVRO support we need have scheme to encode data. That may be provided in several ways:
1) AVRO_SCHEMA_FILE variable to read local avsc file. Then that will be published into schema registry provided in \${SCHEMA_REGISTRY} variable.
	Schema subject will be equal to the \${TOPIC} (we do not use -value, -key suffixes because all keys are strings by convention)
2) AVRO_SCHEMA_URL. URL to ubtain that from schema registry. Something like: http://<host>/subjects/<subject>/versions/latest or http://<host>/schemas/ids/<schema_id>. Then that will be downloaded and used for encoding.
	If host (first part of URL) does not matched to the configured \${SCHEMA_REGISTRY} (e.g. download betwveen environments), then it will be also automatically uploaded to the \${SCHEMA_REGISTRY}.
		Schema subject will be equal to the \${TOPIC} (we do not use -value, -key suffixes because all keys are strings by convention)
3) AVRO_SCHEMA_LAST='true'. Most automatic way! In that variant will be performed attempt to read last message from the configured topic, get there scheme ID, download that from the \${SCHEMA_REGISTRY} and use for the encoding data.
	WARNING! Even if file in kcat format and contains records for different topics, schema will be taken only by first record topics specification!!!

If you provided argument <file.json> is already in ktat format and contains JSON-lines with keys: key, topic, payload, then they will be taken by default! Provided variables take precedence (e.g. you may re-route that into another topic)!
We will not use 'value_schema_id' from file because most frequently that is exported from different environment (and because that is not full URL thta is hardly or impossible to check)!

Examples of invocation:
AVRO_SCHEMA_LAST=true $0 <kcat-exported-file.json>
TOPIC=my_topic KEY=123 AVRO_SCHEMA_LAST=true $0 <file.json>
TOPIC=my_topic KEY=123 AVRO_SCHEMA_URL=http://schema-registry-sbox.epm-eco.projects.epam.com:8081/subjects/epam.mdm.IndustrySectorProject/versions/latest $0 <file.json>
TOPIC=my_topic KEY=123 AVRO_SCHEMA_URL=http://schema-registry.epm-eco.projects.epam.com:8081/schemas/ids/21490 $0 <file.json>
TOPIC=my_topic KEY=123 AVRO_SCHEMA_FILE=file.avsc $0 <file.json>

Note, KEY optional, but in most cases KEY=null it is not what all consumers awaiting!
EOF
exit 1

# ECO Question about Schema-registry get subject by ID
# https://teams.microsoft.com/l/message/19:c3095988a42f49569aa7e775fcde6a8b@thread.skype/1648335061738?tenantId=b41b72d0-4e9f-4c26-8a69-f949f367c91d&groupId=269a96b6-3e3e-48a2-9e17-5d0cdd591139&parentMessageId=1648335061738&teamName=EPAM%20Datahub%20Support&channelName=PubSub&createdTime=1648335061738
}

set -e

######### Check requirements #########
PAYLOAD_JSON_FILE="$1"
[[ ! -f $PAYLOAD_JSON_FILE ]] && echo "File [${PAYLOAD_JSON_FILE}] not exists!" && usage
: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required.$(usage)"}
: ${SCHEMA_REGISTRY?"Not enough vars set: SCHEMA_REGISTRY required$(usage)"}
[[ ! "${AVRO_SCHEMA_FILE-}${AVRO_SCHEMA_URL-}${AVRO_SCHEMA_LAST-}" ]] && echo 'One of the AVRO_SCHEMA_FILE, AVRO_SCHEMA_URL, AVRO_SCHEMA_LAST must be set!' && usage
#: ${TOPIC?"Not enough vars set: TOPIC required.$(usage)"}
[[ ! ${TOPIC-} ]] && $(jq .topic "$PAYLOAD_JSON_FILE" | grep -q null) && echo "In payload file [${PAYLOAD_JSON_FILE}] key [topic] absent atleast in one record! So, variable TOPIC is required then (and will have precedance for all)" && usage
######### /Check requirements ########

_AVRO_TOOLS_JAR=.tmp/avro-tools-1.10.2.jar
_TMP_DIR=.tmp
mkdir -p "${_TMP_DIR}"


function cleanup(){
	[[ "${_AVRO_SCHEMA_FILE-}" ]] && rm -vf "${_AVRO_SCHEMA_FILE}"
	[[ "${_AVRO_ENCODED_DATA_FILE-}" ]] && rm -vf "${_AVRO_ENCODED_DATA_FILE}"
}
trap 'cleanup' EXIT INT

# Publish Schema with Schema Registry
# @param $1 - file with AVRO schema
# @param $TOPIC used
# @param $SCHEMA_REGISTRY used
function publishSchema(){
	ID=$(curl -s -X POST -H "Content-Type: application/json" --data "$(jq '{schema: (. | tojson)}' ${1})" http://${SCHEMA_REGISTRY}/subjects/${TOPIC}/versions | jq .id) # '
	echo "Schema registered with id: $ID" > /dev/stderr
}

# @param $1 - URL to download from
# @used _AVRO_SCHEMA_FILE variable and there placed schema
# @used ID - set to id of downloaded scheme
function downloadSchema(){
	local _url="$1"
	_AVRO_SCHEMA_FILE="$(mktemp "${_TMP_DIR}"/schema_XXXXX.avsc)"
	_RESP=$(curl -s ${_url})
	echo "${_RESP}" | jq '.schema | fromjson' > "${_AVRO_SCHEMA_FILE}"
	# Important for the `latest` schemas
	local _id=$(echo "${_RESP}" | jq .id)
}

if [[ "${AVRO_SCHEMA_FILE-}" ]]; then
	publishSchema "${AVRO_SCHEMA_FILE}"
fi

if [[ "${AVRO_SCHEMA_URL-}" ]]; then
	ID=$(downloadSchema "${AVRO_SCHEMA_URL}")
	if [[ $AVRO_SCHEMA_URL != $SCHEMA_REGISTRY* ]]; then # $AVRO_SCHEMA_URL !startsWith $SCHEMA_REGISTRY
		publishSchema "${_AVRO_SCHEMA_FILE}"
	fi
fi

if [[ 'true' == ${AVRO_SCHEMA_LAST-} ]]; then
	echo 'Operate on mode AVRO_SCHEMA_LAST=true. Try to use scheme from the last published record in the topic'
	# Look only to the first record in the file if TOPIC not provided! See warning in the usage function!
	ID=$(TOPIC=${TOPIC-$(jq -r --slurp '.[1].topic' "${PAYLOAD_JSON_FILE}")} ./_kafkacat.consume-topic.avro.sh -e -o-1 | jq .value_schema_id)
	downloadSchema "${SCHEMA_REGISTRY}/schemas/ids/${ID}"
fi
echo ID=$ID

# @param $1 - string of JSON message
function encodeMessageToAVRO(){
	local _record="$1"

	if [[ ! -f ${_AVRO_TOOLS_JAR} ]]; then
		mvn dependency:get -Dartifact=org.apache.avro:avro-tools:1.10.2:jar -Ddest="${_TMP_DIR}"
	fi

	[[ -f ${_AVRO_ENCODED_DATA_FILE-} ]] && rm -vf "${_AVRO_ENCODED_DATA_FILE}"
	_AVRO_ENCODED_DATA_FILE=$(mktemp "${_TMP_DIR}"/avro_data_XXXXX.avro)

	# Magic Byte 0x00
	printf '\x00' > ${_AVRO_ENCODED_DATA_FILE}
	# Schema Registry ID as 32bit WORD
	printf "0: %.8x" $ID | xxd -r -g0 >> ${_AVRO_ENCODED_DATA_FILE}

	# !WARNING! kcat incorrectly work with namespaces! So, adjustments may be needed! See my bugreport https://github.com/edenhill/kcat/issues/376 and https://stackoverflow.com/questions/49926146/org-apache-avro-avrotypeexception-unknown-union-branch/49939794#49939794
	# Convert JSON payload into Avro using Avro's own toolage, write only the binary data of Avro to the file
	# @TODO For now assume single message in the file!
	java -Dlog4j.configurationFile=/dev/null -jar "${_AVRO_TOOLS_JAR}" jsontofrag --schema-file "${AVRO_SCHEMA_FILE-}${_AVRO_SCHEMA_FILE-}" <( echo "${_record}" | jq '.payload // .' ) >> "${_AVRO_ENCODED_DATA_FILE}" \
		2>&1 | sed '/Unable to load native-hadoop library for your platform/d'
}

# To get _topic value outside of loop. See http://mywiki.wooledge.org/BashFAQ/024
shopt -s lastpipe

# 2 JQ in pipe to work with formated JSON files too
jq . "${PAYLOAD_JSON_FILE}" | jq -c | while read RECORD; do
	echo "PROCESS: $( echo "${RECORD}" | jq '{ topic: .topic, key: .key, offset: .offset, tstype: .tstype, ts: .ts, ts__time: ( if .ts then .ts / 1000 | strftime("%Y-%m-%dT%H:%M:%S %Z") else null end ), value_schema_id: .value_schema_id }' )"
	# @TODO naive approach, we parse only 1 value for the header. Potentially that may be array
	_HEADERS=$(echo "$RECORD" | jq '.headers | to_entries | map("-H " + .key + "=\"" + .value[0] + "\"") | join(" ")' -r) #'
	echo "Headers will be used: ${_HEADERS}"
	_key_record=$(echo "$RECORD" | jq -r .key)
	_key=${KEY-${_key_record}}
	_topic_record=$(echo "$RECORD" | jq -r .topic)
	_topic=${TOPIC-${_topic_record}}
	echo "KEY: ENV variable provided=${KEY-}, record.key=${_key_record}, will be used value: ${_key}"
	echo "TOPIC: ENV variable provided=${TOPIC-}, record.key=${_topic_record}, will be used value: ${_topic}"
	encodeMessageToAVRO "${RECORD}"
	# NOTE, we use file in container! So, expected parameter CONTAINER_CACHE_EXTRA_OPTIONS=('-v.:/host')!
	# @TODO that is not work with stdin redirection and sourcing unfortunately!
	podman exec $(kafkacat_exec_cache) kafkacat \
		-b "${KAFKA_BOOTSTRAP_SERVERS}" "${KAFKACAT_SECURE_OPTIONS[@]}" -m30 \
			-P -e -t ${_topic} -k ${_key} ${_HEADERS} /host/${_AVRO_ENCODED_DATA_FILE}

	echo '   ...SENT!'
	#source "$(dirname $0)/_kafkacat.sh" \
	#	-P -e -t ${TOPIC} -k 'test-key-1' \
	#		"$@" \
	#			< data_file
done


exit
sleep 2
echo '#######################################################'
echo '######## DEBUG read back topic (AVRO), last 2: ########'
echo '#######################################################'
ENV=SBOX TOPIC=${_topic} ./_kafkacat.consume-topic.avro.sh -o-2 -e
