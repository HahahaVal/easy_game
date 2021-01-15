# easy_frame
一个基于skynet的简单服务器框架，实现了以下功能：
* log服务：记录运行日志  
* monitor服务：管理所有服务，开服和关服的流程控制  
* gate网关服务：监听端口，管理连接，数据拆包转发到指定watchdog  
* proxy服务：用于接收json格式的数据并执行对应的函数  
* role_db服务：使用lru缓存玩家数据，读写mongo数据库  
* hall服务：分配和释放agent池,管理所有user，根据fd处理sproto协议  
* agent服务：多个role公用一个agent，根据fd找到指定role处理sproto协议  

# 编译
make clean  
make

# 启动
前台启动：./ops/start.sh  
后台启动：./ops/start.sh -d  

# 关闭
./ops/stop.sh  

# 测试
详细看tools的README  


# 热更
编写服务模块遵循一定的规则： 数据和函数分离  
用法参考stop.sh  

