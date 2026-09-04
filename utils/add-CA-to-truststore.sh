#!/usr/bin/bash

# Delete old, if needed:
#keytool -delete -alias kafka-test-ca -keystore conf/TEST/truststore.jks -storepass 6Q5Z7NIC7mvt3d8+QmT8eA

PASSWORD="${1:?Usage: $0 storepass}"

keytool -importcert -trustcacerts -noprompt \
    -alias fsk-ca \
    -file ../../.tmp/fsk-ca.crt \
    -keystore truststore.jks \
    -storepass "${PASSWORD}"
