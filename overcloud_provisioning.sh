#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


M_IP=210.125.84.51
C_IP=192.168.88.51
D_IP=10.10.20.51
#RABBIT_PASS=secrete
PASSWORD=fn!xo!ska!
#ADMIN_TOKEN=ADMIN
#MAIL=jshan@nm.gist.ac.kr

echo -n "Input your ID: "
read ID
echo -n "Input your Password: "
stty -echo
read Password
echo ""
stty echo


check="1"

echo -n "Choose your SaaS Form (1) 3-tier, (2) IoT-Cloud: "
read SaaS

if [ "$SaaS" == "1" ]; then 
#  echo "you choose 1"
  check="1"
elif [ "$SaaS" == "2" ]; then
#  echo "you choose 2"
  check="2"
else
  echo "you must choose (1) 3-tier or (2) IoT-Cloud"
  exit 1
fi

echo -n "How many Logical Clusters you will use: "
read Num


#echo "check is" $check
#echo "Num is" $Num
#echo "ID is" $ID
#echo "Password is" $Password
#ID="admin"
#Password="fn!xo!ska!"



#source
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=$ID
export OS_USERNAME=$ID
export OS_PASSWORD=$Password
export OS_AUTH_URL=http://192.168.88.51:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

#openstack token issue > temp

Output=`openstack token issue`

#echo "check is $Output"

if [ "$Output" == "" ]; then
   echo "Authentication Failed"
   exit 1
fi


# 3-tier 
if [ "$check" == "1" ]; then 
   echo "OverCloud 3-tier running..."
   ## we need to put them!!!
   exit 1
fi


if [ "$check" == "2" ]; then
   echo "Making Workflow.."
   mistral workflow-create devtower.yaml
   mistral workflow-create datalake.yaml
   mistral workflow-create logical_cluster.yaml
   echo ""
   echo "Workflows are created"
   echo ""


   echo "Creating DevTower.."
   mistral execution-create Dynamic_OverCloud_Provisioning_DevTower
   
   temp=`mistral execution-list | grep DevTower | grep RUN`

   while [ "$temp" != "" ]
   do
     sleep 2
     temp=`mistral execution-list | grep DevTower | grep RUN`
   done
   echo ""
   echo "DevTower has been created"
   echo ""
   
   echo "Creating DataLake.."
 
   mistral execution-create Dynamic_OverCloud_Provisioning_DataLake

   temp=`mistral execution-list | grep DataLake | grep RUN`

   while [ "$temp" != "" ]
   do
     sleep 2
     temp=`mistral execution-list | grep DataLake | grep RUN`
   done

   echo ""
   echo "DataLake has been created"
   echo ""
   

   echo "Creating Logical Clusters.."
   mistral execution-create Dynamic_OverCloud_Provisioning_LogicalCluster
   temp=`mistral execution-list | grep LogicalCluster | grep RUN`

   while [ "$temp" != "" ]
   do
     sleep 2
     temp=`mistral execution-list | grep LogicalCluster | grep RUN`
   done

   mistral execution-create Dynamic_OverCloud_Provisioning_LogicalCluster
   temp=`mistral execution-list | grep LogicalCluster | grep RUN`

   while [ "$temp" != "" ]
   do
     sleep 2
     temp=`mistral execution-list | grep LogicalCluster | grep RUN`
   done


   mistral execution-create Dynamic_OverCloud_Provisioning_LogicalCluster
   temp=`mistral execution-list | grep LogicalCluster | grep RUN`

   while [ "$temp" != "" ]
   do
     sleep 2
     temp=`mistral execution-list | grep LogicalCluster | grep RUN`
   done

   echo ""
   echo "LogicalCluster has been created"
   echo ""
   echo "Dynamic OverCloud Provisioning Complete"
   echo ""



fi





