How to setup mesInfrastructure with Kafka, KafkaUI, Clickhouse and Redis

1. Run the script GenerateCertificates.ps1
This script will generate self signed certificates to be used by the stack that contains Kafka, KafkaUI, Clickhouse and Redis as for the MES stack.

2. Run the script deployStackToSwarm
This script add the certificates generated in step 1. to dockerSwarm as a secret. It will start the stack containing Kafka, KafkaUI, Clickhouse and Redis.

3. Generate an MES stack using the certificates
In PortalQA/PortalDev, in step "Configuration -> Dependencies" set the following values

Clickhouse
Ssl certificate authority: ClickhouseSslCaPem

Kafka
Ssl certificate authority: KafkaSslCaPem
Ssl certificate: KafkaSslCertificatePem
Ssl key: KafkaSslKeyPem

Redis
Ssl certificate authority: RedisSslCaPem

These are the names of the secreats created in step 2.

4. Kubernetes/Openshift
If your environment is in Kubernentes run the following commands to create the secrets.

Clickhouse
kubectl create secret generic ClickhouseSslCaPem --from-file=privatekey.pem=/Certificates/Generic/root.crt --namespace=<namespace_name>

Kafka
kubectl create secret generic KafkaSslCaPem --from-file=privatekey.pem=/Certificates/Kafka/root.crt --namespace=<namespace_name>
kubectl create secret generic KafkaSslCertificatePem --from-file=privatekey.pem=/Certificates/Kafka/client.crt --namespace=<namespace_name>
kubectl create secret generic KafkaSslKeyPem --from-file=privatekey.pem=/Certificates/Kafka/client.key --namespace=<namespace_name>

Redis
kubectl create secret generic RedisSslCaPem --from-file=privatekey.pem=/Certificates/Generic/root.crt --namespace=<namespace_name>
