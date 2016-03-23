local shaco = require "shaco"
local socket = require "socket"
local ssl = require "ssl"

shaco.start(function()
    --local uri = "/user/me.json"
    local uri = "/user/me.json?access_token=2653955205c7e9fe3fa50665fce8a995a9d252876ccf85096d"
    local host = "openapi.360.cn"
    local headers = {["Content-Type"]="application/json", charset="utf-8"}
    local form = nil--{access_token="26538037411bf254c69c509624e328652185ade73a146df699"}
    local port = 443
    local id = assert(socket.connect(host, port))
    print ("socket id:"..id)
    socket.readenable(id, true)

    local ok, err = pcall(function()
        local code, body = ssl.request(id, host, uri, headers, form)
        print ("[code] "..code)
        print ("[body]")
        print(body)
    end)
    print ("socket close")
    socket.close(id)
    if not ok then
        print (err)
    end
end)
