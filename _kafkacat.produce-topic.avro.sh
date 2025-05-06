#!/bin/bash

### !WARNING! Kcat have no builtin possibility to produce in AVRO. See https://github.com/edenhill/kcat/issues/226
### That example by https://forum.confluent.io/t/can-you-produce-avro-data-with-kafkacat/384/3
### Also very helpful DOC for understanding CLI and format: https://www.michael-noll.com/blog/2013/03/17/reading-and-writing-avro-files-from-the-command-line/

source "$(dirname $0)/.shared.sh"

function usage(){
cat <<EOF

To produce with AVRO support we need have scheme to encode data. That may be provided in several ways:
1) Most automatic and recommended way! In that variant we expect in source file structure like:
{
  "topic": "topic1",
  ...
  "value_schema_id": 40,
  "_schema_url_value": "http://gid-kafka-haproxy.gid.team:8081/schemas/ids/40",
  "key_schema_id": 4, // optional
  "_schema_url_key": "http://gid-kafka-haproxy.gid.team:8081/schemas/ids/4", // optional
  "payload": {...}
}

Please note: that is default format, produced by _kafkacat.consume-topic.avro.sh and _kafkacat.consume-topic.avro.lastN.sh scripts.
In that case copying from one topic (possibly from another kafka) to another will be straight forward like:

# KEY_SERIALIZATION='-s key=avro' \
  N=2 ENV=DATA_DEV TOPIC=dev.users ./_kafkacat.consume-topic.avro.lastN.sh > messages.json
# ENV=DATA_TEST TOPIC=test.users ./_kafkacat.produce-topic.avro.sh messages.json

Both schemas will be downloaded and uploaded when needed according to the values of _schema_url_key and _schema_url_value fields.

2) AVRO_SCHEMA_FILE_key/AVRO_SCHEMA_FILE_value variable to read local avsc file. Then that will be published into schema registry provided in \${SCHEMA_REGISTRY} variable.
	Schema subject will be \$SCHEMA_SUBJECT_NAME (by default it \${TOPIC}-{key|value} by convention)
	Please note, for use it for key on dumping most probably you will need to use KEY_SERIALIZATION='-s key=avro'
	You may provide AVRO_SCHEMA_key=false or AVRO_SCHEMA_value=false, to do not use schema for key or value respectively.
3) AVRO_SCHEMA_URL_key/AVRO_SCHEMA_URL_value. URL to obtain that from schema registry. Something like: http://<host>/subjects/<subject>/versions/latest or http://<host>/schemas/ids/<schema_id>.
  Then that will be downloaded and used for encoding for each messages in file.
	If host (first part of URL) does not matched to the configured \${SCHEMA_REGISTRY} (e.g. download between environments), then it will be also automatically uploaded to the \${SCHEMA_REGISTRY}.
	Schema subject will be equal to the \$SCHEMA_SUBJECT_NAME (by default it \${TOPIC}-{key|value} by convention)

If provided argument <file.json> is already in kcat format and contains JSON-lines with keys: key, topic, payload, then they will be taken by default! Provided variables take precedence (e.g. you may re-route that into another topic)!
We will not use 'value_schema_id' from file because most frequently that is exported from different environment (and because that is not the full URL that is hardly or impossible to check)!

Examples of invocation (file.json is obtained something like: N=2 KEY_SERIALIZATION='-s key=avro' TOPIC=dev.users ./_kafkacat.consume-topic.avro.lastN.sh > file.json):
* TOPIC=test.users ./_kafkacat.produce-topic.avro.sh
* TOPIC=my_topic KEY=123 AVRO_SCHEMA_URL_value=http://schema-registry-sbox.epm-eco.projects.epam.com:8081/subjects/epam.mdm.IndustrySectorProject/versions/latest $0 <file.json>
* TOPIC=my_topic KEY=123 AVRO_SCHEMA_URL_value=http://schema-registry.epm-eco.projects.epam.com:8081/schemas/ids/21490 $0 <file.json>
* TOPIC=my_topic KEY=123 AVRO_SCHEMA_FILE=file.avsc $0 <file.json>

