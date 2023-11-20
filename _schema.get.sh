#!/usr/bin/bash

# Script to list schema-registry schemes subjects.

source "$(dirname $0)/.shared.sh"

: ${SCHEMA_REGISTRY?"Not enough vars set: SCHEMA_REGISTRY required"}
: ${SCHEMA?"Not enough vars set: SCHEMA required"}
: "${SCHEMA_SUBJECT_NAME:=${SCHEMA}-value}"
: "${SCHEMA_VERSION:=latest}"

set -x

http -pb GET ${SCHEMA_REGISTRY}/subjects/${SCHEMA_SUBJECT_NAME}/versions/${SCHEMA_VERSION}/schema
