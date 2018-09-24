#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


# MySQL
HOST=""
PASS=""


OverCloud_ID=""
Num="3"

Cloud_keystone_IP=""

ID=""
Password=""


# delete devops Post
sql=$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; delete from devops_post where overcloud_ID='$OverCloud_ID';")

# delete logical clusters
sql=$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; delete from logical_cluster where overcloud_ID='$OverCloud_ID';")

# delete overcloud
sql=$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; delete from overcloud where overcloud_ID='$OverCloud_ID';")




# delete ssh Keys
rm ../configuration/ssh/$OverCloud_ID.key
rm ../configuration/ssh/$OverCloud_ID.key.pub


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


# delete isntance
openstack server delete DevOps_Post

count=0


while [ $count != $Num ]
do
  let count=count+1

  temp="Logical_Cluster"-$count
  #echo $temp

  # delete instance (Logical Clusters)
  openstack server delete $temp


done






# delete router subnet
openstack router remove subnet overcloud_router_$OverCloud_ID overcloud_subnet_$OverCloud_ID 

# delete router
openstack router delete overcloud_router_$OverCloud_ID

# delete network
openstack network delete overcloud_network_$OverCloud_ID


# delete keypair
nova keypair-delete $OverCloud_ID


