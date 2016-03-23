local shaco = require "shaco"
local socket = require "socket"
local linenoise = require "linenoise"

shaco.start(function()
    local history_file = ".cc.history"
    local host = shaco.getenv("host") or "127.0.0.1:7997"
    local ip, port = host:match("([^:]+):?(%d+)$")
    local single_command = shaco.getenv("command")
    local id = assert(socket.connect(ip, tonumber(port)))
    socket.readenable(id, true)
    assert(socket.send(id, "controller\n"))
    assert(assert(socket.read(id, "*l")) == "ok")

    local function rpc(s)
        socket.send(id, s)
        local r = true
        while r ~= "chicken node>" do
            r = assert(socket.read(id, "*l"))
            print(r)
        end
    end
    
    if single_command then
        rpc(single_command)
        os.exit(1)
    end
    rpc("hi")
    linenoise.loadhistory(history_file)
    while true do
        local s = linenoise.linenoise("> ")
        if s == nil then
            linenoise.savehistory(history_file)
            os.exit(1)
        end
        s = string.match(s, "^%s*(.-)%s*$")
        if s ~= "" then
            rpc(s)
            linenoise.addhistory(s)
        end
    end
end)
