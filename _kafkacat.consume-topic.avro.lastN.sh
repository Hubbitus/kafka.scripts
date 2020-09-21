#!/usr/bin/bash

: ${TOPIC?"Not enough vars set: TOPIC required. F.e. to list last 10 (default, you may set N variable) messages::
TOPIC=topic1 [N=5] $0"}

: ${N:=10}

source "$(dirname $0)/_kafkacat.consume-topic.avro.sh" -Oe -o-$N -c$N "$@"
