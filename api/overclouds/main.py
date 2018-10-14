from flask import Flask, request
from flask_restful import Resource, Api
from flask_restful import reqparse
from flaskext.mysql import MySQL
import configparser
import subprocess
import json
import requests


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

  provider = request.get_json()["provider"]

  if (provider == "OpenStack"):
    size = request.get_json()["size"]
    number = request.get_json()["number"]
    print (size)
    print (number) 

  elif (provider == "AWS"):
    size = request.get_json()["size"]
    number = request.get_json()["number"]

    print (size)
    print (number)

  elif (provider == "hybrid"):
    openstack = request.get_json()["OpenStack"]
    openstack_size = openstack["size"]
    openstack_number = openstack["number"]
    openstack_post = openstack["post"]

    aws = request.get_json()["AWS"]
    aws_size = aws["size"]
    aws_number = aws["number"]
    aws_post = aws["post"]

    print (openstack_size)
    print (openstack_number)
    print (openstack_post)

    print (aws_size)
    print (aws_number)
    print (aws_post)


  else:
    return "cloud provider is invalid!\n"


#  slices = request.get_json()["OpenStack"]
 
#  print (slices["Size"])
 

#  result = json.loads(slices)
#  size = result['Size']


  return "POST method"

@app.route('/overclouds', methods=['DELETE'])
def delete_overclouds():
  return "Delete method"


