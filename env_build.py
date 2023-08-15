# -*- coding: utf-8 -*-
import os
import subprocess

root_path = os.path.expandvars('$HOME')
env = root_path+"/env"

subprocess.call("mkdir -p "+env, shell=True)


def yum():
    # centos8替换yum源
    cmds = [
        "cd /etc/yum.repos.d/",
        "rm -rf *",
        "wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo",
        "yum clean all && yum makecache",
    ]
    cmd = "&&".join(cmds)
    subprocess.call(cmd, shell=True)


def python():
    # 安装python3
    cmds = [
        "sudo yum install python3 -y",
        "pip3 install --upgrade setuptools",
        "pip3 install virtualenv",
    ]
    cmd = "&&".join(cmds)
    subprocess.call(cmd, shell=True)


def rely():
    # 安装gcc等编译工具
    cmds = [
        "yum groupinstall 'Development Tools'",
        "yum install -y gcc gcc-c++ make automake",
        "yum -y install autoconf",
        "yum -y install readline-devel",
        "yum -y install openssl-devel",
    ]
    cmd = "&&".join(cmds)
    subprocess.call(cmd, shell=True)


def cmake():
    # 安装cmake3.22
    cmds = [
        "cd "+env,
        "wget https://github.com/Kitware/CMake/releases/download/v3.22.0-rc2/cmake-3.22.0-rc2.tar.gz",
        "tar xzvf cmake-3.22.0-rc2.tar.gz",
        "cd cmake-3.22.0-rc2/",
        "./configure",
        "make",
        "make install",

    ]
    cmd = "&&".join(cmds)
    subprocess.call(cmd, shell=True)


def lua():
    # 安装lua5.4
    cmds = [
        "cd "+env,
        "wget http://www.lua.org/ftp/lua-5.4.2.tar.gz",
        "tar zxvf lua-5.4.2.tar.gz",
        "cd lua-5.4.2",
        "make linux",
        "make install",
    ]
    cmd = "&&".join(cmds)
    subprocess.call(cmd, shell=True)


def go():
    # 安装go1.18.1
    cmds = [
        "cd "+env,
        "wget https://go.dev/dl/go1.18.1.linux-amd64.tar.gz",
        "tar -C /usr/local/ -zxvf go1.18.1.linux-amd64.tar.gz",
        "echo 'export GOROOT=/usr/local/go' | sudo tee -a /etc/profile",
        "echo 'export PATH=$PATH:$GOROOT/bin' | sudo tee -a /etc/profile",
        "echo 'export GOPROXY=https://goproxy.io' | sudo tee -a /etc/profile",
        "source /etc/profile",
    ]
    cmd = "&&".join(cmds)
    subprocess.call(cmd, shell=True)


def mongo():
    # 安装mongo4.2
    repo = r"""
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc
"""
    cmds = [
        "echo -e "+"\'"+repo+"\'"+" > /etc/yum.repos.d/mongodb-org-4.0.repo",
        "yum install -y mongodb-org",
        "systemctl start mongod",
    ]
    cmd = "&&".join(cmds)
    subprocess.call(cmd, shell=True)


def etcd1():
    # 安装etcd3.5
    system = r"""
[Unit]
Description=Etcd Server
After=network.target

[Service]
Type=simple
EnvironmentFile=-/etc/etcd/etcd1.conf
ExecStart=/usr/bin/etcd
Restart=on-failure

[Install]
WantedBy=multi-user.target
"""
    config = r"""
ETCD_NAME=etcd1
ETCD_DATA_DIR="/opt/etcd/default1.etcd"
ETCD_LISTEN_CLIENT_URLS="http://127.0.0.1:12379"
ETCD_ADVERTISE_CLIENT_URLS="http://127.0.0.1:12379"

ETCD_LISTEN_PEER_URLS="http://127.0.0.1:12380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://127.0.0.1:12380"
ETCD_INITIAL_CLUSTER="etcd1=http://127.0.0.1:12380,etcd2=http://127.0.0.1:22380,etcd3=http://127.0.0.1:32380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
"""
    cmds = [
        "cd "+env,
        "wget https://github.com/etcd-io/etcd/releases/download/v3.5.4/etcd-v3.5.4-linux-amd64.tar.gz",
        "tar xzvf etcd-v3.5.4-linux-amd64.tar.gz",
        "mv etcd-v3.5.4-linux-amd64 etcd",
        "cd etcd",
        "cp etcd etcdctl /usr/bin",
        "mkdir -p /opt/etcd/",
        "mkdir -p /etc/etcd",
        "echo -e "+"\'"+system+"\'"+" > /usr/lib/systemd/system/etcd1.service",
        "echo -e "+"\'"+config+"\'"+" > /etc/etcd/etcd1.conf",
        "systemctl daemon-reload",
        "systemctl enable etcd1",
        "systemctl restart etcd1",
        "etcdctl --endpoints=127.0.0.1:12379 user add root <<EOF\n123456\n123456\nEOF",
        "etcdctl --endpoints=127.0.0.1:12379 auth enable",
    ]
    cmd = "&&".join(cmds)
    subprocess.call(cmd, shell=True)


