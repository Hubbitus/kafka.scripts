# Kafka helper scripts

Various kafka-related scripts to easily inspect and manage the cluster, topics, consumer groups, etc.

## Requirements

Scripts in the repository assume you have installed next utilities:
* [curl](https://curl.se/)
* [httpie](https://github.com/httpie/cli)
* [jq](https://jqlang.github.io/jq/)
* [podman](https://podman.io/) (highly recommended, alrough `docker` also supported, please look at the end of the readme for configuration instructions).

Fore example on Fedora you may just install it like: `sudo dnf install curl httpie jq podman`

## Usage

Just create [.config.sh](.config.sh) file by example with said [.config-sandbox.sh](.config-sandbox.sh). It is recommended use symlink to switch beetween configurations.

And then just call any script like:

	./_kafkacat.list-topics.sh

It will work with values from config, or provide details what needs to be provided additionally.

For easy use different environments you may just follow configuration files naming conventions, described below and call it like:

	ENV=PROD ./_kafkacat.list-topics.sh
	ENV=SBOX ./_kafkacat.list-topics.sh

## Configuration

As recommended before, it is recommended place configs into separate directory `conf/<env>` (e.g. conf/production).

In the root directory of the repository assumed `.config.sh` default file, and optionally symlinks by environments like: `.config.sh.PROD`, `.config.sh.SBOX`...

### Main configuration file .config.sh

That should look like:
```shell
[ "$0" = "${BASH_SOURCE[0]}" ] && echo 'Config file must be sourced!' && exit 1

ENV=PROD

: ${KAFKA_BOOTSTRAP_SERVERS:=kafka.epm-eco.projects.example.com:9095}

: ${SCHEMA_REGISTRY:=http://schema-registry.epm-eco.projects.example.com:8081}

# -J for JSON. Or you may provide format as you wish
: ${KAFKACAT_CONSUME_TOPIC_FORMAT=-J}
#: ${KAFKACAT_CONSUME_TOPIC_FORMAT='-f --\nKey (%K bytes): %k\nValue (%S bytes): %s\n\Partition: %p\tOffset: %o\nHeaders: %h\n'}
# Without value itself:
#: ${KAFKACAT_CONSUME_TOPIC_FORMAT='-f --\nKey (%K bytes): %k\t\nValue %S bytes\n\Partition: %p\tOffset: %o\nHeaders: %h\n'}

_conf_dir=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

CONTAINER_CACHE_EXTRA_OPTIONS_kafkacat=('-v.:/host' "-v${_conf_dir}:/conf:Z,ro" "-v${_conf_dir}/krb5.conf:/etc/krb5.conf:Z,ro")
# Note! For Kerberos auth you need also configure
CONTAINER_CACHE_EXTRA_OPTIONS_confluent=('--network=host' '-v.:/host' "-v${_conf_dir}:/conf:Z,ro" "-v${_conf_dir}/krb5.conf:/etc/krb5.conf:Z,ro" '--env=KAFKA_HEAP_OPTS=-Xmx4096M' '--env=KAFKA_OPTS=-Djava.security.auth.login.config=/conf/jaas.conf -Djava.security.krb5.conf=/etc/krb5.conf')

: ${KERBEROS_USER:=Pavel_Alexeev@EXAMPLE.COM}
: ${KERBEROS_KEYTAB_FILE:="conf/${ENV}/${KERBEROS_USER}.keytab"}

# In command below we mount /conf for holds certificates and keystores. File paswd also must contain password for kerberos account,
# provided in sasl.kerberos.kinit.cmd line. Please be careful and NEVER commit sensitive information into git!!!
KAFKACAT_SECURE_OPTIONS=(
	'-Xssl.ca.location=/conf/epm-eco-prod.ca.crt'
	'-Xsecurity.protocol=SASL_SSL'
	'-Xsasl.mechanisms=GSSAPI'
	'-Xsasl.kerberos.principal=kafkaclient'
	"-Xsasl.kerberos.kinit.cmd=/usr/bin/kinit --password-file=/conf/paswd ${KERBEROS_USER}"
	# OR keytab based variant (see script keytab.regenerate for generation):
#	"-Xsasl.kerberos.kinit.cmd=/usr/bin/kinit -kt /conf/${KERBEROS_USER}.keytab ${KERBEROS_USER}"
)

# In command below we mount /conf for holds certificates and keystores.
# provided in sasl.kerberos.kinit.cmd line. Please be careful and NEVER commit sensitive information into git!!!
# '-Xsasl.kerberos.kinit.cmd=/usr/bin/kinit --password-file=/conf/paswd Pavel_Alexeev@PETERSBURG.EXAMPLE.COM'
# You may obtain keytab file like (by https://stackoverflow.com/questions/8144596/kerberos-kinit-enter-password-without-prompt/8282084#8282084, https://stackoverflow.com/questions/37454308/script-kerberos-ktutil-to-make-keytabs):
# See script keytab.regenerate for that!
KAFKACAT_SECURE_OPTIONS=(
	'-Xssl.ca.location=/conf/epm-eco-int.ca.crt'
	'-Xsecurity.protocol=SASL_SSL'
	'-Xsasl.mechanisms=GSSAPI'
	'-Xsasl.kerberos.principal=kafkaclient'
)

: ${KAFKA_CONNECT_HOST:=localhost:8083}

: ${KSQLDB_SERVER:=http://localhost:8088}

CONSUMER_GROUP_ID=epm-ddo.consumer.$(hostname).$(date --iso-8601=s)
```

### Typical additional files for the kafkacat-based utilities

Please note, for use with Kerberos you probably will need several configuration files also:

1. Server CA certificate 'server.ca.crt'
2. `conf/<env>/paswd` with password to the AD account, configured for usage in `.config.sh`.
   > **Warning** Such password never should be committed into the GIT! And that is ignored in the repository (please pay attention also to the `error` naming)
3. Instead of providing plain text password in the file, as described before, you may also use `keytab` based auth. See configuration alternatives before and script [keytab.regenerate](keytab.regenerate)
4. `krb5.conf` file. As example:
   ```
   # By https://kb.example.com/display/EPMECOSYS/Pub-Sub+Clients
   [libdefaults]
       default_realm = EXAMPLE.COM
       dns_canonicalize_hostname = false
       rdns = false

   #    dns_lookup_realm = true
   #    dns_lookup_kdc = true
   dns_lookup_realm = false
   dns_lookup_kdc = false
   [realms]
   #    EXAMPLE.COM = {
   #      kdc = example.com:88
   #      admin_server = example.com
   #      default_domain = example.com
   #    }
   EXAMPLE.COM = {
          kdc = EVBYMINSA0016.example.com
          kdc = EVBYMINSA0084.example.com
          kdc = EVBYMINSA0018.example.com
          admin_server = EVBYMINSA0016.example.com
       }
       PETERSBURG.EXAMPLE.COM = {
          kdc = evbyminsa0007.petersburg.example.com.
          kdc = evhubudsa0309.budapest.example.com.
          admin_server = evbyminsa0007.petersburg.example.com.
       }
   [domain_realm]
      .example.com = EXAMPLE.COM
       example.com = EXAMPLE.COM
   [login]
       krb4_convert = true
       krb4_get_tickets = false
   ```

### Typical additional files for the confluent-based utilities (kafka-acls, kafka-configs and others)

1. Client configuration like `kafka-client.properties`
2. Truststore, possibly with configures password (e.g. `server-prod.truststore`)
3. `jaas.conf` - java [JAAS Login Configuration File](https://docs.oracle.com/javase/7/docs/technotes/guides/security/jgss/tutorials/LoginConfigFile.html).

### If you would like to use docker instead of podman

If you really want to use docker instead of podman (I've not reccommend), please run first:

cat <<CONF > .config.global.sh
alias podman=docker
shopt -s expand_aliases
CONF
