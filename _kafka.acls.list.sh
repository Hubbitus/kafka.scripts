#!/bin/bash

source "$(dirname $0)/.shared.sh"

source "$(dirname $0)/_kafka.acls.sh" --list "$@"
