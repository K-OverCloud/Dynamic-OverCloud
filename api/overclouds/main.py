from flask import Flask, request
from flask_restful import Resource, Api
from flask_restful import reqparse
from flaskext.mysql import MySQL
import configparser
import subprocess
import json
import uuid
import requests
from collections import defaultdict

app = Flask(__name__)
api = Api(app)


# get the MySQL HOST from init.conf
config = configparser.ConfigParser()
config.read('../configuration/init.ini')
Host= config.get('database','MySQL_HOST')

# get the MySQL PASS from init.conf
Pass= config.get('database','MySQL_PASS')


mysql = MySQL()

# MySQL Config
app.config['MYSQL_DATABASE_USER'] ='overclouds'
app.config['MYSQL_DATABASE_PASSWORD'] = Pass
app.config['MYSQL_DATABASE_DB'] = 'overclouds'
app.config['MYSQL_DATABASE_HOST'] = Host

mysql.init_app(app)


@app.route("/")
def dynamic_overcloud():
  return "Dynamic OverCloud v1.0"


@app.route("/overclouds")
def show_overclouds():

  # JSON 
  #  slices_id = request.get_json()["Slice_ID"]
  #  MAC = request.get_json()["MAC"]


  cur = mysql.connect().cursor()
  cur.execute("select * from overcloud")

  result = []

  columns = tuple( [d[0] for d in cur.description])
 
  for row in cur:
    result.append(dict(zip(columns, row)))

  print(result)

  return json.dumps(result)


