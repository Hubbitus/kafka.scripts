
source "$(dirname $0)/.config.sh${ENV+.$ENV}"

# Exec much faster than run container each time. Container will be run and active 1h automatically
# $1 - name of contaiiner
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
		|| (podman rm -vf "${_name}" &>/dev/null || : ; podman run --rm -d --entrypoint sleep "$@" --name "${_name}" "${CONTAINER_CACHE_EXTRA_OPTIONS[@]}" "${_image}" 1h > /dev/null )

	echo "${_name}"
}

function kafka_exec_cache(){
	container_exec_cache kafka-exec-cache docker.io/confluentinc/cp-kafka:5.5.1
}
function kafkacat_exec_cache(){
	container_exec_cache ${KAFKACAT_EXEC_CACHE_NAME-'kafkacat-exec-cache'} docker.io/hubbitus/kafkacat-sasl:20210622
}

function kafkactl_exec_cache(){
	container_exec_cache kafkactl-exec-cache docker.io/deviceinsight/kafkactl:v1.11.1 -v ~/.config/kafkactl/config.yml:/etc/kafkactl/config.yml
}
