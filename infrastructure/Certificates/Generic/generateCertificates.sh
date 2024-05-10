VALIDITY_IN_DAYS=3650

export COUNTRY=PT
export STATE=Porto
export ORGANIZATION_UNIT=Generic
export CITY=Maia
export PASSWORD=secret

COUNTRY=$COUNTRY
STATE=$STATE
OU=$ORGANIZATION_UNIT
CN="*.cmf.criticalmanufacturing.com"
LOCATION=$CITY
PASS=$PASSWORD

echo
echo "Create Root CA"
echo

echo
echo "1. Generate a key that will be used for the new CA"
echo
openssl genrsa -out root.key 2048

echo
echo "2. Generate a new self-signed CA certificate. The following will create a new certificate that will be used to sign other certificates using the CA key"
echo
openssl req -x509 -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$OU/CN=$CN" -new -key root.key -sha256 -days $VALIDITY_IN_DAYS -out root.crt

echo
echo "3. Generate server key and certificate"
echo
openssl genrsa -out server.key 2048
openssl req -new -sha256 -key server.key -out server.csr -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$OU/CN=$CN"
openssl x509 -req -days $VALIDITY_IN_DAYS -sha256 -CA root.crt -CAkey root.key -CAcreateserial -in server.csr -out server.crt

rm server.csr
rm root.key
rm root.srl
