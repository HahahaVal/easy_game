# -*- coding: utf-8 -*-
import os
import subprocess

root_path = os.path.expandvars('$HOME')
env = root_path+"/env"

subprocess.call("mkdir -p "+env, shell = True)

def main():
    python()
    rely()
    cmake()
    lua()

def python():
    subprocess.call("pip3 install virtualenv", shell = True)

def rely():
    subprocess.call("yum groupinstall 'Development Tools'", shell = True)
    subprocess.call("yum install -y gcc gcc-c++ make automake", shell = True)
    subprocess.call("yum -y install autoconf", shell = True)
    subprocess.call("yum -y install readline-devel", shell = True)
    subprocess.call("yum -y install openssl-devel", shell = True)

def cmake():
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
    cmd1 = "cd "+env
    cmd2 = "wget http://www.lua.org/ftp/lua-5.4.2.tar.gz"
    cmd3 = "tar zxvf lua-5.4.2.tar.gz"
    cmd4 = "cd lua-5.4.2"
    cmd5 = "make linux"
    cmd6 = "make install"
    cmd = cmd1 + "&&" + cmd2 + "&&" + cmd3 + "&&" + cmd4 + "&&" + cmd5 + "&&" + cmd6
    subprocess.call(cmd, shell = True)
    
if __name__ == "__main__":
    main()
