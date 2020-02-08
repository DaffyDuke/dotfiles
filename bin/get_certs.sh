#!/bin/sh
# Source : https://gist.githubusercontent.com/petRUShka/af96ae25ce8280729b9ea049b929f31d/raw/a79471ce8aee3f6d04049039adf870a53a524f7f/get_certs.sh

SERVER=${1:-my.server.com}
PORT=${2:-993}
CERT_FOLDER=${3:-~/certs}

openssl s_client -connect ${SERVER}:${PORT} -showcerts 2>&1 < /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'| sed -ne '1,/-END CERTIFICATE-/p' > ${CERT_FOLDER}/${SERVER}.pem
