# -*- coding: utf-8 -*-
import os
import subprocess

root_path = os.path.expandvars('$HOME')
env = root_path+"/env"

subprocess.call("mkdir -p "+env, shell = True)

def yum():
    #centos7替换yum源
    subprocess.call("wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo", shell = True)

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

def main():
    yum()
    python()
    rely()
    cmake()
    lua()
    mongo()

if __name__ == "__main__":
    main()
