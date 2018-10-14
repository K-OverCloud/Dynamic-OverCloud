#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#Parsing Function
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


# $1 == OverCloud_ID

#OverCloud_ID=$1
OverCloud_ID=$1

#echo $OverCloud_ID > ID

# find DevOps Post IP
sql=$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; select * from devops_post where overcloud_ID='$OverCloud_ID';")
post_IP=`echo $sql | awk '{print $4}'`
echo $post_IP


# remokte previous ssh key
#ssh-keygen -f "/root/.ssh/known_hosts" -R $post_IP


# Ping check
check=0


while [ $check == 0 ]
do
        ssh -o "StrictHostKeyChecking = no" -i ../configuration/ssh/$OverCloud_ID.key -q ubuntu@$post_IP exit
        if [ "$?" == 0 ]
        then
          echo "Host found"
          check=1
        else
          echo "Host not found"
        fi
        sleep 3
done




# download git
ssh -o "StrictHostKeyChecking = no" -i ../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP git clone http://github.com/k-overcloud/dynamic-overcloud

# kube config
ssh -o "StrictHostKeyChecking = no" -i ../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo ./dynamic-overcloud/workflows/post/kubernetes_config.sh $post_IP &


# find Logical Clusters
#sql=$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; select count(*) from logical_cluster where overcloud_ID='$OverCloud_ID';")
#Num=`echo $sql | awk '{print $2}'`

#echo $Num
#count=0
sql=$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; select IP from logical_cluster where overcloud_ID='$OverCloud_ID';")

for i in $sql; do
  if [ $i == "IP" ]; then
    continue
  fi

  check=0
  while [ $check == 0 ]
  do
        ssh -o "StrictHostKeyChecking = no" -i ../configuration/ssh/$OverCloud_ID.key -q ubuntu@$i exit 
        if [ "$?" = 0 ]
        then
          echo "Host found"
          check=1
        else
          echo "Host not found"
        fi
        sleep 3
  done



  # download git
  ssh -o "StrictHostKeyChecking = no" -i ../configuration/ssh/$OverCloud_ID.key ubuntu@$i sudo git clone http://github.com/k-overcloud/dynamic-overcloud

  # kube config
  ssh -o "StrictHostKeyChecking = no" -i ../configuration/ssh/$OverCloud_ID.key ubuntu@$i sudo ./dynamic-overcloud/workflows/post/kubernetes_config.sh $i &

done

# wait all jobs..
WORK_PID=`jobs -l | awk '{print $2}'`
wait $WORK_PID

