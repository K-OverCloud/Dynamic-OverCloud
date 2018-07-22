#!/bin/bash
export FLASK_APP=./overclouds/main.py
source $(pipenv --venv)/bin/activate
flask run -h 0.0.0.0 -p 6126
