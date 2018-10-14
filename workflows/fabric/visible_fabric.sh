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

sleep 1

ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/prom-rbac.yaml

sleep 1

ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/ambassador-rbac.yaml

sleep 1

ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/ambassador.yaml

sleep 5

ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/statsd-sink-svc.yaml

sleep 1

ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/prometheus.yaml

sleep 1

ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/prom-svc.yaml

sleep 1

ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/httpbin.yaml

sleep 1
# Weave 
ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f dynamic-overcloud/workflows/fabric/weave.yaml



# install Telegraf & influxdb & chronograf

# download influxdb
ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo wget https://dl.influxdata.com/influxdb/releases/influxdb_1.6.3_amd64.deb

# install influxdb
ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo dpkg -i influxdb_1.6.3_amd64.deb

# start service
ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo service influxdb start


# download chronograf
ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo wget https://dl.influxdata.com/chronograf/releases/chronograf_1.6.2_amd64.deb

# install chronograf
ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo dpkg -i chronograf_1.6.2_amd64.deb



# telegraf configuration

# find logical cluster IPs
sql=$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; select IP from logical_cluster where overcloud_ID='$OverCloud_ID';")

for i in $sql; do
  if [ $i == "IP" ]; then
    continue
  fi


  # download telegraf
  ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$i sudo wget https://dl.influxdata.com/telegraf/releases/telegraf_1.4.3-1_amd64.deb

  # install telegraf 
  ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$i sudo dpkg -i telegraf_1.4.3-1_amd64.deb

  # configure conf file
  temp="sed -i \"s/http:\/\/localhost/http:\/\/$post_IP/g\" /etc/telegraf/telegraf.conf"

  ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$i sudo $temp

  # service restart 
  ssh -o "StrictHostKeyChecking = no" -i ../../configuration/ssh/$OverCloud_ID.key ubuntu@$i sudo service telegraf restart

done
 
 



