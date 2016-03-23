local shaco = require "shaco"
local socket = require "socket"
local pb = require "protobuf"
local MRES = require "msg_resname"
local MREQ = require "msg_reqname"
MREQ[IDUM_TEXT] = "UM_TEXT"

pb.register_file("../res/pb/enum.pb")
pb.register_file("../res/pb/struct.pb")
pb.register_file("../res/pb/msg_client.pb")

local pack_size = shaco.getnum("pack_size")

print ("pack_size:"..pack_size)
local MSG = string.rep("1",pack_size).."\n"

local client_count = shaco.getnum("client_count")
local pack_count = shaco.getnum("pack_count")
local stat = 0
local start_time

local function encode(mid, v)
    local s = pb.encode(MREQ[mid], v)
    local l = #s+2
    return string.char(l&0xff, (l>>8)&0xff)..
        string.char(mid&0xff, (mid>>8)&0xff)..s
end

local function decode(s)
    local mid = string.byte(s,1,1)|(string.byte(s,2,2)<<8)
    return mid, pb.decode(MREQ[mid], string.sub(s,3))
end
 
local function client(uid)
    coroutine.yield()

    local id = assert(socket.connect("127.0.0.1",1234))
    socket.readenable(id, true)

    local v = {str=MSG}
    while true do
        socket.send(id, encode(IDUM_TEXT, v))
        local h = assert(socket.read(id, "*2"))
        local s = assert(socket.read(id, h))
        local mid, r = decode(s)
        assert(mid == IDUM_TEXT)
        stat = stat+1
        if stat == pack_count then
            stat = 0
            local now = shaco.now()
            print (string.format("client_count=%d,pack_count=%d, pack_size=%d, use time=%d, pqs=%.02f", 
                client_count, pack_count, pack_size, now-start_time, pack_count/(now-start_time)*1000))
            start_time = now
        end
    end
end

local function fork(f,...)
    local co = coroutine.create(f)
    assert(coroutine.resume(co, ...))
    return co
end

local function wakeup(co, ...)
    assert(coroutine.resume(co, ...))
end

shaco.start(function()
    local t = {}
    for i=1, client_count do
        local co = fork(client,i)
        table.insert(t,co)
    end
    start_time = shaco.now()
    for _, co in ipairs(t) do
        wakeup(co)
    end
end)
