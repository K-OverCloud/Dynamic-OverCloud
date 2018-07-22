#!/bin/bash


# CREATE TABLE

#HOST=`cat init.conf | grep MySQL_HOST | awk '{print $3}'`
#PASS=`cat init.conf | grep MySQL_PASS | awk '{print $3}'`

HOST="10.10.10.10"
PASS="PASS"

#if [ "$HOST" == "" ]; then
#        echo "You should write your MySQL HOST into \"init.conf\""
#        exit
#fi
#
#if [ "$PASS" == "" ]; then
#        echo "You should write your MySQL Password into \"init.conf\""
#        exit
#fi

# CREATE Two Table
# slice / cloud_slice

cat << EOF | mysql -uroot -p$PASS
CREATE DATABASE overclouds;
GRANT ALL PRIVILEGES ON overclouds.* TO 'overclouds'@'localhost' IDENTIFIED BY '$PASS';
GRANT ALL PRIVILEGES ON overclouds.* TO 'overclouds'@'%' IDENTIFIED BY '$PASS';
use overclouds;
CREATE TABLE tenant(
tenant_ID VARCHAR(30) NOT NULL,
PRIMARY KEY (tenant_ID));
CREATE TABLE overcloud(
overcloud_ID VARCHAR (30) NOT NULL,
tenant_ID VARCHAR (30) NOT NULL,
PRIMARY KEY (overcloud_ID),
FOREIGN KEY (tenant_ID) references tenant(tenant_ID));
CREATE TABLE devops_post(
IP VARCHAR (30) NOT NULL,
overcloud_ID VARCHAR (30) NOT NULL,
provider VARCHAR (30) NOT NULL,
PRIMARY KEY(IP),
FOREIGN KEY (overcloud_ID) references overcloud(overcloud_ID));
CREATE TABLE logical_cluster(
IP VARCHAR (30) NOT NULL,
overcloud_ID VARCHAR (30) NOT NULL,
provider VARCHAR (30) NOT NULL,
PRIMARY KEY(IP),
FOREIGN KEY(overcloud_ID) references overcloud(overcloud_ID));
quit
EOF

