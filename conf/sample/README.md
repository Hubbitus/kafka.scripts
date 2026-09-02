
Symlinks provided with names common for the Python implementation:

```python
context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
context.load_cert_chain(
    '/home/pasha/@Projects/@DATA/kafka.scripts/conf/DEV/certificate.pem',
    '/home/pasha/@Projects/@DATA/kafka.scripts/conf/DEV/RSAkey.pem'
)
context.load_verify_locations('/home/pasha/@Projects/@DATA/kafka.scripts/conf/DEV/cafile.pem')

producer = KafkaProducer(
    bootstrap_servers='10.221.0.93:19090,10.221.0.93:19091,10.221.0.93:19092',
    security_protocol='SSL',
    ssl_check_hostname=True,
    ssl_context=context,
    value_serializer=lambda m: json.dumps(m).encode('utf-8')
)

json_row = {"test": "ok"}
producer.send(TOPIC, json_row)
producer.flush()
```

See also [utils/keystore.convert](../../utils/keystore.convert) script and its description
