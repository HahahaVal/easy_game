# proxy的网关：
处理连接，数据处理

# 接收的数据格式：  
{"data": {"now": "2021-01-04 20:44:26.176479"}, "cmd": "hello", "session": 1}  
对应的函数：  
function M.hello(now) end  

# gate服务需要收发的数据：  
接收：socket的通知  
    SOCKET_OPEN        listen_fd就绪  
    SOCKET_ACCEPT      有新的连接请求  
    SOCKET_OPEN        读写fd就绪  
    SOCKET_DATA        数据可读处理  
    
    SOCKET_CLOSE       连接关闭  
    SOCKET_CLOSE       连接关闭确定处理  
接收：watch_dog的通知  
    forward open后通知gate，设置agent  
    start   通知gate服务可以开始收发数据  
    
    kick    被动关闭连接  
    close   被动关闭连接  
发送：通知watch_dog服务  
    open    SOCKET_ACCEPT后通知watch_dog打开指定连接  
    close   SOCKET_CLOSE后通知watch关闭指定连接  
发送：通知agent服务  
    redirect   SOCKET_DATA收到数据后转发到指定agent  


watch_dog服务需要收发的数据：  
接收：gate服务的通知  
    open    设置新的连接对象  
    close   置空连接对象  
发送：通知gate服务  
    forward  open后通知gate，设置agent  
    start   forward后通知gate服务可以开始收发数据  

    kick    主动kick连接，并通知gate服务  
    close   主动close连接  
    


