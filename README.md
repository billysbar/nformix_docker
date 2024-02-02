# payzone_informix_docker

docker container
```
https://hub.docker.com/r/ibmcom/informix-developer-database
```

docs
```
https://github.com/informix/informix-dockerhub-readme/blob/master/14.10.FC1/informix-developer-database.md
```

run up the container
```
docker-compose up --build
```
```
ignore 'debconf: unable to initialize frontend: Dialog'
```

External database connection information (DataGrip etc) 
```
Add new Driver
Name - Informix JDBC
Driver Files - add Custom Jar - ifxjdbc.jar (located in folder jdbc_driver)
select Class from dropdown - com.informix.jdbc.ifxDriver
```

Connect via DataGrip
```
new data source, select 'Informix JDBC'
User - informix
Password - in4mix
URL - jdbc:informix-sqli://localhost:9088/sysadmin:INFORMIXSERVER=informix
```

should connect and see sysadmin database

```
running install4gl from Dockerfile screws up
must be due to env not set or container not yet initialized correctly 
- TODO maybe
```

run a test script, create database & table & populate
```
docker exec -it  payzone_informix_docker-informix-1 bash
cd config
./server-setup.sh
```

### install i4gl

shell into docker image
```
docker exec -it  payzone_informix_docker-informix-1 bash

/home/informix/config/i4gl-setup.sh
```

i4gl installed correctly displays

```
"Goodbye Cruel World - i4gl install success"
```

###Try dbaccess & i4gl

You can connect to the informix db via the rest connection
```
http://localhost:27018/sysmaster/systables?query={tabid:{$lte:5}}&fields={tabname:1}&sort={tabname:-1}
```

mongo data select dbaccess
select data::JSON FROM shani