@app.route('/overclouds', methods=['POST'])
def create_overclouds():


  # Create OverCloud ID
  ID=(str)(uuid.uuid4())
  #ID="EDogZKrYZ3EcC83"

  provider = request.get_json()["provider"]

  if (provider == "OpenStack"):
    size = request.get_json()["size"]
    number = request.get_json()["number"]
    print (size)
    print (number) 

    #execute Workflow

    cmd="cd ../workflows && bash instantiation.sh " + ID + " OpenStack " + number + " " + size 
    print (cmd)
    #return ("End")
    result = subprocess.check_output (cmd , shell=True)
    #return ("End")
    



    # Ready for JSON file
    d1 = defaultdict(list)

    d1["overcloud_ID"] = ID


    # find devops IP
    cmd ="select * from devops_post where overcloud_ID='"
    cmd = cmd + ID + "';"

    cur = mysql.connect().cursor()
    cur.execute(cmd)
    rows = cur.fetchall()
    
    devops_IP= str(rows[0][0])
    #print (devops_IP)
    d1['devops_post'] = devops_IP
 

    # find logical cluster IP
    cmd ="select * from logical_cluster where overcloud_ID='"
    cmd = cmd + ID + "';"
    
    cur = mysql.connect().cursor()
    cur.execute(cmd)
    rows = cur.fetchall()
   

    for row in rows:     
      d1["logical_cluster"].append(row[0])



    # Find SSH
    cmd="../configuration/ssh/"
    cmd=cmd + ID
    cmd=cmd + ".key"
    #print (cmd)

    out = subprocess.Popen(['cat', cmd], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    stdout,stderr = out.communicate()

    response= stdout.decode()
    response=response.replace("\n","")

    d1["ssh"] = response



    # Weave Scope
    cmd="http://" + devops_IP + ":32080"
    d1["weave_url"] = cmd

    # Chronograf 
    cmd="http://" + devops_IP +":8888"
    d1["chronograf_url"] = cmd
     

    # Prometheus

    cmd="ssh -o 'StrictHostKeyChecking = no' -i ../configuration/ssh/"+ ID +".key ubuntu@" + devops_IP + " kubectl get svc | grep prometheus | grep NodePort | awk '{print $5}' | cut -d':' -f2 | cut -d'/' -f1"

    result = subprocess.check_output (cmd , shell=True)
    
    #out = subprocess.Popen(['ssh', shell=True], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    #stdout,stderr = out.communicate()

    response= result.decode()
    response=response.replace("\n","")
    cmd="http://" + devops_IP + ":" + response
    d1["prometheus_url"] = cmd



    print(json.dumps(d1, ensure_ascii=False, indent="\t") )

    return (json.dumps(d1, ensure_ascii=False, indent="\t"))




  elif (provider == "Amazon"):
    size = request.get_json()["size"]
    number = request.get_json()["number"]

    print (size)
    print (number)


    #execute Workflow

    cmd="cd ../workflows && bash amazon.sh " + ID + " Amazon " + number + " " + size
    print (cmd)
    #return ("End")
    result = subprocess.check_output (cmd , shell=True)
    #return ("End")


    
    # Ready for JSON file
    d1 = defaultdict(list)

    d1["overcloud_ID"] = ID


    # find devops IP
    cmd ="select * from devops_post where overcloud_ID='"
    cmd = cmd + ID + "';"

    cur = mysql.connect().cursor()
    cur.execute(cmd)
    rows = cur.fetchall()

    devops_IP= str(rows[0][0])
    #print (devops_IP)
    d1['devops_post'] = devops_IP


    # find logical cluster IP
    cmd ="select * from logical_cluster where overcloud_ID='"
    cmd = cmd + ID + "';"

    cur = mysql.connect().cursor()
    cur.execute(cmd)
    rows = cur.fetchall()


    for row in rows:
      d1["logical_cluster"].append(row[0])



    # Find SSH
    cmd="../configuration/ssh/"
    cmd=cmd + ID
    cmd=cmd + ".key"
    #print (cmd)

    out = subprocess.Popen(['cat', cmd], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    stdout,stderr = out.communicate()

    response= stdout.decode()
    response=response.replace("\n","")

    d1["ssh"] = response



    # Weave Scope
    cmd="http://" + devops_IP + ":32080"
    d1["weave_url"] = cmd

    # Chronograf
    cmd="http://" + devops_IP +":8888"
    d1["chronograf_url"] = cmd


    # Prometheus

    cmd="ssh -o 'StrictHostKeyChecking = no' -i ../configuration/ssh/"+ ID +".key ubuntu@" + devops_IP + " kubectl get svc | grep prometheus | grep NodePort | awk '{print $5}' | cut -d':' -f2 | cut -d'/' -f1"

    result = subprocess.check_output (cmd , shell=True)

    #out = subprocess.Popen(['ssh', shell=True], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    #stdout,stderr = out.communicate()

    response= result.decode()
    response=response.replace("\n","")
    cmd="http://" + devops_IP + ":" + response
    d1["prometheus_url"] = cmd



    print(json.dumps(d1, ensure_ascii=False, indent="\t") )

    return (json.dumps(d1, ensure_ascii=False, indent="\t"))


    


  elif (provider == "heterogeneous"):
    openstack = request.get_json()["OpenStack"]
    openstack_size = openstack["size"]
    openstack_number = openstack["number"]
    openstack_post = openstack["post"]

    aws = request.get_json()["Amazon"]
    aws_size = aws["size"]
    aws_number = aws["number"]
    aws_post = aws["post"]

    print (openstack_size)
    print (openstack_number)
    print (openstack_post)

    print (aws_size)
    print (aws_number)
    print (aws_post)

    devops=""
    if (openstack_post == "yes"):
      devops="OpenStack"
    else:
      devops="Amazon"

    #execute Workflow

    cmd="cd ../workflows && bash heterogeneous.sh " + ID + " " + openstack_number + " " + aws_number + " " + openstack_size + " " + aws_size + " " + devops
    print (cmd)
    #return ("End")
    result = subprocess.check_output (cmd , shell=True)
    #return ("End")



    # Ready for JSON file
    d1 = defaultdict(list)

    d1["overcloud_ID"] = ID


    # find devops IP
    cmd ="select * from devops_post where overcloud_ID='"
    cmd = cmd + ID + "';"

    cur = mysql.connect().cursor()
    cur.execute(cmd)
    rows = cur.fetchall()

    devops_IP= str(rows[0][0])
    #print (devops_IP)
    d1['devops_post'] = devops_IP


    # find logical cluster IP
    cmd ="select * from logical_cluster where overcloud_ID='"
    cmd = cmd + ID + "';"

    cur = mysql.connect().cursor()
    cur.execute(cmd)
    rows = cur.fetchall()


    for row in rows:
      d1["logical_cluster"].append(row[0])



    # Find SSH
    cmd="../configuration/ssh/"
    cmd=cmd + ID
    cmd=cmd + ".key"
    #print (cmd)

    out = subprocess.Popen(['cat', cmd], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    stdout,stderr = out.communicate()

    response= stdout.decode()
    response=response.replace("\n","")

    d1["ssh"] = response



    # Weave Scope
    cmd="http://" + devops_IP + ":32080"
    d1["weave_url"] = cmd

    # Chronograf
    cmd="http://" + devops_IP +":8888"
    d1["chronograf_url"] = cmd


    # Prometheus

    cmd="ssh -o 'StrictHostKeyChecking = no' -i ../configuration/ssh/"+ ID +".key ubuntu@" + devops_IP + " kubectl get svc | grep prometheus | grep NodePort | awk '{print $5}' | cut -d':' -f2 | cut -d'/' -f1"

    result = subprocess.check_output (cmd , shell=True)

    #out = subprocess.Popen(['ssh', shell=True], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    #stdout,stderr = out.communicate()

    response= result.decode()
    response=response.replace("\n","")
    cmd="http://" + devops_IP + ":" + response
    d1["prometheus_url"] = cmd



    print(json.dumps(d1, ensure_ascii=False, indent="\t") )

    return (json.dumps(d1, ensure_ascii=False, indent="\t"))




    #return ("hybrid is not supported yet\n")

  else:
    return "cloud provider is invalid!\n"



  return "POST method"

@app.route('/overclouds', methods=['DELETE'])
def delete_overclouds():

  overcloud_id = request.get_json()["overcloud_id"]
  print (overcloud_id)
  
  #execute Workflow

  cmd="cd ../workflows && bash delete_overcloud.sh " + overcloud_id
  print (cmd)
  #return ("End")
  result = subprocess.check_output (cmd , shell=True)
  #return ("End")
  

  return "Success\n"


