#!/bin/bash
#
# Display OCSP response.
#
# VERSION       :2.2.1
# DATE          :2016-06-19
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install openssl
# UPSTREAM      :https://github.com/matteocorti/check_ssl_cert
# LOCATION      :/usr/local/bin/ocsp-check.sh

HOST="$1"

set -e

Onexit() {
    local -i RET="$1"
    local BASH_CMD="$2"

    set +e

    # Cleanup
    rm -f "$CERTIFICATE" "$CA_ISSUER_CERT" &> /dev/null

    if [ "$RET" -ne 0 ]; then
        echo "COMMAND WITH ERROR: ${BASH_CMD}" 1>&2
    fi

    exit "$RET"
}

trap 'Onexit "$?" "$BASH_COMMAND"' EXIT HUP INT QUIT PIPE TERM

[ -n "$HOST" ]

CERTIFICATE="$(mktemp -t "${0##*/}.XXXXXXXX")"
CA_ISSUER_CERT="$(mktemp -t "${0##*/}.XXXXXXXX")"

# Get certificate
openssl s_client -connect "${HOST}:443" -servername "$HOST" < /dev/null > "$CERTIFICATE" 2> /dev/null

OCSP_URI="$(openssl x509 -in "$CERTIFICATE" -noout -ocsp_uri)"
[ -n "$OCSP_URI" ]

OCSP_HOST="$(sed -e 's;^.*//\([^/]\+\)\(/.*\)\?$;\1;' <<< "$OCSP_URI")"
[ -n "$OCSP_HOST" ]

CA_ISSUER_CERT_URI="$(openssl x509 -in "${CERTIFICATE}" -text -noout \
    | sed -n -e '/^\s*Authority Information Access:\s*$/,/^\s*$/s/^\s*CA Issuers - URI:\(.\+\)$/\1/p')"
[ -n "$CA_ISSUER_CERT_URI" ]

# Download issuer certificate
wget -q -t 1 -O "$CA_ISSUER_CERT" "$CA_ISSUER_CERT_URI"
if openssl x509 -inform DER -in "$CA_ISSUER_CERT" -noout 2> /dev/null; then
    # FIXME Input and output files are the same
    openssl x509 -inform DER -in "$CA_ISSUER_CERT" -outform PEM -out "$CA_ISSUER_CERT"
fi
openssl x509 -inform PEM -in "$CA_ISSUER_CERT" -noout

# Get OCSP response
OCSP_RESPONSE="$(openssl ocsp -no_nonce -timeout 10 -CAfile "$CA_ISSUER_CERT" -issuer "$CA_ISSUER_CERT" \
    -url "$OCSP_URI" -header "Host" "$OCSP_HOST" -cert "$CERTIFICATE" 2>&1)"
if ! grep -qFx "Response verify OK" <<< "$OCSP_RESPONSE"; then
    echo "Invalid OCSP response" 1>&2
    exit 101
fi
if ! grep -qFx "${CERTIFICATE}: good" <<< "$OCSP_RESPONSE"; then
    echo "Certificate is revoked" 1>&2
    exit 102
fi

THIS_UPDATE="$(sed -n -e '0,/^\s*This Update: \(.\+\)$/s//\1/p' <<< "$OCSP_RESPONSE")"
NEXT_UPDATE="$(sed -n -e '0,/^\s*Next Update: \(.\+\)$/s//\1/p' <<< "$OCSP_RESPONSE")"
declare -i THIS_UPDATE_SECOND="$(date --date "$THIS_UPDATE" "+%s")"
declare -i NEXT_UPDATE_SECOND="$(date --date "$NEXT_UPDATE" "+%s")"

# Check expiry
[ "$NEXT_UPDATE_SECOND" -ge "$(date "+%s")" ]

# Check expiration time
declare -i OCSP_HOURS="$(( ( NEXT_UPDATE_SECOND - THIS_UPDATE_SECOND ) / 3600 ))"
[ "$OCSP_HOURS" -ge 24 ]
[ "$OCSP_HOURS" -le 240 ]

echo "${HOST} OCSP period: ${OCSP_HOURS} hours"

exit 0
