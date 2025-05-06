#!/bin/bash

# Script to put new schema (version) to schema-registry.

source "$(dirname $0)/.shared.sh"

: ${SCHEMA_REGISTRY?"Not enough vars set: SCHEMA_REGISTRY required"}
: ${SCHEMA?"Not enough vars set: SCHEMA required"}
: "${SCHEMA_AVSC_FILE:=$(dirname $0)/_schemas/${SCHEMA}.avsc}"
: "${SCHEMA_SUBJECT_NAME:=${SCHEMA}-value}"

echo SCHEMA_AVSC_FILE=${SCHEMA_AVSC_FILE}

if [[ ! -e "${SCHEMA_AVSC_FILE}" ]]; then
	echo "Schema AVSC file [${SCHEMA_AVSC_FILE}] does not exists! Please place it there, or provide alternative path in SCHEMA_AVSC_FILE variable"
	exit 1
fi

set -x

echo "{\"schemaType\": \"AVRO\",\"schema\": $( jq '. | tojson' ${SCHEMA_AVSC_FILE} )}" \
	| http -pb POST ${SCHEMA_REGISTRY}/subjects/${SCHEMA_SUBJECT_NAME}/versions \
		| jq .id