Note, KEY optional, but in most cases KEY=null it is not what all consumers awaiting!
EOF
exit 1

# ECO Question about Schema-registry get subject by ID
# https://teams.microsoft.com/l/message/19:c3095988a42f49569aa7e775fcde6a8b@thread.skype/1648335061738?tenantId=b41b72d0-4e9f-4c26-8a69-f949f367c91d&groupId=269a96b6-3e3e-48a2-9e17-5d0cdd591139&parentMessageId=1648335061738&teamName=EPAM%20Datahub%20Support&channelName=PubSub&createdTime=1648335061738
}

set -e

PAYLOAD_JSON_FILE="${1}"

######### Check requirements #########
: ${AVRO_SCHEMA_SOURCE:=true}
[[ ! -f $PAYLOAD_JSON_FILE ]] && echo "File [${PAYLOAD_JSON_FILE}] not exists!" && usage
: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required.$(usage)"}
: ${SCHEMA_REGISTRY?"Not enough vars set: SCHEMA_REGISTRY required$(usage)"}
PAYLOAD_JSON_FILE="$1"
if [[ ! 'true' == "${AVRO_SCHEMA_SOURCE}" ]]; then
  [[ ! "${AVRO_SCHEMA_FILE_key-}${AVRO_SCHEMA_URL_key-}" ]] && echo 'One of the AVRO_SCHEMA_FILE_key, AVRO_SCHEMA_URL_key needs to be provided if you do not use AVRO_SCHEMA_SOURCE. If you are not willing to use schema, you may set AVRO_SCHEMA_FILE_key=false!' && usage
  [[ ! "${AVRO_SCHEMA_FILE_value-}${AVRO_SCHEMA_URL_value-}" ]] && echo 'One of the AVRO_SCHEMA_FILE_value, AVRO_SCHEMA_URL_value needs to be provided if you do not use AVRO_SCHEMA_SOURCE. If you are not willing to use schema, you may set AVRO_SCHEMA_FILE_value=false!' && usage
  [[ ! ${TOPIC-} ]] && $(jq .topic "$PAYLOAD_JSON_FILE" | grep -q null) && echo "In payload file [${PAYLOAD_JSON_FILE}] key [topic] absent at least in one record! So, variable TOPIC is required then (and will have precedence for all)" && usage
fi
: "${AVRO_TOOLS_VERSION:=1.11.3}"
: "${DEBUG:=false}"
: "${_TMP_DIR:=.tmp}"
######### /Check requirements ########

_AVRO_TOOLS_JAR=.tmp/avro-tools-${AVRO_TOOLS_VERSION}.jar
mkdir -p "${_TMP_DIR}"

declare -A _AVRO_SCHEMA_ID
declare -A _AVRO_SCHEMA_FILE
declare -A _AVRO_ENCODED_DATA_FILE

# $1 - message to print
function debug(){
  [[ "${DEBUG}" ]] && echo "[DEBUG] $1" > /dev/stderr
}


function cleanup(){
	if [[ 'true' = "${DEBUG}" ]]; then
		echo 'WARNING. DEBUG=true provided. No cleanup will be performed!'
	else
	  rm -vf "${_TMP_DIR}/full.avro" "${_AVRO_SCHEMA_FILE[key]}" "${_AVRO_SCHEMA_FILE[value]}"
	fi
}
trap 'cleanup' EXIT INT

# Publish Schema with Schema Registry
# @param $1 - file with AVRO schema
# @param $2 - schema flavour: key or value
# @param $TOPIC used
# @param $SCHEMA_REGISTRY used
function publishSchema(){
	local _kind="$2"
#  debug "Publishing [${2}] schema from file [${1}] to [${SCHEMA_REGISTRY}/subjects/${TOPIC}-${2}/versions]"
	local _ID=$(curl -sS -X POST -H "Content-Type: application/json" --data "$(jq '{schema: (. | tojson)}' ${1})" ${SCHEMA_REGISTRY}/subjects/${TOPIC}-${2}/versions | jq .id) # '
	debug "Schema for [${_kind}] registered with id [${_ID}]. URL: [${SCHEMA_REGISTRY}/schemas/ids/${_ID}] (${SCHEMA_REGISTRY}/subjects/${TOPIC}-${2}/versions)" > /dev/stderr
	# Indirect set variable. See https://stackoverflow.com/a/16973754/307525
	_AVRO_SCHEMA_ID[${_kind}]=${_ID} # Important for the `latest` schemas
}

