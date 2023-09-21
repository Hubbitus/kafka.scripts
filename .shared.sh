
[[ -e "$(dirname $0)/.config.global.sh" ]] && source "$(dirname $0)/.config.global.sh"

source "$(dirname $0)/.config.sh${ENV+.$ENV}"

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
		|| (podman rm -vf "${_name}" &>/dev/null || : ; podman run --rm -d --entrypoint sleep "$@" --name "${_name}" "${_image}" 1h > /dev/null )

	echo "${_name}"
}

function kafka_exec_cache(){
	container_exec_cache "cp-kafka-exec-cache-${ENV}" docker.io/confluentinc/cp-kafka:7.1.0 "${CONTAINER_CACHE_EXTRA_OPTIONS_confluent[@]}"
}
function kafkacat_exec_cache(){
	container_exec_cache "kafkacat-exec-cache-${ENV}" docker.io/hubbitus/kafkacat-sasl:20210622 "${CONTAINER_CACHE_EXTRA_OPTIONS_kafkacat[@]}"
}

function kafkactl_exec_cache(){
	container_exec_cache "kafkactl-exec-cache-${ENV}" docker.io/deviceinsight/kafkactl:v1.11.1 -v ~/.config/kafkactl/config.yml:/etc/kafkactl/config.yml
}

function JQ_common(){
jq ". |
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
	}" "$@"
}
