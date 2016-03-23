local shaco = require "shaco"
local http = require "http"
local tbl = require "tbl"
local socket = require "socket"
local cjson = require "cjson"
local crypt = require "crypt.c"
local rcall = shaco.callum
local sfmt = string.format
local find = string.find
local sub = string.sub
local len = string.len
local request_handle
local __rsap = crypt.rsa_new("./100148_SignKey.pub", true)
local result = {'{"code":"0","tips":"接受成功"}','{"code":"1","tips":"接受失败"}'}

shaco.start(function()
    --local host = shaco.getenv("billinghost") or "0.0.0.0:1234"
    local function handle_request(id)
      --  print ("accept", id)
        socket.start(id)
        socket.readon(id)
        local code, method, uri, head_t, body = http.read(id)
       -- print(code, method, uri, head_t, body)
        local t = cjson.decode(body)
        local value = t
        local recharge = {}
        for k, v in pairs(t) do
            if type(v) == "table" then
                --tbl.print(v, k) 
            else
                recharge[""..k] = v
                --tbl.print(v, k) 
            end 
        end
        --tbl.print(recharge, "init recharge", shaco.trace)
        local s_in = crypt.base64decode(recharge.verifystring)
        s_in = __rsap:public_decrypt(s_in)
        
        local indx = 1
        local sign = recharge.florderid.."|"..recharge.orderid.."|"..recharge.productid.."|"..recharge.cardno.."|"..
                    recharge.amount.."|"..recharge.ret.."|"..recharge.cardstatus.."|"..recharge.merpriv
        if sign == s_in then
            indx = 2
        end
        code = 200
        head_t = {}
        head_t["content-type"] = "text/html; charset=utf8"
        http.response(id, code, result[indx], head_t)
        socket.shutdown(id)
        local err = 0
        if indx == 1 then
            err = rcall(request_handle, "B.Success", recharge)
        else
            err = rcall(request_handle, "B.Fail", recharge)	
        end
    end

    local CMD = {}

    function CMD.open(conf)
        local host = assert(conf.address, "No listen address")
        request_handle = assert(conf.request_handle, "No request handle")
        assert(socket.listen(host, handle_request))
        shaco.info("billing listen on "..host)
    end

    shaco.dispatch('lua', function(source, session, cmd, ...)
        local f = CMD[cmd]
        if f then
            shaco.ret(shaco.pack(f(...)))
        end
    end)
end)
