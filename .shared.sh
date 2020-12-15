
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
	docker ps -q --filter "name=${_name}" --filter status=running | grep -q . \
		|| (docker rm -vf "${_name}" &>/dev/null || : ; docker run --rm -d --entrypoint sleep "$@" --name "${_name}" "${_image}" 1h > /dev/null )

	echo "${_name}"
}

function kafka_exec_cache(){
	container_exec_cache kafka-exec-cache docker.io/confluentinc/cp-kafka:5.5.1
}
function kafkacat_exec_cache(){
#	container_exec_cache kafkacat-exec-cache docker.io/confluentinc/cp-kafkacat:5.5.1
	container_exec_cache kafkacat-exec-cache docker.io/edenhill/kafkacat:1.6.0
}

function kafkactl_exec_cache(){
	container_exec_cache kafkactl-exec-cache docker.io/deviceinsight/kafkactl:v1.11.1 -v ~/.config/kafkactl/config.yml:/etc/kafkactl/config.yml
}