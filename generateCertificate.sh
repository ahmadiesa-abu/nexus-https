touch san.cnf
HOST_NAME=$(hostname)
HOST_IP=$(ip a s $(ip ro sho | grep default | awk '{ print $5 }') | grep 'inet ' | cut -d'/' -f1 | awk '{ print $2 }')

cat >> san.cnf <<EOF
[ req ]
prompt = no
distinguished_name = req_distinguished_name
x509_extensions = san_self_signed
[ req_distinguished_name ]
CN=$HOST_NAME
countryName                 = IL
stateOrProvinceName         = Hayifa
localityName               = Nablus
organizationName           = Home
[ san_self_signed ]
subjectAltName = DNS:localhost,DNS:127.0.0.1,DNS:$HOST_NAME,DNS:$HOST_IP,DNS:$1,DNS:$2,IP:$HOST_IP,IP:127.0.0.1,IP:$2
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = CA:true
keyUsage = nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment, keyCertSign, cRLSign
extendedKeyUsage = serverAuth, clientAuth, timeStamping
EOF

openssl req -newkey rsa:2048 -nodes -keyout  $1_key.pem -x509 -sha256 -days  10000 -config san.cnf -out $1_crt.pem
