local shaco = require "shaco"
local gateserver = require "gateserver"
local socket = require "socket.c"
local pb = require "protobuf"
local sformat = string.format
local spack = string.pack
local sunpack = string.unpack
local ssub = string.sub
local chan = require "chan"
require "msg_error"
require "msg_client"
require "msg_server"

local connection = {}
local request_handle
local livetime = 60*1000

local function sendpackage(id, data)
    gateserver.send(id, spack('<s2', data))
end

local function route2client(connid, msgid, msg)
    sendpackage(connid, spack('<I2', msgid)..msg)
end

local function send2client(connid, msgid, name, value)
    route2client(connid, msgid, pb.encode(name, value))
end

local function send2handle(handle, connid, msgid, name, value)
    shaco.sendum(handle, IDUM_GATE, connid, msgid, pb.encode(name, value))
end

local handle = {}

function handle.connect(id, addr)
    shaco.trace("Conn "..id, addr)
    gateserver.openclient(id)
    -- todo 登录超时
    connection[id] = {
        address = addr,
        connect_time = shaco.now(),
        logined = false,
    }
end

function handle.disconnect(id, err)
    shaco.trace("Conn disconnect "..id, err)
    local c = connection[id]
    if not c then return end
    chan.exit(id)
    if err and c.logined then
        send2handle(request_handle, id, IDUM_NETDISCONN, "UM_NETDISCONN", {})
    end
    connection[id]=nil
end

function handle.reject(id, addr)
    shaco.trace("Conn reject "..id, addr)
    send2client(id, IDUM_LOGOUT, "UM_LOGOUT", {err=SERR_GATEFULL})
end

function handle.message(id, data)
    if #data < 2 then
        return 1
    end
    local c = connection[id]
    if not c then
        return 1
    end
    local msgid, pos = sunpack("<I2", data)
    data = ssub(data, pos)
    
    if msgid >= IDUM_GATEB and msgid < IDUM_GATEE then
        if msgid ~= IDUM_HEARTBEAT then
            shaco.trace(sformat("Conn %d recv %u sz %d", id, msgid, #data))
            if not c.logined then
                c.logined = true
            end
            shaco.sendum(request_handle, IDUM_GATE, id, msgid, data)
        end
    end
end

function handle.open(conf)
    request_handle = conf.request_handle
    livetime = conf.livetime or 120
    assert(livetime > 0, "Invalid livetime")
    livetime = livetime*1000
end

function handle.init()
    pb.register_file("../res/pb/enum.pb")
    pb.register_file("../res/pb/struct.pb")
    pb.register_file("../res/pb/msg_client.pb")
    pb.register_file("../res/pb/msg_server.pb")

    local function tick()
        shaco.timeout(3000, tick)
        local now = shaco.now()
        for k, v in pairs(connection) do
            if not v.logined then
                if now - v.connect_time > livetime then -- login over time
                    gateserver.closeclient(k)
                end
            end
        end
    end
    shaco.timeout(3000, tick)
    shaco.dispatch("um", function(_,_, msgid, p1,p2,p3,p4,p5) 
        if msgid == IDUM_GATE then
            local connid, subid, msg = p1,p2,p3
            assert(connid)
            assert(subid)
            -- todo check connid exist
            local c = connection[connid] 
            if not c then
                return
            end
            shaco.trace(sformat("Conn %d send %d sz %d", connid, subid, #msg))
            if subid == IDUM_LOGOUT then
                local v, err = pb.decode("UM_LOGOUT", msg)
                assert(v, err)
                --local reason = "logout:"..v.err
                if v.err == SERR_OKUNFORCE then
                    gateserver.closeclient(connid)
                elseif v.err == SERR_OK then
                    gateserver.closeclient(connid)
                else
                    route2client(connid, subid, msg)
                    gateserver.closeclient(connid)
                end
            else
                route2client(connid, subid, msg)
            end 
        elseif msgid == IDUM_SUBSCRIBE then
            local connid, chanid = p1,p2
            assert(connid)
            assert(chanid)
            local c = connection[connid]
            if c then
                chan.subscribe(chanid, connid)
            end
        elseif msgid == IDUM_SUBSCRIBE then
            local connid, chanid = p1,p2
            assert(connid)
            assert(chanid)
            local c = connection[connid]
            if c then
                chan.unsubscribe(chanid, connid)
            end
        elseif msgid == IDUM_PUBLISH then
            local connid, chanid, subid, msg = p1,p2,p3,p4
            assert(connid)
            assert(chanid)
            if chanid == nil then
                for connid, c in pairs(connection) do
                    route2client(connid, subid, msg)
                end
                shaco.trace(sfmt("chan[0] publish msg:%d", msgid))
            else
                chan.publish(chanid, subid, msg)
            end
        end
    end)
end

--local CMD = {}
--function handle.command(cmd, ...)
--    local f = CMD[cmd]
--    return f(...)
--end

gateserver.start(handle)
