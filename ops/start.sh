#! /bin/bash

function log_fail(){
    echo "启动失败： " $1
}

SCRIPT_DIR="$( cd "$(dirname $0)" && pwd )"
SERVER_DIR="$(dirname $SCRIPT_DIR)"

server="game"
daemon=$1

skynet=$SERVER_DIR/bin/skynet
config=$SERVER_DIR/${server}/etc/game_config

start_info=$(grep "start_msg" $config | awk '{print $3}' | sed "s/\"//g")

function check_success(){
    wait_sec=5
    while [ $wait_sec -ge 0 ]; do
        if [ $(expr $wait_sec % 2) -eq 0 ]; then
            echo "启动中..."
        fi
        let wait_sec-=1
        if [ -f "$start_info" ]; then            
            start_msg=$(head $start_info 2>/dev/null)
            if [ ! -z "$start_msg" ]; then
                break
            fi
        fi
        sleep 1
    done
    
    start_ok=$(echo $start_msg | fgrep _start_ok_)
    if [ -z "$start_ok" ]; then
        log_fail "$start_msg"
        exit 1
    else
        echo "启动成功"
    fi
}

echo -e "\n准备启服: type:$server start_info:$start_info"
if [ "$daemon" == "-d" ];then
    [ -f "$start_info" ] && rm $start_info
    nohup $skynet $config 1>/dev/null 2>&1 &
    check_success
else
    $skynet $config
fi