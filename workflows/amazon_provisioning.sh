#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


# Parsing Function
get_config_value()
{
    cat <<EOF | python
import ConfigParser
config = ConfigParser.ConfigParser()
config.read('$1')
print (config.get('$2','$3'))
EOF
}


# MySQL
MYSQL_HOST=$(get_config_value ../configuration/init.ini database MySQL_HOST)
MYSQL_PASS=$(get_config_value ../configuration/init.ini database MySQL_PASS)


Provider="amazon"

Cloud_keystone_IP=$(get_config_value ../configuration/init.ini provider OpenStack_keystone)


# $1 == Number
# $2 == Flavor
# $3 == Provider
# $4 == ID

Num="3"
Flavor="c5d.xlarge"


OverCloud_ID=$4


# Amazon Ubuntu 16.04 Image ID
Image="ami-00ca7ffe117e2fe91"


# Parsing Function

get_config_value()
{
    cat <<EOF | python
import ConfigParser
config = ConfigParser.ConfigParser()
config.read('$1')
print (config.get('$2','$3'))
EOF
}




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

aws ec2 create-key-pair --key-name $OverCloud_ID --query 'KeyMaterial' --output text > ../configuration/ssh/$OverCloud_ID.key 
chmod 400 ../configuration/ssh/$OverCloud_ID.key


# Instnace Creation

# DevOps Post

#aws ec2 run-instances --image-id $Image --count 1 --instance-type t2.2xlarge --key-name $OverCloud_ID --query 'Instances[0].InstanceId'

DevOps_id=$(aws ec2 run-instances --image-id $Image --count 1 --instance-type t2.2xlarge --key-name $OverCloud_ID --query 'Instances[0].InstanceId')

DevOps_id=$(echo "$DevOps_id" | tr -d '"')

echo $DevOps_id


# Name Tag
aws ec2 create-tags --resources $DevOps_id --tags Key=Name,Value=DevOps_Post

# Wait for running instance
#instance_state=$(aws ec2 wait instance-running --instance-ids $DevOps_id)



# obtain Public IP

IP=$(aws ec2 describe-instances --instance-ids $DevOps_id --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)

echo $IP


# create tuple for DevOps_Post
mysql -u overclouds -h $MYSQL_HOST --password=$MYSQL_PASS -e "use overclouds; insert into devops_post values('$IP', '$OverCloud_ID', '$Provider');"


# Floating IP (Logical Cluster)
count=0


while [ $count != $Num ]
do
  let count=count+1

  temp="Logical_Cluster"-$count

  Logical_Cluster_id=$(aws ec2 run-instances --image-id $Image --count 1 --instance-type $Flavor --key-name $OverCloud_ID --query 'Instances[0].InstanceId')

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
  mysql -u overclouds -h $MYSQL_HOST --password=$MYSQL_PASS -e "use overclouds; insert into logical_cluster values('$IP', '$OverCloud_ID', '$Provider');"

done


# Wait for running instance
instance_state=$(aws ec2 wait instance-running --instance-ids $Logical_Cluster_id)

