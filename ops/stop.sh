#! /bin/bash

function log_fail(){
    echo "关服超时, 请检查服务器状态"
}

SCRIPT_DIR="$( cd "$(dirname $0)" && pwd )"
SERVER_DIR="$(dirname $SCRIPT_DIR)"
server="game"

config=$SERVER_DIR/${server}/etc/game_config
console_port=$(grep "console_port" $config | awk '{print $3}' | sed "s/\"//g")
stop_info=$(grep "sign_msg" $config | awk '{print $3}' | sed "s/\"//g")

inject_addr=$(echo "list" | nc 127.0.0.1 $console_port -w 1 |grep "hall" | awk '{print $1}')
echo "inject $inject_addr $SCRIPT_DIR/shutdown.lua" | nc 127.0.0.1 $console_port -w 1


function check_success(){
    wait_sec=5
    while [ $wait_sec -ge 0 ]; do
        if [ $(expr $wait_sec % 2) -eq 0 ]; then
            echo "停服中..."
        fi
        let wait_sec-=1
        if [ -f "$stop_info" ]; then            
            stop_msg=$(head $stop_info 2>/dev/null)
            if [ ! -z "$stop_msg" ]; then
                stop_ok=$(echo $stop_msg | fgrep _stop_ok_)
                echo "关服成功"
                exit 0
            fi
        fi
        sleep 1
    done
    log_fail
    exit 0 
}

check_success