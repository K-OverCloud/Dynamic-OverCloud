# Dynamic OverCloud

## Overview ##
Dynamic OverCloud is a specially-arranged razor-thin overlay layer that supports the open-source leveraged service composition in a cloud-agnostic way. Dynamic OverCloud includes several elements to support the MSA-based service composition. Dynamic OverCloud consists of Interface Proxy, Dev+Ops Post, Cloud-native Clusters, Connected DataLake and Visible Fabric. Dynamic OverCloud provides the open-source leveraged service composition when given a containerized microservices pattern that corresponds to the targeted service.


To show more details of Dynamic OverCloud, see following the document.
* [Dynamic OverCloud Concept & Components](docs/OVERCLOUD.md)


## Requirements
Interface Proxy 
* OpenStack Mistral
* Python3 
* MySQL
* pipenv
* Ubuntu 16.04

Clouds
* OpenStack (Pike version) / Amazon AWS Clouds


## Install 

In this step, you should run following commands on Interface Proxy (OverCloud Tower Proxy).

```
$ git clone http://github.com/k-overcloud/dynamic-overcloud
$ cd dynamic-overcloud
```

(Option) If you have MySQL, Skip following commands
```
$ cd installation
$ vim mysql.sh
```
Change "10.10.10.10" in Bind_Address to your IP of Interface Proxy


Change "PASS" in PASSWORD to your MySQL Password 


save & exit
```
$ ./mysql.sh
```

## Configuration

To configure DB Tables,
```
$ cd dynamic-overcloud/configuration/mysql
$ vim init_db.sh
```
Change "10.10.10.10" in HOST to your IP of MySQL HOST


Change "PASS" in PASS to your MySQL Password 


Save & exit
```
$ ./init_db.sh
```

To set informations (clouds, database, mistral), run following commands

```
$ cd dynamic-overcloud/configuration
$ vim init.ini
```

In [provider] seciton, you configure your own clouds (OpenStack, Amazon AWS)

You can only configure specific clouds (OpenStack or Amazon AWS), if you don't have both clouds

```
OpenStack_ID: your OpenStack Keystone ID
OpenStack_Password: your Password of Keystone ID
OpenStack_keystone: Keystone Endpoint IP (ex, 192.168.90.10)


Amazon_ACCESS_KEY_ID: Amazon Access Key token (Ex.,CDQJJQHYZODEFBC7P62A)
Amazon_SECRET_ACCESS_KEY: Amazon secrete access Key (Ex., A5qZUguxDG/kJzqjAKaqPNE9KoiXo38Rq8HpqQ3f)
```



In [database] seciton, you configure your MySQL IP and Password

```
MySQL_HOST: MySQL Endpoint IP
MySQL_PASS: MySQL Password
```


In [operator] seciton, you configure your Interface Proxy

```
Operator_HOST: Interface Proxy IP
Operator_ID: Box Account Name (To connect remote SSH)
Operator_PASS: Box Password 
```

Save & exit

## Running
To run Dynamic OverCloud API server, run following commands

```
$ cd dynamic-overcloud/api
$ pipenv install
$ ./bootstrap.sh
```


## Documents
To use Dynamic OverCloud API, check the following API user guide

* [REST API V1](docs/REST_API_V1.md)





