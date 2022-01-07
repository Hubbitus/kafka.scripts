#!/bin/bash

source "$(dirname $0)/.config.sh"

source "$(dirname $0)/_kafka.acls.sh" --list "$@"
