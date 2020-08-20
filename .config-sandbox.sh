set -ueo pipefail;

alias docker=podman
shopt -s expand_aliases

: ${KAFKA_CONNECT_HOST:=localhost:8083}
: ${KAFKA_BOOTSTRAP_SERVERS:=PLAINTEXT://ecsc00a060af.epam.com:9092,PLAINTEXT://ecsc00a060b0.epam.com:9092,PLAINTEXT://ecsc00a060b1.epam.com:9092,PLAINTEXT://ecsc00a060b2.epam.com:9092,PLAINTEXT://ecsc00a060b3.epam.com:9092}

# Default connect to name:
: ${CONNECTOR:=s3-sync-test-01}
# Connector file to install
: ${CONNECTOR_FILE:=$(dirname $0)/../connectors/s3-sync-test.json}

# In ./_connect.status-connector.sh script provide info by *connector* or not. Set 'false' if it is not interesting
: ${CONNECTOR_STATUS_ITSELF:=true}
# In ./_connect.status-connector.sh script provide info by connector *tasks* or not. Set 'false' if it is not interesting
: ${CONNECTOR_STATUS_TASKS:=true}



# Exec much faster than run container each time. Container will be run and active 1h automatically
# $1 - name of contaiiner
# $2 - image
function container_exec_cache(){
	: ${1?"Not enough arguments passed: container_exec_cache <container_name> <image>"}
	: ${2?"Not enough arguments passed: container_exec_cache <container_name> <image>"}

	# grep -q required: https://github.com/moby/moby/issues/35057#issuecomment-333476596
	docker ps -q --filter "name=${1}" --filter status=running | grep -q . \
		|| (docker rm -vf "${1}" &>/dev/null || : ; docker run --rm -d --name "$1" "$2" sleep 1h)

	echo "$1"
}

function kafka_exec_cache(){
	container_exec_cache kafka-exec-cache docker.io/confluentinc/cp-kafka
}
function kafkacat_exec_cache(){
	container_exec_cache kafkacat-exec-cache docker.io/confluentinc/cp-kafkacat
}
