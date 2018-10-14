#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

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


# MySQL
HOST=$(get_config_value ../configuration/init.ini database MySQL_HOST)
PASS=$(get_config_value ../configuration/init.ini database MySQL_PASS)



OverCloud_ID="$1"

Cloud_keystone_IP=$(get_config_value ../configuration/init.ini provider OpenStack_keystone)


ID=$(get_config_value ../configuration/init.ini provider OpenStack_ID)
Password=$(get_config_value ../configuration/init.ini provider OpenStack_Password)


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




# find DevOps Post IP
sql=$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; select * from devops_post where overcloud_ID='$OverCloud_ID';")
#echo $sql
post_IP=`echo $sql | awk '{print $4}'`
echo $post_IP

# find provider
sql==$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; select provider from devops_post where overcloud_ID='$OverCloud_ID';")
#echo $sql
provider=`echo $sql | awk '{print $2}'`


echo $provider

if [ $provider == "Amazon" ]; then
   echo "amazon delete"

   Instance_id=$(aws ec2 describe-instances --filter "Name=ip-address, Values=$post_IP" --query "Reservations[].Instances[].InstanceId" --output text)
   echo $Instance_id
   aws ec2 terminate-instances --instance-ids $Instance_id

else
   echo "openstack delete"
   Instance_id=$(openstack server list | grep $post_IP | awk '{print $2}')
   echo $Instance_id
   openstack server delete $Instance_id

fi



# find logical cluster IPs with Amazon
sql=$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; select IP from logical_cluster where overcloud_ID='$OverCloud_ID' and provider='Amazon';")


for i in $sql; do
  if [ $i == "IP" ]; then
    continue
  fi

  Instance_id=$(aws ec2 describe-instances --filter "Name=ip-address, Values=$i" --query "Reservations[].Instances[].InstanceId" --output text)
  echo $Instance_id
  aws ec2 terminate-instances --instance-ids $Instance_id 

done



# find logical cluster IPs with OpenStack
sql=$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; select IP from logical_cluster where overcloud_ID='$OverCloud_ID' and provider='OpenStack';")


for i in $sql; do
  if [ $i == "IP" ]; then
    continue
  fi

  Instance_id=$(openstack server list | grep $i | awk '{print $2}')
  echo $Instance_id
  openstack server delete $Instance_id
done



# MySQL 
# delete devops Post
sql=$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; delete from devops_post where overcloud_ID='$OverCloud_ID';")

# delete logical clusters
sql=$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; delete from logical_cluster where overcloud_ID='$OverCloud_ID';")

# delete overcloud
sql=$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; delete from overcloud where overcloud_ID='$OverCloud_ID';")



# delete ssh Keys
rm ../configuration/ssh/$OverCloud_ID.key
rm ../configuration/ssh/$OverCloud_ID.key.pub



# Amazon key-delete 
aws ec2 delete-key-pair --key-name $OverCloud_ID




## Openstack delete


# delete router subnet
openstack router remove subnet overcloud_router_$OverCloud_ID overcloud_subnet_$OverCloud_ID

# delete router
openstack router delete overcloud_router_$OverCloud_ID

# delete network
openstack network delete overcloud_network_$OverCloud_ID


# delete keypair
nova keypair-delete $OverCloud_ID

