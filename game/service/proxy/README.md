# proxy服务
接收json格式的数据，并执行对应的函数

# 接收的数据格式：
```lua
{"data": {"now": "2021-01-04 20:44:26.176479"}, "cmd": "hello", "session": 1}  
```
# 对应的处理函数：  
```lua
function M.hello(now) end
```