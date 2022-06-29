# -*- coding: utf-8 -*-
import os
import subprocess

root_path = os.path.expandvars('$HOME')
env = root_path+"/env"

subprocess.call("mkdir -p "+env, shell = True)

def yum():
    #centos8替换yum源
    subprocess.call("cd /etc/yum.repos.d/", shell = True)
    subprocess.call("rm -rf *", shell = True)
    subprocess.call("wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo", shell = True)
    subprocess.call("yum clean all && yum makecache", shell = True)
 
def python():
    #安装python3
    subprocess.call("sudo yum install python3 -y", shell = True)
    subprocess.call("pip3 install --upgrade setuptools", shell = True)
    subprocess.call("pip3 install virtualenv", shell = True)

def rely():
    #安装gcc等编译工具
    subprocess.call("yum groupinstall 'Development Tools'", shell = True)
    subprocess.call("yum install -y gcc gcc-c++ make automake", shell = True)
    subprocess.call("yum -y install autoconf", shell = True)
    subprocess.call("yum -y install readline-devel", shell = True)
    subprocess.call("yum -y install openssl-devel", shell = True)

def cmake():
    #安装cmake3.22
    cmd1 = "cd "+env
    cmd2 = "wget https://github.com/Kitware/CMake/releases/download/v3.22.0-rc2/cmake-3.22.0-rc2.tar.gz"
    cmd3 = "tar xzvf cmake-3.22.0-rc2.tar.gz"
    cmd4 = "cd cmake-3.22.0-rc2/"
    cmd5 = "./configure"
    cmd6 = "make"
    cmd7 = "make install"
    cmd = cmd1 + "&&" + cmd2 + "&&" + cmd3 + "&&" + cmd4 + "&&" + cmd5 + "&&" + cmd6 + "&&" + cmd7
    subprocess.call(cmd, shell = True)

def lua():
    #安装lua5.4
    cmd1 = "cd "+env
    cmd2 = "wget http://www.lua.org/ftp/lua-5.4.2.tar.gz"
    cmd3 = "tar zxvf lua-5.4.2.tar.gz"
    cmd4 = "cd lua-5.4.2"
    cmd5 = "make linux"
    cmd6 = "make install"
    cmd = cmd1 + "&&" + cmd2 + "&&" + cmd3 + "&&" + cmd4 + "&&" + cmd5 + "&&" + cmd6
    subprocess.call(cmd, shell = True)

def go():
    #安装go1.18.1
    cmd1 = "cd "+env
    cmd2 = "wget https://go.dev/dl/go1.18.1.linux-amd64.tar.gz"
    cmd3 = "tar -C /usr/local/ -zxvf go1.18.1.linux-amd64.tar.gz"
    cmd4 = "echo 'export GOROOT=/usr/local/go' | sudo tee -a /etc/profile"
    cmd5 = "echo 'export PATH=$PATH:$GOROOT/bin' | sudo tee -a /etc/profile"
    cmd6 = "echo 'export GOPROXY=https://goproxy.io' | sudo tee -a /etc/profile"
    cmd7 = "source /etc/profile"

    cmd = cmd1 + "&&" + cmd2 + "&&" + cmd3 + "&&" + cmd4 + "&&" + cmd5 + "&&" + cmd6 + "&&" + cmd7
    subprocess.call(cmd, shell = True)

def mongo():
    #安装mongo4.2
    repo = r"""
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc
"""
    cmd1 = "echo -e " +"\'"+ repo +"\'"+ " > /etc/yum.repos.d/mongodb-org-4.0.repo"
    cmd2 = "yum install -y mongodb-org"
    cmd3 = "systemctl start mongod"
    cmd = cmd1 + "&&" + cmd2 + "&&" + cmd3
    subprocess.call(cmd, shell = True)

def etcd1():
    #安装etcd3.5
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
    cmd1 = "cd "+env
    cmd2 = "wget https://github.com/etcd-io/etcd/releases/download/v3.5.4/etcd-v3.5.4-linux-amd64.tar.gz"
    cmd3 = "tar xzvf etcd-v3.5.4-linux-amd64.tar.gz"
    cmd4 = "mv etcd-v3.5.4-linux-amd64 etcd"
    cmd5 = "cd etcd"
    cmd6 = "cp etcd etcdctl /usr/bin"
    cmd7 = "mkdir -p /opt/etcd/"
    cmd8 = "mkdir -p /etc/etcd"
    cmd9 = "echo -e " +"\'"+ system +"\'"+ " > /usr/lib/systemd/system/etcd1.service"
    cmd10 = "echo -e " +"\'"+ config +"\'"+ " > /etc/etcd/etcd1.conf"
    cmd11 = "systemctl daemon-reload"
    cmd12 = "systemctl enable etcd1"
    cmd13 = "systemctl restart etcd1"
    cmd14 = "etcdctl --endpoints=127.0.0.1:12379 user add root <<EOF
123456
123456
EOF"
    cmd15 = "etcdctl --endpoints=127.0.0.1:12379 auth enable"

    cmd = cmd1 + "&&" + cmd2 + "&&" + cmd3 + "&&" + cmd4 + "&&" + cmd5 + "&&" + cmd6 \
            + "&&" + cmd7 + "&&" + cmd8 + "&&" + cmd9 + "&&" + cmd10 + "&&" + cmd11 + "&&" + cmd12  \
            + "&&" + cmd13 + "&&" + cmd14 + "&&" + cmd15
    subprocess.call(cmd, shell = True)

def etcd2():
    #安装etcd3.5
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
    cmd1 = "echo -e " +"\'"+ system +"\'"+ " > /usr/lib/systemd/system/etcd2.service"
    cmd2 = "echo -e " +"\'"+ config +"\'"+ " > /etc/etcd/etcd2.conf"
    cmd3 = "systemctl daemon-reload"
    cmd4 = "systemctl enable etcd2"
    cmd5 = "systemctl restart etcd2"

    cmd = cmd1 + "&&" + cmd2 + "&&" + cmd3 + "&&" + cmd4 + "&&" + cmd5
    subprocess.call(cmd, shell = True)

def etcd3():
    #安装etcd3.5
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
    cmd1 = "echo -e " +"\'"+ system +"\'"+ " > /usr/lib/systemd/system/etcd3.service"
    cmd2 = "echo -e " +"\'"+ config +"\'"+ " > /etc/etcd/etcd3.conf"
    cmd3 = "systemctl daemon-reload"
    cmd4 = "systemctl enable etcd3"
    cmd5 = "systemctl restart etcd3"

    cmd = cmd1 + "&&" + cmd2 + "&&" + cmd3 + "&&" + cmd4 + "&&" + cmd5
    subprocess.call(cmd, shell = True)

def nginx():
    #配置nginx
    config = r"""
upstream etcd{
    server  127.0.0.1:12379;
    server  127.0.0.1:22379;
    server  127.0.0.1:32379;
}
server {
    listen  2379;
    proxy_http_version 1.1;
    server_name 127.0.0.1;
    location / {
        proxy_pass http://etcd;
    }
}
"""
    cmd1 = "echo -e " +"\'"+ config +"\'"+ " > /etc/nginx/conf.d/etcd.conf"
    cmd2 = "nginx"

    cmd = cmd1 + "&&" + cmd2
    subprocess.call(cmd, shell = True)

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
