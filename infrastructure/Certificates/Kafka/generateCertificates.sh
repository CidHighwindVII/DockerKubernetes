VALIDITY_IN_DAYS=3650

export COUNTRY=PT
export STATE=Porto
export ORGANIZATION_UNIT=Clickhouse
export CITY=Maia
export PASSWORD=secret

COUNTRY=$COUNTRY
STATE=$STATE
OU=$ORGANIZATION_UNIT
CN="*.cmf.criticalmanufacturing.com"
LOCATION=$CITY
PASS=$PASSWORD

echo 
echo "Cleanup before generation"
echo 
keytool -delete -keystore kafka.keystore.jks -alias localhost -storepass $PASS
keytool -delete -keystore kafka.keystore.jks -alias caroot -storepass $PASS
keytool -delete -keystore kafka.truststore.jks -alias caroot -storepass $PASS

echo
echo "Create Root CA"
echo

echo
echo "1. Generate a private key named root.key"
echo
openssl genrsa -out root.key

echo
echo "2. Generating a self-signed root CA named root.crt"
echo
openssl req -new -x509 -key root.key -out root.crt -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$OU/CN=$CN"

echo
echo "Create the Truststore and Keystore"
echo

echo
echo "1. Create a truststore file for all of the Kafka brokers"
echo
keytool -keystore kafka.truststore.jks -alias CARoot -import -file root.crt -noprompt \
 -dname "C=$COUNTRY, ST=$STATE, L=$LOCATION, O=$OU, CN=$CN" -keypass $PASS -storepass $PASS

echo
echo "2. Create a keystore file for the Kafka broker named kafka"
echo
keytool -keystore kafka.keystore.jks -alias localhost -validity $VALIDITY_IN_DAYS -dname "C=$COUNTRY, ST=$STATE, L=$LOCATION, O=$OU, CN=$CN" \
 -genkey -keyalg RSA -ext SAN=DNS:kafka.cmf.criticalmanufacturing.com -noprompt -keypass $PASS -storepass $PASS

echo
echo "3. Export the Kafka broker's certificate so it can be signed by the root CA."
echo
keytool -keystore kafka.keystore.jks -alias localhost -certreq -file kafka.unsigned.crt -noprompt -keypass $PASS -storepass $PASS

echo
echo "4. Sign the Kafka broker's certificate using the root CA."
echo
openssl x509 -req -CA root.crt -CAkey root.key -in kafka.unsigned.crt -out kafka.signed.crt -days $VALIDITY_IN_DAYS -CAcreateserial

echo
echo "5. Import the root CA into the broker's keystore."
echo
keytool -keystore kafka.keystore.jks -alias CARoot -import -file root.crt -noprompt -keypass $PASS -storepass $PASS

echo
echo "6. Import the signed Kafka broker certificate into the keystore."
echo
keytool -keystore kafka.keystore.jks -alias localhost -import -file kafka.signed.crt -noprompt -keypass $PASS -storepass $PASS

echo
echo "Create client certificate"
echo

echo
echo "1. Create a private key / public key certificate pair for the client"
echo 
openssl req -newkey rsa:2048 -nodes -keyout client.key -out client.csr \
 -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$OU/CN=$CN"

echo
echo "2. Now you have the CSR, you can generate a CA signed certificate as follows"
echo 
openssl x509 -req -CA root.crt -CAkey root.key -in client.csr -out client.crt -days $VALIDITY_IN_DAYS -CAcreateserial

rm kafka.signed.crt
rm kafka.unsigned.crt
rm client.csr
rm root.key
rm root.srl
