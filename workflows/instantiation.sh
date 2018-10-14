#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


# OverCloud_ID = $1
# Provider = $2
# Number = $3
# Flavor = $4

#Provider="OpenStack"
Provider=$2

#Num="2"
Num=$3

Flavor=$4
#Flavor="m1.logical"

OverCloud_ID=$1


# Parsing Function

get_config_value()
{
    cat <<EOF | python3
import configparser
config = configparser.ConfigParser()
config.read('$1')
print (config.get('$2','$3'))
EOF
}


Cloud_keystone_IP=$(get_config_value ../configuration/init.ini provider OpenStack_keystone)
ID=$(get_config_value ../configuration/init.ini provider OpenStack_ID)
Password=$(get_config_value ../configuration/init.ini provider OpenStack_Password)

MYSQL_HOST=$(get_config_value ../configuration/init.ini database MySQL_HOST)
MYSQL_PASS=$(get_config_value ../configuration/init.ini database MySQL_PASS)



operator_host=$(get_config_value ../configuration/init.ini operator Operator_HOST)
operator_id=$(get_config_value ../configuration/init.ini operator Operator_ID)
operator_pass=$(get_config_value ../configuration/init.ini operator Operator_PASS)




#Keystone Authntication
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=$ID
export OS_USERNAME=$ID
export OS_PASSWORD=$Password
export OS_AUTH_URL=http://$Cloud_keystone_IP:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

#openstack token issue > temp

Output=`openstack token issue`

#echo "check is $Output"

if [ "$Output" == "" ]; then
   echo "Authentication Failed"
   exit 1
fi



# Create OverCloud ID
#MATRIX="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
#LENGTH="15"

#while [ "${n:=1}" -le "$LENGTH" ]
#do
#    OverCloud_ID="$OverCloud_ID${MATRIX:$(($RANDOM%${#MATRIX})):1}"
#    let n+=1
#done
#echo $OverCloud_ID


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
echo '{"task_name":"visible_fabric"}' > task_name.json


# run mistral execution-create
mistral execution-create Instantiation input.json task_name.json -d $OverCloud_ID

rm input.json
rm task_name.json


# wait until finishing workflows

while [ true ]
do
  temp=$(mistral execution-list | grep $OverCloud_ID | grep RUNNING)
  if [ "$temp" != "" ]; then
    echo "Waiting"
    sleep 3
  else
    echo "Finish"
    break
  fi
done





