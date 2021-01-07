#coding=utf-8
from gevent.pywsgi import WSGIServer

if __name__ == '__main__':
    from webapp import app, config
    port = int(config['app']['port'])
    http_server = WSGIServer(('', port), app)
    http_server.serve_forever()