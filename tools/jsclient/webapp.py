#coding=utf-8
from gevent import monkey, spawn
monkey.patch_all()

from datetime import datetime

from flask import Flask
from flask import render_template, jsonify
from flask import request
app = Flask(__name__)

from configparser import ConfigParser
config = ConfigParser()
config.read('web.conf')


from jsclient import send_data

@app.route('/hello', methods=['GET'])
def hello():
   cmd = "hello"
   data = dict(now=str(datetime.now()))
   successful = send_data(cmd,data)
   print("hello: ",successful)
   return jsonify(ret=successful)

@app.route('/shutdown', methods=['GET'])
def shutdown():
   cmd = "shutdown"
   data = dict(now=str(datetime.now()))
   successful = send_data(cmd,data)
   print("shutdown: ",successful)
   return jsonify(ret=successful)