#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


MYSQL_HOST=""
MYSQL_PASS=""
Provider="Amazon"

Cloud_keystone_IP=""

ID=""
Password=""
Num="3"
Flavor=""

operator_host=""
operator_id=""
operator_pass=""



# Create OverCloud ID
MATRIX="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
LENGTH="15"

while [ "${n:=1}" -le "$LENGTH" ]
do
    OverCloud_ID="$OverCloud_ID${MATRIX:$(($RANDOM%${#MATRIX})):1}"
    let n+=1
done
echo $OverCloud_ID


# found ID from mysql database
sql=$(mysql -u overclouds -h $MYSQL_HOST --password=$MYSQL_PASS -e "use overclouds; select * from tenant where tenant_ID='$ID';")

if [ "$sql" == "" ]; then
  echo "No result"
  mysql -u overclouds -h $MYSQL_HOST --password=$MYSQL_PASS -e "use overclouds; insert into tenant value('$ID');"
else
  echo "Found"
fi


# create tuple for OverCLoud ID
mysql -u overclouds -h $MYSQL_HOST --password=$MYSQL_PASS -e "use overclouds; insert into overcloud values('$OverCloud_ID', '$ID');"


# create input.json file
touch input.json
echo '{"operator_host":"'$operator_host'","operator_id":"'$operator_id'","operator_pass":"'$operator_pass'","id":"'$OverCloud_ID'","flavor":"'$Flavor'","number":"'$Num'","provider":"'$Provider'"}' > input.json


# create task_name file
touch task_name.json
echo '{"task_name":"datalake_provisioning"}' > task_name.json


# run mistral execution-create
mistral execution-create Amazon_Instantiation input.json task_name.json

rm input.json
rm task_name.json