def etcd2():
    # 安装etcd3.5
    system = r"""
[Unit]
Description=Etcd Server
After=network.target

[Service]
Type=simple
EnvironmentFile=-/etc/etcd/etcd2.conf
ExecStart=/usr/bin/etcd
Restart=on-failure

[Install]
WantedBy=multi-user.target
"""
    config = r"""
ETCD_NAME=etcd2
ETCD_DATA_DIR="/opt/etcd/default2.etcd"
ETCD_LISTEN_CLIENT_URLS="http://127.0.0.1:22379"
ETCD_ADVERTISE_CLIENT_URLS="http://127.0.0.1:22379"

ETCD_LISTEN_PEER_URLS="http://127.0.0.1:22380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://127.0.0.1:22380"
ETCD_INITIAL_CLUSTER="etcd1=http://127.0.0.1:12380,etcd2=http://127.0.0.1:22380,etcd3=http://127.0.0.1:32380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
"""
    cmds = [
        "echo -e "+"\'"+system+"\'"+" > /usr/lib/systemd/system/etcd2.service",
        "echo -e "+"\'"+config+"\'"+" > /etc/etcd/etcd2.conf",
        "systemctl daemon-reload",
        "systemctl enable etcd2",
        "systemctl restart etcd2",
    ]
    cmd = "&&".join(cmds)
    subprocess.call(cmd, shell=True)


def etcd3():
    # 安装etcd3.5
    system = r"""
[Unit]
Description=Etcd Server
After=network.target

[Service]
Type=simple
EnvironmentFile=-/etc/etcd/etcd3.conf
ExecStart=/usr/bin/etcd
Restart=on-failure

[Install]
WantedBy=multi-user.target
"""
    config = r"""
ETCD_NAME=etcd3
ETCD_DATA_DIR="/opt/etcd/default3.etcd"
ETCD_LISTEN_CLIENT_URLS="http://127.0.0.1:32379"
ETCD_ADVERTISE_CLIENT_URLS="http://127.0.0.1:32379"

ETCD_LISTEN_PEER_URLS="http://127.0.0.1:32380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://127.0.0.1:32380"
ETCD_INITIAL_CLUSTER="etcd1=http://127.0.0.1:12380,etcd2=http://127.0.0.1:22380,etcd3=http://127.0.0.1:32380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
"""
    cmds = [
        "echo -e "+"\'"+system+"\'"+" > /usr/lib/systemd/system/etcd3.service",
        "echo -e "+"\'"+config+"\'"+" > /etc/etcd/etcd3.conf",
        "systemctl daemon-reload",
        "systemctl enable etcd3",
        "systemctl restart etcd3",
    ]
    cmd = "&&".join(cmds)
    subprocess.call(cmd, shell=True)


def nginx():
    # 配置nginx
    config = r"""
upstream etcd{
    server  127.0.0.1:12379;
    server  127.0.0.1:22379;
    server  127.0.0.1:32379;
    keepalive 10000;
}
server {
    listen  2379;
    server_name 127.0.0.1;
    location / {
        proxy_http_version 1.1;
        proxy_connect_timeout 15;
        proxy_read_timeout 1000;
        proxy_send_timeout 1000;
        proxy_pass http://etcd;
    }
}
"""
    cmds = [
        "echo -e "+"\'"+config+"\'"+" > /etc/nginx/conf.d/etcd.conf",
        "nginx"
    ]
    cmd = "&&".join(cmds)
    subprocess.call(cmd, shell=True)


def main():
    yum()
    python()
    rely()
    cmake()
    lua()
    go()
    mongo()
    etcd1()
    etcd2()
    etcd3()
    nginx()


if __name__ == "__main__":
    main()
