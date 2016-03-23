--- todo
local shaco = require "shaco"
local socket = require "socket"
local linenoise = require "linenoise"

shaco.start(function()
    local history_file = ".cmdcli.history"
    local host = shaco.getenv("host") or "127.0.0.1:18001"
    local single_command = shaco.getenv("command")
    local id = assert(socket.connect(host))
    socket.readon(id)

    ---local function rpc(s)
    ---    while true do
    ---        print ("====")
    ---        local h = assert(socket.read(id, 2))
    ---        h = sunpack('<I2', h)
    ---        print ("rad h:",h)
    ---        local c = assert(socket.read(id, h))
    ---        if c == "." then
    ---            return
    ---        end
    ---        print(c)
    ---    end
    ---end
    
    local function interact()
        if not id then
            id = assert(socket.connect(host))
            socket.readon(id)
        end
        shaco.fork(function()
            while true do
                local data = assert(socket.read(id))
                print (data)
            end
        end)
        local stdin = assert(socket.stdin())
        while true do
            local s = linenoise.read(function()
                return socket.read(stdin, 1)
            end)
            if s == nil then
                linenoise.savehistory(history_file)
                os.exit(1)
            end
            s = string.match(s, "^%s*(.-)%s*$")
            if s ~= "" then
                socket.send(id, s..'\n')
            end
        end
        linenoise.savehistory(history_file)
    end

    if single_command then
        print ("not support now")
        --rpc(single_command)
        os.exit(1)
    end
    --rpc("hi")
    linenoise.loadhistory(history_file)
    while true do
        local ok, err = pcall(interact)
        if not ok then
            print ('[error]'..err..', wait to connect ...')
            shaco.sleep(1000)
            socket.close(id)
            id = nil
        end
    end
end)
