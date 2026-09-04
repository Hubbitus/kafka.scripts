#!/usr/bin/bash
#
# Fetch TLS cert chain from a server (Kafka broker, HTTPS host, etc.),
# extract the root CA, and build a JKS truststore that contains it.
#
# Usage:
#   truststore-from-server.sh <host:port> <out-dir> [alias] [storepass]
#
# Example:
#   utils/truststore-from-server.sh 127.0.0.1:9096 conf/PROD fsk-ca 6Q5Z7NIC7mvt3d8+QmT8eA
#   utils/truststore-from-server.sh kafka-1.k8s-test.fsk.ru:9094 conf/TEST
#
# Result file (in <out-dir>):
#   truststore.jks       - JKS/PKCS12 truststore with the root CA imported
#
# Intermediate files (fetched chain, extracted CA PEM) are written to a temp dir
# and removed on exit. Pass --keep-intermediate as 5th arg to retain them in <out-dir>.
#
# Notes:
#   * The script assumes the LAST certificate in the chain is the root CA (self-signed).
#     This matches typical Kafka broker responses at FSK (server cert + FSK CA root).
#   * If the server does not send the root itself, this script will import whatever the
#     last returned cert is - verify with `keytool -list` afterwards.

set -euo pipefail

usage() {
    echo "Usage: $0 <host:port> <out-dir> <storepass> [alias] [--keep-intermediate]" >&2
    exit 1
}

[[ $# -ge 3 ]] || usage

HOST_PORT="$1"
OUT_DIR="$2"
STOREPASS="$3"
ALIAS="${4:-server-ca}"
KEEP="${5:-}"

HOST="${HOST_PORT%:*}"
PORT="${HOST_PORT##*:}"

mkdir -p "${OUT_DIR}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

CHAIN="${TMP_DIR}/server-chain.pem"
CA="${TMP_DIR}/ca.crt"
JKS="${OUT_DIR}/truststore.jks"

echo ">> Fetching TLS chain from ${HOST}:${PORT} ..."
openssl s_client -connect "${HOST}:${PORT}" -servername "${HOST}" -showcerts </dev/null 2>/dev/null \
    | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' > "${CHAIN}"

CERT_COUNT=$(grep -c 'BEGIN CERTIFICATE' "${CHAIN}" || true)
if [[ "${CERT_COUNT}" -lt 1 ]]; then
    echo "!! No certificates returned by ${HOST}:${PORT}" >&2
    exit 1
fi
echo "   chain contains ${CERT_COUNT} cert(s) -> ${CHAIN}"

echo ">> Extracting last cert (assumed root CA) -> ${CA}"
awk '/BEGIN CERTIFICATE/{c=""} {c=c$0"\n"} /END CERTIFICATE/{last=c} END{printf "%s", last}' \
    "${CHAIN}" > "${CA}"

echo ">> Root CA details:"
openssl x509 -in "${CA}" -noout -subject -issuer -dates -fingerprint -sha256 | sed 's/^/     /'

if [[ -f "${JKS}" ]]; then
    echo ">> Removing existing ${JKS}"
    rm -f "${JKS}"
fi

echo ">> Importing CA into ${JKS} (alias=${ALIAS})"
keytool -importcert -trustcacerts -noprompt \
    -alias "${ALIAS}" \
    -file "${CA}" \
    -keystore "${JKS}" \
    -storepass "${STOREPASS}"

echo ">> Truststore contents:"
keytool -list -keystore "${JKS}" -storepass "${STOREPASS}" | tail -n +3 | sed 's/^/     /'

if [[ "${KEEP}" == "--keep-intermediate" ]]; then
    cp "${CHAIN}" "${CA}" "${OUT_DIR}/"
    echo ">> Kept intermediate files in ${OUT_DIR}: server-chain.pem, ca.crt"
fi

echo ">> Done: ${JKS}"