# @param $1 - URL to download from
# $2 - avsc flavour: key or value
# @used Set _AVRO_SCHEMA_FILE[key|value] variable and there placed schema
# @used _AVRO_SCHEMA_ID[key|value] - set to id of downloaded scheme
function downloadSchema(){
	local _url="$1"
	local _kind="$2"
	#?local _AVRO_SCHEMA_FILE="$(mktemp "${_TMP_DIR}"/schema_XXXXX.${2}.avsc)"
	_AVRO_SCHEMA_FILE[$_kind]="${_TMP_DIR}/schema.${2}.avsc"
	debug "Downloading [${2}] schema from URL: [${_url}] to file [${_AVRO_SCHEMA_FILE[$_kind]}]"
	local _RESP="$(curl -sS ${_url})"
	# "del(.namespace)" is the workaround of error "AvroTypeException: Unknown union branch Value". By https://stackoverflow.com/questions/49926146/org-apache-avro-avrotypeexception-unknown-union-branch
	# kcat incorrectly work with namespaces! So, adjustments may be needed! See my bugreport https://github.com/edenhill/kcat/issues/376 and https://stackoverflow.com/questions/49926146/org-apache-avro-avrotypeexception-unknown-union-branch/49939794#49939794
	echo "${_RESP}" | jq '.schema | fromjson | del(.namespace)' > "${_AVRO_SCHEMA_FILE[$_kind]}"
	# URL like http://gid-kafka-haproxy.gid.team:8081/schemas/ids/4 contains id:
	if [[ "${_url}" == *latest ]]; then
	  _AVRO_SCHEMA_ID[$_kind]=$(echo "${_RESP}" | jq .id) # Important for the `latest` schemas
	else
	  _AVRO_SCHEMA_ID[$_kind]="${_url//*\/ids\//}"
	fi
	debug "Downloaded [$2] schema from URL [$1] to file [${_AVRO_SCHEMA_FILE[$_kind]}], schema id: [${_AVRO_SCHEMA_ID[$_kind]}]"
}

# @param $1 - flavour: key or value
# @param $2 - string of JSON message
# @used _AVRO_ENCODED_DATA_FILE[key|value] to store file path
# @used _AVRO_SCHEMA_ID[key|value] - id of schema
# See https://forum.confluent.io/t/can-you-produce-avro-data-with-kafkacat/384/3
function encodeToAVRO(){
	local _kind="${1}"
	local _record="${2}"
	local _schema_file="${_AVRO_SCHEMA_FILE[${_kind}]}"
	_AVRO_ENCODED_DATA_FILE[${_kind}]="${_TMP_DIR}/avro_data.${_kind}.avro"
	rm -vf "${_AVRO_ENCODED_DATA_FILE[$_kind]}" 1>&2
	debug "Encoding to avro [${_kind}] by schema id [${_AVRO_SCHEMA_ID[$_kind]}] from file [${_schema_file}] to [${_AVRO_ENCODED_DATA_FILE[${_kind}]}]"

	if [[ ! -f ${_AVRO_TOOLS_JAR} ]]; then
	  mvn dependency:get -Dartifact=org.apache.avro:avro-tools:${AVRO_TOOLS_VERSION}:jar -Ddest="${_TMP_DIR}"
	fi

	# Magic Byte 0x00
	printf '\x00' > ${_AVRO_ENCODED_DATA_FILE[$_kind]}
	# Schema Registry ID as 32bit WORD
	printf "0: %.8x" ${_AVRO_SCHEMA_ID[$_kind]} | xxd -r -g0 >> ${_AVRO_ENCODED_DATA_FILE[$_kind]}

	# !WARNING! kcat incorrectly work with namespaces! So, adjustments may be needed! See my bugreport https://github.com/edenhill/kcat/issues/376 and https://stackoverflow.com/questions/49926146/org-apache-avro-avrotypeexception-unknown-union-branch/49939794#49939794
	# Convert JSON payload into Avro using Avro's own tooling, write only the binary data of Avro to the file
	# @TODO For now assume single message in the file!
	java -jar "${_AVRO_TOOLS_JAR}" jsontofrag --schema-file "${_schema_file}" <( echo "${_record}" ) \
		2> >(sed '/Unable to load native-hadoop library for your platform/d') \
		1>> "${_AVRO_ENCODED_DATA_FILE[$_kind]}"
}

