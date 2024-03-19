# Directory for store connectors configurations

Directory where the bunch of the AVRO schemas should be put (`*.avsc` files).
Several `_schema.*.sh` files looks they there by default.

One schema example present in file [example-schema.avsc].

# Examples of usages

    _schemas.list.sh
    SCHEMA=example-schema ./_schema.put.sh
    SCHEMA=example-schema _schema.list-versions.sh
    SCHEMA=example-schema ./_schema.get.sh
