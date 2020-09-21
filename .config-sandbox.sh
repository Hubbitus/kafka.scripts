set -ueo pipefail;

source "$(dirname $0)/_shared.sh"

alias docker=podman
shopt -s expand_aliases

: ${KAFKA_CONNECT_HOST:=localhost:8083}
: ${KAFKA_BOOTSTRAP_SERVERS:=PLAINTEXT://ecsc00a060af.epam.com:9092,PLAINTEXT://ecsc00a060b0.epam.com:9092,PLAINTEXT://ecsc00a060b1.epam.com:9092,PLAINTEXT://ecsc00a060b2.epam.com:9092,PLAINTEXT://ecsc00a060b3.epam.com:9092}

: ${SCHEMA_REGISTRY:=schema-registry-sbox.epm-eco.projects.epam.com:8081}

# Default connect to name:
: ${CONNECTOR:=s3-sync-test-01}
# Connector file to install
: ${CONNECTOR_FILE:=$(dirname $0)/../connectors/s3-sync-test.json}

# In ./_connect.status-connector.sh script provide info by *connector* or not. Set 'false' if it is not interesting
: ${CONNECTOR_STATUS_ITSELF:=true}
# In ./_connect.status-connector.sh script provide info by connector *tasks* or not. Set 'false' if it is not interesting
: ${CONNECTOR_STATUS_TASKS:=true}
