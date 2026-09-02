#!/usr/bin/env python

import json
import os
import sys
from confluent_kafka import Consumer

TOPIC = os.environ.get('TOPIC', 'marketplace.dwh.application')

conf = {
    'bootstrap.servers': os.environ['KAFKA_BOOTSTRAP_SERVERS'],
    'security.protocol': 'SASL_SSL',
    'sasl.mechanism': 'SCRAM-SHA-512',
    'sasl.username': os.environ['SASL_USERNAME'],
    'sasl.password': os.environ['SASL_PASSWORD'],
    'ssl.ca.location': os.environ.get('SSL_CA_LOCATION', 'truststore.cer.pem'),
    'ssl.endpoint.identification.algorithm': 'none',
    'group.id': os.environ.get('GROUP_ID', 'sample-consumer-group'),
    'auto.offset.reset': 'earliest',
    'enable.auto.commit': True,
    'enable.auto.offset.store': False
}

consumer = Consumer(conf)
consumer.subscribe([TOPIC])

try:
    while True:
        msg = consumer.poll(timeout=5.0)
        if msg is None:
            continue
        if msg.error():
            print(f"ERROR: {msg.error()}", file=sys.stderr)
            continue
        try:
            value = json.loads(msg.value().decode('utf-8'))
        except (ValueError, UnicodeDecodeError):
            value = msg.value()
        print(f"{msg.topic()}[{msg.partition()}]@{msg.offset()} key={msg.key()} value={value}")
except KeyboardInterrupt:
    pass
finally:
    consumer.close()
    print("Done")
