local function hello()
	local resp = player:call("hello.hello",{client_time = os.time()})
    print(resp.server_time)
end

test({
    hello,
})
 