# To get _topic value outside of loop. See http://mywiki.wooledge.org/BashFAQ/024
shopt -s lastpipe

_records_count=$(jq --slurp length "${PAYLOAD_JSON_FILE}")
_i=0
jq . "${PAYLOAD_JSON_FILE}" -c | while read -r _RECORD; do
	((++_i))
	echo '####################################################################'
	echo -e "\e[1;49;34mPROCESS RECORD\e[0m: (${_i}/${_records_count}): $( echo "${_RECORD}" | jq '{ topic: .topic, key: .key, offset: .offset, tstype: .tstype, ts: .ts, ts__time__: ( if .ts then .ts / 1000 | strftime("%Y-%m-%dT%H:%M:%S %Z") else null end ), value_schema_id: .value_schema_id }' )"
	# @TODO naive approach, we parse only 1 value for the header. Potentially that may be array. Or absent at all
	 _headers=$(echo "${_RECORD}" | jq '( if .headers then .headers | to_entries | map("-H " + .key + "=\"" + .value[0] + "\"") | join(" ") else "" end)' -r) #'
	echo "RECORD.Headers: ${_headers}"
	_key=${KEY-$(echo "${_RECORD}" | jq -cr .key)}
	_schema_url_key=${AVRO_SCHEMA_URL_key-$(echo "${_RECORD}" | jq -cr ._schema_url_key)}
	_schema_url_value=${AVRO_SCHEMA_URL_key-$(echo "${_RECORD}" | jq -cr ._schema_url_value)}
	_topic=${TOPIC-$(echo "${_RECORD}" | jq -r .topic)}
	echo "RECORD.key: [${_key}]; _schema_url_key=${_schema_url_key=}; _schema_url_value=${_schema_url_value}"
	echo "TOPIC will be used: [${_topic}]; "

	# @TODO add caching and do not download/upload on each record!
	if [[ 'false' != "${AVRO_SCHEMA_key}" ]]; then
		downloadSchema "${_schema_url_key}" key
		[[ ${_schema_url_key} != $SCHEMA_REGISTRY* ]] && publishSchema "${_AVRO_SCHEMA_FILE[key]}" key
		encodeToAVRO key "${_key}"
	fi
	if [[ 'false' != "${AVRO_SCHEMA_value}" ]]; then
		downloadSchema "${_schema_url_value}" value
		[[ ${_schema_url_value} != $SCHEMA_REGISTRY* ]] && publishSchema "${_AVRO_SCHEMA_FILE[value]}" value
		encodeToAVRO value "$(echo "${_RECORD}" | jq '.payload // .')"
	fi

	cat "${_AVRO_ENCODED_DATA_FILE[key]}" > "${_TMP_DIR}/full.avro"
	echo -en ":" >> "${_TMP_DIR}/full.avro"
	cat "${_AVRO_ENCODED_DATA_FILE[value]}" >> "${_TMP_DIR}/full.avro"

	# NOTE, we use file in container! So, expected parameter CONTAINER_CACHE_EXTRA_OPTIONS_kafkacat=('-v.:/host')!
	# @TODO that is not work with stdin redirection and sourcing unfortunately!
	podman exec $(kafkacat_exec_cache) kafkacat \
		-b "${KAFKA_BOOTSTRAP_SERVERS}" "${KAFKACAT_SECURE_OPTIONS[@]}" -m30 \
			-P -e -t ${_topic} \
			-K: -D'\0' ${_headers} -l /host/.tmp/full.avro

	echo -e '\t\e[0;49;92m...SENT!\e[0m'
done
