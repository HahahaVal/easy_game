# tool测试工具

# jsclient
监听一个端口，通过http get方式去请求游戏服  

修改配置文件 web.conf，并执行以下命令：  
    source env/bin/activate  
    python3 main.py  

# robot
机器人，模拟玩家登陆  

修改配置文件config，指定要登陆的玩家和要执行的脚本script，在script中编写要执行的指令  
    lua main  