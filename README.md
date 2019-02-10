# Dynamic OverCloud

## Overview ##
Dynamic OverCloud is a specially-arranged razor-thin overlay layer that supports the open-source leveraged service composition in a cloud-agnostic way. Dynamic OverCloud includes several elements to support the MSA-based service composition. Dynamic OverCloud consists of Interface Proxy, Dev+Ops Post, Cloud-native Clusters, Connected DataLake and Visible Fabric. Dynamic OverCloud provides the open-source leveraged service composition when given a containerized microservices pattern that corresponds to the targeted service.


## Requirements
Interface Proxy 
* OpenStack Mistral (Recommended, It doesn't matter it is on another server)
* Python3 
* MySQL
* Ubuntu 16.04

Cloud Boxes
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


save & exit
```
$ ./init_db.sh
```

To set informations (clouds, database, mistral), run following commands

```
$ cd dynamic-overcloud/configuration
$ vim init.ini
```




