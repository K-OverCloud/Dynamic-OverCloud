#!/bin/bash


# Parsing


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
HOST=$(get_config_value ../configuration/init.ini database MySQL_HOST)
PASS=$(get_config_value ../configuration/init.ini database MySQL_PASS)


# $1 == OverCloud_ID

OverCloud_ID=$1


# find DevOps Post IP
sql=$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; select * from devops_post where overcloud_ID='$OverCloud_ID';")
post_IP=`echo $sql | awk '{print $4}'`
echo $post_IP

# kube init 
ssh -o "StrictHostKeyChecking = no" -i ../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo ./dynamic-overcloud/workflows/post/init_clulster.sh $post_IP


# find kube join ssh key
join=`ssh -o "StrictHostKeyChecking = no" -i ../configuration/ssh/"$OverCloud_ID".key ubuntu@"$post_IP" sudo cat join_data`

echo ""
echo "temp is"
echo $join

# find logical cluster IPs
sql=$(mysql -u overclouds -h $HOST --password=$PASS -e "use overclouds; select IP from logical_cluster where overcloud_ID='$OverCloud_ID';")

for i in $sql; do
  if [ $i == "IP" ]; then
    continue
  fi


  # kubelet configuration
  ssh -o "StrictHostKeyChecking = no" -i ../configuration/ssh/$OverCloud_ID.key ubuntu@$i sudo./dynamic-overcloud/workflows/clusters/join_cluster.sh $i

  
  # kube join 
  ssh -o "StrictHostKeyChecking = no" -i ../configuration/ssh/$OverCloud_ID.key ubuntu@$i sudo $join

done




# RBAC 
ssh -o "StrictHostKeyChecking = no" -i ../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl create clusterrolebinding permissive-binding --clusterrole=cluster-admin --user=admin --user=kubelet --group=system:serviceaccounts


# apply Calico network Plugin
#ssh -o "StrictHostKeyChecking = no" -i ../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f https://docs.projectcalico.org/v3.2/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml


#ssh -o "StrictHostKeyChecking = no" -i ../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f https://docs.projectcalico.org/v3.2/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml



# apply weave network Plugin

# to install weave network plugin, permission are allowed
ssh -o "StrictHostKeyChecking = no" -i ../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo chmod 777 /home/ubuntu/.kube/config


version=`ssh -o "StrictHostKeyChecking = no" -i ../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl version | base64 | tr -d '\n'`

ssh -o "StrictHostKeyChecking = no" -i ../configuration/ssh/$OverCloud_ID.key ubuntu@$post_IP sudo kubectl apply -f https://cloud.weave.works/k8s/net?k8s-version=$version



