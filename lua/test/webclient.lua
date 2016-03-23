local shaco = require "shaco"
local http = require "http"
local tbl = require "tbl"
local cjson = require "cjson"

shaco.start(function()
	--local code, body = http.get("http://sdk.test4.g.uc.cn/cp/account.verifySession", "/")
 --   print (code)
  --  print(body)
	--[[ local root = "../html/"
    local host = "http://sdk.test4.g.uc.cn/cp/account.verifySession"
	local headers = {["content-type"] = "application/json" }

	--local host = shaco.getenv("host") or "127.0.0.1:1234"
    local uri  = shaco.getenv("uri") or "/"
	local f = io.open(root.."index.json")
    local s = f:read("*a")
	print("s-===================  ")
	local t = cjson.decode(s)
    local value = t
	for k, v in pairs(t) do
        if type(v) == "table" then
            tbl.print(v, k) 
        else
            print(k..":"..v) 
        end 
    end
	tbl.print(value,"-------------------  value ======= ")
	local code, body = http.get(host, uri, headers, value)
    print (code, body)
	
	]]
	
	
	--[[
	--http://sdk.g.uc.cn/cp/account.verifySession
	local root = "../html/"
    local host = "sdk.test4.g.uc.cn"
	local headers = {["content-type"] = "application/json" }

	--local host = shaco.getenv("host") or "127.0.0.1:1234"
    local uri  = shaco.getenv("uri") or "/cp/account.verifySession"
	--local f = io.open(root.."index.json")
   -- local s = f:read("*a")
    --print ("s="..s)
	local sid = "ssh1game9c76aa0a6b49466b941406ba25cc4727146910"
    local value = '{"id":63235,"game":{"gameId":666956},"data":{"sid":"'..sid..'"},"sign":"71a2d4cf2f449186b16c32dea35e6615"}'
	--local t = cjson.decode(s)
    --local value = t
	--for k, v in pairs(t) do
    --    if type(v) == "table" then
    --        tbl.print(v, k) 
    --    else
    --        print(k..":"..v) 
    --    end 
    --end
	--tbl.print(value,"-------------------  value ======= ")
	print ("value ="..value)
    print (host)
    print (uri)
	local code, body = http.get(host, uri, headers, value)
    print (code, body)
	local t = cjson.decode(body)
	local test = {}
    for k, v in pairs(t) do
		if type(v) == "table" then
            test[""..k] = v
        else
            print(k..":"..v) 
        end 
     end
	tbl.print(test.state,"test ===== ")
	print("test.state ==== "..test.state.msg)
	if test.state.msg == "操作成功" then
		print("creator === "..test.data.creator)
		print("accountId === "..test.data.accountId)
		print("nickName === "..test.data.nickName)
	end
	]]
	
	
	local root = "../html/"
    local host = "openapi.360.cn"
	local headers = {["content-type"] = "application/json" }
	local uri  = shaco.getenv("uri") or "/user/me.json"
	--local value = '{"id":'.._time..',"game":{"gameId":666956},"data":{"sid":"'..sid..'"},"sign":"'..sign..'"}'
	local value = '{"access_token",265314343157960136a2a0417ef24576b94437e66b9b176115}'
	local code, body = http.get(host, uri, headers, value)
    print (code, body)
	
   --[[local code, body = http.get(host, uri)
    print(body)
    if mode == "get" then
        local code, body = http.get(host, uri)
        print(code)
        print(body)
        if body:byte(1) == 123 then -- "{"
            local t = cjson.decode(body)
            for k, v in pairs(t) do
                if type(v) == "table" then
                    tbl.print(v, k) 
                else
                    print(k..":"..v) 
                end 
            end
        end
    else
        local code, body = http.pos(host, uri, nil, {b='abc'})
        print (code, body)
    end]]
    os.exit(1)
end)
