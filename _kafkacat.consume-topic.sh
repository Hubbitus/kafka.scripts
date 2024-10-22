#!/usr/bin/bash

source "$(dirname $0)/.shared.sh"

function usage(){
cat <<EOF

E.g. to list last N (default 10) messages (with offsets -O) and exit:
TOPIC=topic1 $0 -Oe -o-10 -c10
See also _kafkacat.consume-topic.lastN.sh script for simplicity

TOPICS var may include several topics, or even regexp (e.g.: my-topic ^my-regex-.*-topic some-other-topic). Please see https://github.com/edenhill/kcat/issues/179.
Meantime please note:
1. That also require set variable CONSUMER_GROUP_ID
2. You must have access to became group member of provided group!
3. That will require some more time on startup to check access, join group and rebalance all consumers in it (up to several seconds).
So, it is not recommended use this mode without the reason. Please use just TOPIC!
EOF
exit 1
}

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}
[[ ! ${TOPIC-} && !( ${TOPICS} && ${CONSUMER_GROUP_ID} ) ]] && echo 'Not enough vars set: TOPIC or pair TOPICS+CONSUMER_GROUP_ID variables must be provided.' && usage

if [[ "${KAFKACAT_CONSUME_TOPIC_FORMAT}" ]]; then
	source "$(dirname $0)/_kafkacat.sh" \
		"${KAFKACAT_CONSUME_TOPIC_FORMAT}" \
		-u "$@" \
		${TOPIC+-C -t ${TOPIC}} ${TOPICS+-G ${CONSUMER_GROUP_ID} ${TOPICS}}
else
	source "$(dirname $0)/_kafkacat.sh" \
		-u "$@" \
			${TOPIC+-C -t ${TOPIC}} ${TOPICS+-G ${CONSUMER_GROUP_ID} ${TOPICS}}
fi
