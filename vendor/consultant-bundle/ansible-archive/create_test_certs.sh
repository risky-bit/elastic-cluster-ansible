TARGET_FOLDER="certs"
CA_KEY_PATH="${TARGET_FOLDER}/ca.key"
CA_CRT_PATH="${TARGET_FOLDER}/ca.crt"
ES_KEY_PATH="${TARGET_FOLDER}/es.key"
ES_CSR_PATH="${TARGET_FOLDER}/es.csr"
ES_CRT_PATH="${TARGET_FOLDER}/es.crt"
ES_CNF_PATH="${TARGET_FOLDER}/es.cnf"
P12_PATH="${TARGET_FOLDER}/certfile.p12"

openssl genrsa -out $CA_KEY_PATH 4096
chmod 600 $CA_KEY_PATH
openssl req -x509 -new -sha256 \
    -key $CA_KEY_PATH \
    -days 3650 \
    -out $CA_CRT_PATH \
    -subj "/C=QA/O=Nvt/OU=TEST/CN=Elastic-Internal-CA"

openssl genrsa -out $ES_KEY_PATH 4096
chmod 600 $ES_KEY_PATH
openssl req -new -key $ES_KEY_PATH -out $ES_CSR_PATH -config $ES_CNF_PATH
openssl x509 -req \
    -in $ES_CSR_PATH \
    -CA $CA_CRT_PATH \
    -CAkey $CA_KEY_PATH \
    -CAcreateserial \
    -out $ES_CRT_PATH \
    -days 825 \
    -sha256 \
    -extensions req_ext \
    -extfile $ES_CNF_PATH
openssl pkcs12 -export \
    -in $ES_CRT_PATH \
    -inkey $ES_KEY_PATH \
    -certfile $CA_CRT_PATH \
    -out $P12_PATH \
    -name certfile

#openssl pkcs12 -info -in $P12_PATH


