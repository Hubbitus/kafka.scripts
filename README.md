# Kafka helper scripts

Various kafka-related scripts to easily inspect and manage the cluster, topics, consumer groups, etc.

## Usage

Just create [.config.sh]() file by example with said [.config-sandbox.sh](). It is recommentded use symlink to switch beetween configurations.

And then just call any script like:

	./_kafka.list-topics.sh

It will work with values from config, or provide details what needs to be provided additionally.