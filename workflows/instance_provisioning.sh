#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


MYSQL_HOST=""
MYSQL_PASS=""
Provider=""


Cloud_keystone_IP=""

# $1 == Number
# $2 == Flavor
# $3 == Provider
# $4 == ID

ID=""
Password=""
Num=$1
Flavor=$2
#key="HJS"

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


OverCloud_ID=$4
key=$4

# Generate SSH key
ssh-keygen -t rsa -P "" -f $key.key -q

nova keypair-add --pub-key $key.key.pub $key

mv $key.key $key.key.pub ../configuration/ssh





# create network
openstack network create overcloud_network_$OverCloud_ID

# create subnet
openstack subnet create --network overcloud_network_$OverCloud_ID --dns-nameserver 8.8.8.8 --subnet-range 192.168.100.0/24 overcloud_subnet_$OverCloud_ID

# create router
openstack router create overcloud_router_$OverCloud_ID

# setting external gateway
openstack router set --external-gateway public overcloud_router_$OverCloud_ID

# add port
openstack router add subnet overcloud_router_$OverCloud_ID overcloud_subnet_$OverCloud_ID


# Openstack Instance

# DevOps Post
openstack server create --key-name $key --flavor $Flavor --image ubuntu-xenial --network overcloud_network_$OverCloud_ID DevOps_Post

# Logical Cluster 
openstack server create --key-name $key --flavor $Flavor --image ubuntu-xenial --network overcloud_network_$OverCloud_ID Logical_Cluster --max $Num


# find flaoting ip list
floating=`openstack floating ip list | grep None | sed -n 1p | awk '{print $4}'`


if [ "$floating" == "" ]; then
  openstack floating ip create public
fi

floating=`openstack floating ip list | grep None | sed -n 1p | awk '{print $4}'`

# assocaite flaoting ip to instance
openstack server add floating ip DevOps_Post $floating

# create tuple for DevOps_Post
mysql -u overclouds -h $MYSQL_HOST --password=$MYSQL_PASS -e "use overclouds; insert into devops_post values('$floating', '$OverCloud_ID', '$Provider');"




# Floating IP (Logical Cluster)
count=0


while [ $count != $Num ]
do
  let count=count+1

  temp="Logical_Cluster"-$count
  #echo $temp

  floating=`openstack floating ip list | grep None | sed -n 1p | awk '{print $4}'`


  if [ "$floating" == "" ]; then
    openstack floating ip create public
  fi

  floating=`openstack floating ip list | grep None | sed -n 1p | awk '{print $4}'`

  # assocaite flaoting ip to instance
  openstack server add floating ip $temp $floating

  # create tuple for logical clusters
  mysql -u overclouds -h $MYSQL_HOST --password=$MYSQL_PASS -e "use overclouds; insert into logical_cluster values('$floating', '$OverCloud_ID', '$Provider');"

done




