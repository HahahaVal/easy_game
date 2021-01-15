# 网关：
监听端口，管理连接，数据拆包转发到指定watchdog  

# 拆包规则：
每次接收到数据放入buffer中，从buffer中取出2字节并以大端方式作为一段完整数据的长度chunksz，最后取出chunksz字节的数据转发到指定的watchdog  