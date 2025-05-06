#!/bin/bash

# Script to list schema-registry SCHEMA available versions.
# Uasge: SCHEMA=dev__bonus_to_gid ./_schema.list.versions.sh

source "$(dirname $0)/.shared.sh"

: ${SCHEMA_REGISTRY?"Not enough vars set: SCHEMA_REGISTRY required"}
: ${SCHEMA?"Not enough vars set: SCHEMA required"}

http -pb ${SCHEMA_REGISTRY}/subjects/${SCHEMA}/versions
