#!/usr/bin/env python

import ssl
from confluent_kafka import KafkaProducer, SslConfig


context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
context.load_cert_chain(
    'certificate.pem',
    'RSAkey.pem'
)
context.load_verify_locations('cafile.pem')

producer = KafkaProducer(
    bootstrap_servers='kafaka1.host:19091,kafaka1.host:19092,kafaka1.host:19093',
    security_protocol='SSL',
    ssl_check_hostname=True,
    ssl_context=context,
    value_serializer=lambda m: json.dumps(m).encode('utf-8')
)

json_row = {"test": "ok"}
producer.send(TOPIC, json_row)
producer.flush()
producer.close()
print("Done")
