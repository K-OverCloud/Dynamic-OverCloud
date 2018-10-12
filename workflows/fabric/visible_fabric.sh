#!/bin/bash

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


# Prometheus & Envoy
ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/prom-operator.yaml

ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/prom-rbac.yaml

ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/ambassador-rbac.yaml

ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/ambassador.yaml

ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/statsd-sink-svc.yaml

ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/prometheus.yaml

ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/prom-svc.yaml

ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/httpbin.yaml


# Weave 
ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/weave.yaml

