local shaco = require "shaco"
local socket = require "socket"
local tbl = require "tbl"

shaco.start(function()
    local code, body = http.get("www.baidu.com", "/")
    print (code)
    print(body)
end)
