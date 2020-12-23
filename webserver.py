#!/usr/bin/python3

from flask import Flask, json, jsonify, request
import json
import pymysql
import secrets
import datetime
import shlex
import subprocess
from time import sleep
import os

try:
    config_file = open('config.json')
    config = json.load(config_file)
except:
    print("Error, config file not defined properly!")
    exit(1)

api = Flask(__name__)

def auth_check(request):
    headers = request.headers
    try:
        auth = headers.get("X-Api-Key")
        if auth in config['tokens']:
            return True
        else:
            return False
    except:
        return False

def query_database(query):
    db = pymysql.connect(config['mysql']['host'],config['mysql']['username'],config['mysql']['password'])
    cursor = db.cursor()
    cursor.execute(query)
    data = cursor.fetchall()
    db.close()
    return data

@api.route('/databases', methods=['GET'])
def databases():
    if not auth_check(request):
        return jsonify({"message": "ERROR: Unauthorized"}), 401

    # Get all databases
    all_databases = query_database("show databases;")
    all_databases_formatted = []
    for database in all_databases:
        all_databases_formatted.append(database[0])

    return jsonify({"databases": all_databases_formatted}), 200

@api.route('/create_database', methods=['POST'])
def create_database():
    if not auth_check(request):
        return jsonify({"message": "ERROR: Unauthorized"}), 401

    data = request.json
    if data == None:
        return jsonify({"message": "ERROR: no data or type json data given."}), 417

    if "name" not in data:
        return jsonify({"message": "ERROR: no name given in payload"}), 417

    # Create the database
    query = "CREATE DATABASE {}; ".format(data['name'])
    query_database(query)

    # Create the user
    password = secrets.token_urlsafe(20) 
    query = "CREATE USER '{}'@'%' IDENTIFIED BY '{}'; ".format(data['name'],password)
    query_database(query)

    # Grand user all rights
    query = "GRANT ALL ON {}.* TO '{}'@'%';".format(data['name'],data['name'])
    query_database(query)

    return jsonify({"database": data['name'], "username": data['name'], "password": password}), 200

@api.route('/delete_database', methods=['POST'])
def delete_database():
    if not auth_check(request):
        return jsonify({"message": "ERROR: Unauthorized"}), 401

    data = request.json
    if data == None:
        return jsonify({"message": "ERROR: no data or type json data given."}), 417

    if "name" not in data:
        return jsonify({"message": "ERROR: no name given in payload"}), 417

    # Revoke user all rights
    query = "REVOKE ALL, GRANT OPTION FROM '{}'@'%';".format(data['name'],data['name'])
    query_database(query)

    # Delete the user
    query = "DROP USER '{}'@'%'; ".format(data['name'])
    query_database(query)

    # Delete the database
    query = "DROP DATABASE {}; ".format(data['name'])
    query_database(query)

    return jsonify({"database_user_deleted": data['name']}), 200

@api.route('/create_backup', methods=['POST'])
def create_backup():
    if not auth_check(request):
        return jsonify({"message": "ERROR: Unauthorized"}), 401

    data = request.json
    if data == None:
        return jsonify({"message": "ERROR: no data or type json data given."}), 417

    if "name" not in data:
        return jsonify({"message": "ERROR: no name given in payload"}), 417

    # Start the backup
    current_date='{0:%Y-%m-%d-%H-%M-%S}'.format(datetime.datetime.now())
    backup_file="{}-{}".format(data['name'],current_date)
    cmd = "bash mysqldump.sh {} {} &".format(data['name'],backup_file)
    cmds = shlex.split(cmd)
    p = subprocess.Popen(cmds, start_new_session=True)

    # Wait two seconds
    sleep(2)
    
    # Check if backup is failed or finished
    files = os.listdir("/tmp/mysqldump/")
    if "{}.error".format(backup_file) in files:
        return jsonify({"backup_failed": backup_file}), 500
    elif "{}.pid".format(backup_file) in files:
        return jsonify({"backup_in_progress": backup_file}), 201
    else:
        return jsonify({"backup_saved_to_s3": backup_file + ".sql"}), 200

@api.route('/check_backup', methods=['GET'])
def check_backup():
    if not auth_check(request):
        return jsonify({"message": "ERROR: Unauthorized"}), 401

    data = request.json
    if data == None:
        return jsonify({"message": "ERROR: no data or type json data given."}), 417

    if "backup_file" not in data:
        return jsonify({"message": "ERROR: no backup_file given in payload"}), 417
    
    # Set the backup_file variable
    backup_file = data['backup_file']

    # Check if backup is failed or finished
    files = os.listdir("/tmp/mysqldump/")
    if "{}.error".format(backup_file) in files:
        return jsonify({"backup_failed": backup_file}), 500
    elif "{}.pid".format(backup_file) in files:
        return jsonify({"backup_in_progress": data['backup_file']}), 201
    else:
        return jsonify({"backup_saved_to_s3": data['backup_file'] + ".sql"}), 200

if __name__ == '__main__':
        api.run(host='0.0.0.0')
