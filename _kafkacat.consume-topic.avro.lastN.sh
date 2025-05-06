#!/bin/bash

: ${N:=10}

source "$(dirname $0)/_kafkacat.consume-topic.avro.sh" -Oe -o-$N -c$N "$@"
