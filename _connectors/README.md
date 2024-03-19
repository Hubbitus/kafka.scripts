# Directory for store connectors configurations

Directory where the bunch of the `_kafka-connect*.sh` scripts will automatically search connector's configuration files.

One connector example present in file [example-connector.config.json]

# Examples of usage

> ***Note*** Be awayre of naming convention: _connectors/example-connector.config.json in most cases will be reffered as `CONNECTOR=example-connector`

## Mass operations

    ./_kafka-connect.connectors.pause-all.sh
    ./_kafka-connect.list-connectors.restart-all.sh
    ./_kafka-connect.list-connectors.status.sh | jq '."source.gid.api.db.api"'

## Start, restart, pause, create, delete, etc

    CONNECTOR=example-connector ./_kafka-connect.connector.put.sh
    CONNECTOR=example-connector ./_kafka-connect.connector.status.sh
    CONNECTOR=example-connector ./_kafka-connect.connector.delete.sh

    CONNECTOR=example-connector ./_kafka-connect.connector.pause.sh
    CONNECTOR=example-connector ./_kafka-connect.connector.status.sh
    CONNECTOR=example-connector ./_kafka-connect.connector.resume.sh

### Reinstall

Single command to dump configuration of the connector, delete it, re-create, wait and provide status:

    CONNECTOR=example-connector.config ./_kafka-connect.connector.reinstall.sh

Beneficial for testing and developing purposes.

## Connectors runtime logging configuration

    LOGGER=ROOT                             LEVEL=WARN  ./_kafka-connect.admin.logger.put.sh
    LOGGER=io.confluent.connect.jdbc        LEVEL=TRACE ./_kafka-connect.admin.logger.put.sh
    LOGGER=io.confluent.connect             LEVEL=WARN  ./_kafka-connect.admin.logger.put.sh
    LOGGER=io.debezium.connector.postgresql LEVEL=WARN  ./_kafka-connect.admin.logger.put.sh

## Reset offset of consumer offset

Often you need to reset consumer offset, but that will require delete connectors, reset offsets and then recrate it... May be troublesome. But you may just doing:

    CONNECTOR=example-connector ./_kafka-connect.connector.delete.sh
    KAFKA_CONSUMER_GROUP=connect-example-connector TOPIC=example-connector ./_kafka.consumer-group.reset-offset.sh
    CONNECTOR=example-connector ./_kafka-connect.connector.put.sh
    # To check:
    KAFKA_CONSUMER_GROUP=connect-example-connector ./_kafka.consumer-group.describe.sh
