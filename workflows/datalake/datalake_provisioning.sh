#!/bin/bash

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
HOST=$(get_config_value ../../configuration/init.ini database MySQL_HOST)
PASS=$(get_config_value ../../configuration/init.ini database MySQL_PASS)


# $1 == OverCloud_ID

#OverCloud_ID=$1
OverCloud_ID=$1

#echo $OverCloud_ID > ID

# find DevOps Post IP
sql=$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; select * from devops_post where overcloud_ID='$OverCloud_ID';")
post_IP=`echo $sql | awk '{print $4}'`
echo $post_IP


# download rook
ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo git clone http://github.com/rook/rook

# add rook operator
ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl create -f rook/cluster/examples/kubernetes/ceph/operator.yaml

# add rook cluster
ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl create -f rook/cluster/examples/kubernetes/ceph/cluster.yaml

# add rook block storage
ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl create -f rook/cluster/examples/kubernetes/ceph/storageclass.yaml

# configure default storage
temp="'{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}'"

ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl patch storageclass rook-ceph-block -p $temp


