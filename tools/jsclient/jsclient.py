from gevent import socket

import json
import struct
import sys
from configparser import ConfigParser
config = ConfigParser()
config.read('web.conf')


host = config['target_server']['host']
port = int(config['target_server']['port'])

session = 0

def send_data(cmd, data):
    s = socket.socket()
    try:
        s.connect((host, port))
    except socket.error as e:
        print('Connection refused:', host, port, data, file=sys.stderr)
        return False

    global session
    
    session += 1
    string = json.dumps(dict(data=data, cmd=cmd, session=session)).encode('utf8')
    byte = struct.pack('>H', len(string)) + string
    s.send(byte)
    return True
