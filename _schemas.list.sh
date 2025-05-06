#!/bin/bash

# Script to list schema-registry schemes subjects.

source "$(dirname $0)/.shared.sh"

: ${SCHEMA_REGISTRY?"Not enough vars set: SCHEMA_REGISTRY required"}

http -pb ${SCHEMA_REGISTRY}/subjects | jq -r '.[]'
