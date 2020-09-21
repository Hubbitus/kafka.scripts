
# Exec much faster than run container each time. Container will be run and active 1h automatically
# $1 - name of contaiiner
# $2 - image
function container_exec_cache(){
	: ${1?"Not enough arguments passed: container_exec_cache <container_name> <image>"}
	: ${2?"Not enough arguments passed: container_exec_cache <container_name> <image>"}

	# grep -q required: https://github.com/moby/moby/issues/35057#issuecomment-333476596
	docker ps -q --filter "name=${1}" --filter status=running | grep -q . \
		|| (docker rm -vf "${1}" &>/dev/null || : ; docker run --rm -d --entrypoint sleep --name "$1" "$2" 1h > /dev/null )

	echo "$1"
}

function kafka_exec_cache(){
	container_exec_cache kafka-exec-cache docker.io/confluentinc/cp-kafka:5.5.1
}
function kafkacat_exec_cache(){
#	container_exec_cache kafkacat-exec-cache docker.io/confluentinc/cp-kafkacat:5.5.1
	container_exec_cache kafkacat-exec-cache docker.io/edenhill/kafkacat:1.6.0
}
