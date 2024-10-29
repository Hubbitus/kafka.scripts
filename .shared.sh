#!/usr/bin/bash

[[ -e "$(dirname $0)/.config.global.sh" ]] && source "$(dirname $0)/.config.global.sh"

# Default env name, if not set is parent dir name:
function infer_ENV(){
	: ${ENV:=$(basename $(dirname $(realpath ${BASH_SOURCE[1]})))}
	export ENV
}

source "$(dirname ${BASH_SOURCE[0]})/.config.sh${ENV+.$ENV}"

: ${ENV?"Not enough vars set: Each config should define ENV variable, naming environment"}

set -eo pipefail

# Exec much faster than run container each time. Container will be run and active 1h automatically
# $1 - name of container
# $2 - image
# "@" all other args passed as is to container run.
function container_exec_cache(){
	: ${1?"Not enough arguments passed: container_exec_cache <container_name> <image>"}
	: ${2?"Not enough arguments passed: container_exec_cache <container_name> <image>"}

	local _name="$1"
	local _image="$2"
	shift;shift

	# grep -q required: https://github.com/moby/moby/issues/35057#issuecomment-333476596
	podman ps -q --filter "name=${_name}" --filter status=running | grep -q . \
		|| (podman rm -vf "${_name}" &>/dev/null || : ; podman run --rm -d --entrypoint sleep "$@" --name "${_name}" "${_image}" 1h > /dev/null)

	echo "${_name}"
}

function kafka_exec_cache(){
	container_exec_cache "cp-kafka-exec-cache-${ENV}" docker.io/confluentinc/cp-kafka:7.1.0 "${CONTAINER_CACHE_EXTRA_OPTIONS_confluent[@]}"
}
function kafkacat_exec_cache(){
	# SALS+Kerberros tested version (see https://github.com/Hubbitus/kafkacat repositore readme for the more details):
	# container_exec_cache "kafkacat-exec-cache-${ENV}" docker.io/hubbitus/kafkacat-sasl:20210622 "${CONTAINER_CACHE_EXTRA_OPTIONS_kafkacat[@]}"
	# echo kafkacat

	container_exec_cache "kafkacat-exec-cache-${ENV}" docker.io/hubbitus/kafkacat-sasl:20240324 "${CONTAINER_CACHE_EXTRA_OPTIONS_kafkacat[@]}"
#	container_exec_cache "kafkacat-exec-cache-${ENV}" docker.io/edenhill/kcat:1.7.1 "${CONTAINER_CACHE_EXTRA_OPTIONS_kafkacat[@]}"
	echo kcat
}

function kafkactl_exec_cache(){
	container_exec_cache "kafkactl-exec-cache-${ENV}" docker.io/deviceinsight/kafkactl:v1.11.1 -v ~/.config/kafkactl/config.yml:/etc/kafkactl/config.yml
}

# Most common JQ formatting with payload
function JQ(){
	jq --unbuffered ${JQ_OPTIONS} ". |
	{
		topic: .topic,
		key: .key,
		partition: .partition,
		offset: .offset,
		tstype: .tstype,
		ts: .ts,
		_ts_time: ( if .ts then .ts / 1000 | strftime(\"%Y-%m-%dT%H:%M:%S %Z\") else null end ),
		payload: .payload
	}
	+ if .value_schema_id then { \"_schema_url_value\": (\"${SCHEMA_REGISTRY}/schemas/ids/\" + (.value_schema_id|tostring)) } else null end
	+ if .key_schema_id then { \"_schema_url_key\": (\"${SCHEMA_REGISTRY}/schemas/ids/\" + (.key_schema_id|tostring)) } else null end
	${JQ_ADDON}" "$@"
}

# Common JQ extractor and formatter, with CDM headers (without payload)
function JQ_common(){
	jq --unbuffered ${JQ_OPTIONS} ". |
	{
		key: .key,
		partition: .partition,
		offset: .offset,
		tstype: .tstype,
		ts: .ts,
		_ts_time: ( if .ts then .ts / 1000 | strftime(\"%Y-%m-%dT%H:%M:%S %Z\") else null end ),
		_schema_url: (\"${SCHEMA_REGISTRY}/schemas/ids/\" + (.value_schema_id|tostring)),
		\"headers[cdm.type_metadata.type][0]\": getpath([\"headers\", \"cdm.type_metadata.type\", 0]),
		\"headers[datahub-transform-processor.payload-schema-subject][0]\": getpath([\"headers\", \"datahub-transform-processor.payload-schema-subject\", 0]),
		\"headers[cdm.type_metadata.source][0]\": getpath([\"headers\", \"cdm.type_metadata.source\", 0])
	} ${JQ_ADDON}" "$@"
}

function JSON_compact(){
	# For coloring options you may select themes: pygmentize -L styles --json
	# For the PYGMENTIZE_STYLE option see script .shared.list-color-styles and .shared.list-color-styles.styles.example as output
	# For JSON compact options good playground of options: https://j-brooke.github.io/FracturedJson/
	JQ_OPTIONS=-c JQ \
		| while read -r _json; do compact-json <( echo "${_json}" ) --max-inline-length ${COMPACT_JSON_LINE_LENGTH-1250} --max-compact-list-complexity 7 --no-ensure-ascii | pygmentize -O style=${PYGMENTIZE_STYLE-friendly}; done

#		| while read -r _json; do underscore --wrapwidth $(tput cols) pretty -d "$_json" "$@" ; done
}

function JSON_compact_JSON_payload(){
	JQ_ADDON="| del(.payload) + { payload: (.payload | fromjson) }${JQ_ADDON}" JSON_compact
}

function JQ_track_event(){
	JQ_ADDON=$(cat <<- END
		| del(.payload) + { payload: (.payload | fromjson) }
		| . += { "meta": {
				"userId": .payload.body.userId,
				"accoutId": (.payload.body.userId | sub("\\\[|\\\]"; "") | split(",")[0]),
				"timestamp": .payload.body.timestamp
				}
			}
		| . += { "event": {
				"type": .payload.body.type,
				"eventName": .payload.body.event,
				"properties": .payload.body.properties,
				}
			}
		| del(.topic, .key, .offset, .payload, .partition, .tstype, .ts)
		${JQ_ADDON}
END
	)
 JQ
}