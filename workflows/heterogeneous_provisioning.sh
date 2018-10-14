#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


get_config_value()
{
    cat <<EOF | python3
import configparser
config = configparser.ConfigParser()
config.read('$1')
print (config.get('$2','$3'))
EOF
}


MYSQL_HOST=$(get_config_value ../configuration/init.ini database MySQL_HOST)
MYSQL_PASS=$(get_config_value ../configuration/init.ini database MySQL_PASS)

Cloud_keystone_IP=$(get_config_value ../configuration/init.ini provider OpenStack_keystone)

ID=$(get_config_value ../configuration/init.ini provider OpenStack_ID)
Password=$(get_config_value ../configuration/init.ini provider OpenStack_Password)


# $1 == OpenStack_Number
# $2 == Amazon_Number
# $3 == OpenStack_Flavor
# $4 == Amazon_Flavor
# $5 == devops_post
# $6 == OverCloud_ID

OpenStack_Number=$1
Amazon_Number=$2
OpenStack_Flavor=$3
Amazon_Flavor=$4
devops_post=$5
OverCloud_ID=$6


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


# AWS configure

KEY_ID=$(get_config_value ../configuration/init.ini provider Amazon_ACCESS_KEY_ID)
ACCESS_KEY=$(get_config_value ../configuration/init.ini provider Amazon_SECRET_ACCESS_KEY)
REGION="ap-northeast-2"

echo $KEY_ID
echo $ACCESS_KEY

cat << EOF | aws configure
$KEY_ID
$ACCESS_KEY
$REGION
json
EOF




# Generate SSH key
ssh-keygen -t rsa -P "" -f $OverCloud_ID.key -q


# OpenStack add
nova keypair-add --pub-key $OverCloud_ID.key.pub $OverCloud_ID

# Ec2 add 
aws ec2 import-key-pair --key-name $OverCloud_ID --public-key-material file://$OverCloud_ID.key.pub

mkdir ../configuration/ssh
mv $OverCloud_ID.key $OverCloud_ID.key.pub ../configuration/ssh




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

if [ "$devops_post" == "OpenStack" ]; then

  # DevOps Post
  openstack server create --key-name $OverCloud_ID --flavor m1.logical --image ubuntu-xenial --network overcloud_network_$OverCloud_ID DevOps_Post

fi

# Logical Cluster 
if [ "$OpenStack_Number" == "1" ]; then
  openstack server create --key-name $OverCloud_ID --flavor $OpenStack_Flavor --image ubuntu-xenial --network overcloud_network_$OverCloud_ID Logical_Cluster-1 --max $OpenStack_Number

else
  openstack server create --key-name $OverCloud_ID --flavor $OpenStack_Flavor --image ubuntu-xenial --network overcloud_network_$OverCloud_ID Logical_Cluster --max $OpenStack_Number
fi


# find flaoting ip list
floating=`openstack floating ip list | grep None | sed -n 1p | awk '{print $4}'`



if [ "$floating" == "" ]; then
  openstack floating ip create public
fi

floating=`openstack floating ip list | grep None | sed -n 1p | awk '{print $4}'`


if [ "$devops_post" == "OpenStack" ]; then

  # assocaite flaoting ip to instance
  openstack server add floating ip DevOps_Post $floating
  
  
  # create tuple for DevOps_Post
  mysql -u overclouds -h $MYSQL_HOST --password=$MYSQL_PASS -e "use overclouds; insert into devops_post values('$floating', '$OverCloud_ID', '$devops_post');"

fi



# Floating IP (Logical Cluster) for OpenStack
count=0


while [ $count != $OpenStack_Number ]
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
  mysql -u overclouds -h $MYSQL_HOST --password=$MYSQL_PASS -e "use overclouds; insert into logical_cluster values('$floating', '$OverCloud_ID', 'OpenStack');"

done


# Amazon 

Image="ami-00ca7ffe117e2fe91"


if [ "$devops_post" == "Amazon" ]; then

  DevOps_id=$(aws ec2 run-instances --image-id $Image --count 1 --instance-type t2.2xlarge --key-name $OverCloud_ID --query 'Instances[0].InstanceId')

  DevOps_id=$(echo "$DevOps_id" | tr -d '"')

  echo $DevOps_id

  # Name Tag
  aws ec2 create-tags --resources $DevOps_id --tags Key=Name,Value=DevOps_Post

  
  # obtain Public IP

  IP=$(aws ec2 describe-instances --instance-ids $DevOps_id --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)

  echo $IP


  # create tuple for DevOps_Post
  mysql -u overclouds -h $MYSQL_HOST --password=$MYSQL_PASS -e "use overclouds; insert into devops_post values('$IP', '$OverCloud_ID', '$devops_post');"

fi


# Floating IP (Logical Cluster)
count=$OpenStack_Number

total=$Amazon_Number
let total=total+$count

while [ $count != $total ]
do
  let count=count+1

  temp="Logical_Cluster"-$count

  Logical_Cluster_id=$(aws ec2 run-instances --image-id $Image --count 1 --instance-type $Amazon_Flavor --key-name $OverCloud_ID --query 'Instances[0].InstanceId')

  Logical_Cluster_id=$(echo "$Logical_Cluster_id" | tr -d '"')

  echo $Logical_Cluster_id

  # Name Tag
  aws ec2 create-tags --resources $Logical_Cluster_id --tags Key=Name,Value=$temp

  # Wait for running instance
  #instance_state=$(aws ec2 wait instance-running --instance-ids $Logical_Cluster_id)


  # obtain Public IP

  IP=$(aws ec2 describe-instances --instance-ids $Logical_Cluster_id --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)

  echo $IP


  # create tuple for logical clusters
  mysql -u overclouds -h $MYSQL_HOST --password=$MYSQL_PASS -e "use overclouds; insert into logical_cluster values('$IP', '$OverCloud_ID', 'Amazon');"

done








