[![Infinispan](https://design.jboss.org/infinispan/logo/final/PNG/infinispan_logo_rgb_lightbluewhite_darkblue_600px.png)](https://infinispan.org/)

# Infinispan SQL Store Demo with Quarkus # 

## Description

### Retail Catalogue

Retail Catalogue is a very simple Quarkus application that persists data in a Postgresql database. 

'commands' endpoint displays the content of the database model.
```json
[
    {
        "id": 5,
        "buyer": {
            "id": 4,
            "country": "Spain",
            "email": "mfrechilla@quarkus.io",
            "name": "Maria Rosario Frechilla",
            "phone": "+34 666"
        },
    "products": [
            {
                "id": 1,
                "code": "c123",
                "name": "Skirt Party",
                "price": 50,
                "stock": 20
            },
            {
                "id": 2,
                "code": "c456",
                "name": "Pants Party",
                "price": 20,
                "stock": 10
            },
            {
                "id": 3,
                "code": "c789",
                "name": "Dress Party",
                "price": 90,
                "stock": 20
            }
            ],
          "promotion": true
        }
]
```

### Inmemory Catalogue

Inmemory Catalogue creates two SQL Cache Stores with Infinispan on startup. 
1. `catalogue-table-store` is a table sql store persisted cache that maps to the RetailProduct table
2. `sold-products-query-store`is a query sql store persisted cache that joins information across multiple tables.

Both caches use indexing.

The application exposes 3 endpoints:
* `catalogue`: Lists the catalogue content. Can filter by name, stock units and prices using query parameters.
* `catalogue/{code}`: Displays the catalogue product by code
* `sales`: Lists the  products than have been sold. Filter can be done name of the product and country.

## Dev mode 

* Run Infinispan and Postgresql in the same network with docker

```shell
docker-compose up
```
Dev services are disabled since the Infinispan and Postresql need to be in the same
docker network and Infinispan access the Postgresql database directly to load the data
into the caches.

* Run Retail Catalogue and Store

```shell
cd infinispan-sqlstore-demo/retail-catalogue 
./mvnw quarkus:dev 
```

* Run Infinispan In-memory catalogue
```shell
cd infinispan-sqlstore-demo/inmemory-catalogue 
./mvnw quarkus:dev 
```

## Links

Additional resources and useful links:

* [Infinispan Query and Indexing Guide](https://infinispan.org/docs/stable/titles/query/query.htm)
* [Infinispan SQL Cache Storage Documentation](https://infinispan.org/docs/stable/titles/configuring/configuring.html#sql-cache-store_persistence)
* [Quarkus Infinispan Extension](https://quarkus.io/guides/infinispan-client)

## Deploy Openshift

1. Connect Openshift
```shell
oc login --certificate-authority=openshift-crt.crt https://api.cluster-hmstj.hmstj.sandbox2239.opentlc.com:6443 -u login -p pwd 
```   
2. Create Kubernetes Secret `sqlstore-credentials`
```shell
oc create secret generic clients-credentials --from-literal=db-username=infinispan --from-literal=db-password=secret --from-literal=infinispan-username=admin --from-literal=infinispan-password=secret
```
3. Deploy Postgresql
```shell
oc apply -f deploy/postgres.yaml
```

4. Build and deploy Retail Catalogue
```shell
cd retail-catalogue
./mvnw clean package -Dquarkus.kubernetes.deploy=true -DskipTests=true -Dquarkus.profile=prod 

# Export the service URL 
export RETAIL_CATALOGUE=$(oc get route retail-store-service --output=jsonpath={..spec.host}) 

# Check the commands endpoint 
curl $RETAIL_CATALOGUE/commands
```

5. Install the Data Grid Operator from the OperatorHub


6. Create Infinispan identities secret
```shell
oc create secret generic --from-file=identities.yaml connect-secret
```

7. Deploy infinispan server
```shell
oc apply -f deploy/infinispan.yaml
```

You should see something like the following list

```shell
 oc get services   
Name                          TYPE        CLUSTER-IP     EXTERNAL-IP     PORT(S)           AGE
infinispan                   ClusterIP   172.30.12.78     <none>        11222/TCP         4h3m
infinispan-admin             ClusterIP   None             <none>        11223/TCP         63m
infinispan-external          NodePort    172.30.224.46    <none>        11222:30000/TCP   63m
infinispan-ping              ClusterIP   None             <none>        8888/TCP          63m
postgres                     NodePort    172.30.64.229    <none>        5432:31867/TCP    4h4m
retail-store-service         ClusterIP   172.30.247.242   <none>        80/TCP            44m
```

8. Build and deploy Inmemory Catalogue
```shell
cd ../inmemory-catalogue
./mvnw clean package -Dquarkus.kubernetes.deploy=true -DskipTests=true -Dquarkus.profile=prod 

# Export the service URL 
export INMEMORY_CATALOGUE=$(oc get route inmemory-catalogue-service --output=jsonpath={..spec.host}) 

curl $INMEMORY_CATALOGUE
```