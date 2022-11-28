oc create secret generic sqlstore-credentials --from-literal=username=infinispan --from-literal=password=secret
oc apply -f deploy/postgres.yaml

#--> deploy and run infinispan, with the postgresql driver inside

cd retail-catalogue
./mvnw clean package -Dquarkus.kubernetes.deploy=true -DskipTests=true
cd ..
cd inmemory-catalogue
./mvnw clean package -Dquarkus.kubernetes.deploy=true -DskipTests=true
cd ..