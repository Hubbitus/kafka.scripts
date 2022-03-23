#!/bin/bash

# Delete multiple kafka topics.
# For filtering you may provide optional variable KAFKA_TOPICS_FILTER
# See ./_kafka.list-topics.sh script description and examples
source $(dirname $0)/.shared.sh

i=0

for TOPIC in $($(dirname $0)/_kafka.list-topics.sh); do
	echo "Deleting topic [$TOPIC]"
	TOPIC=${TOPIC} $(dirname $0)/_kafka.delete-topic.sh
	(( ++i ))
done
echo "Deleted $i topics"
