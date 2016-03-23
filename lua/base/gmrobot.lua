local shaco = require "shaco"
local socket = require "socket"
local linenoise = require "linenoise"
local pb = require "protobuf"
local tbl = require "tbl"
local MRES = require "msg_resname"
local MREQ = require "msg_reqname"
local sunpack = string.unpack

local WELCOME = [[
    ______________________________________________
    |              WELCOME TO GM ROBOT           |
    ______________________________________________
    ]]

local TRACE = shaco.getenv("trace")
local IP, PORT = string.match(shaco.getenv("host"), "([^:]+):?(%d+)$")
assert(IP)
assert(PORT)
local ROBOTID = tonumber(shaco.getenv("robotid"))

local function info_trace(msgid, tag)
    if not TRACE then return end
    if tag == "<" then
        print(string.format("%s--[%s:%d]", tag, MREQ[msgid], msgid))
    elseif tag == ">" then
        print(string.format("--%s[%s:%d]", tag, MRES[msgid], msgid))
    else
        print(string.format("  %s[%s:%d]", tag, MRES[msgid], msgid))
    end
end

local function responseid(reqid)
    if reqid == IDUM_LOGIN then
        return IDUM_ROLELIST
    else
        return IDUM_RESPONSE
    end
end

local function encode(mid, v)
    local s = pb.encode(MREQ[mid], v)
    local l = #s+2
    return string.char(l&0xff, (l>>8)&0xff)..
        string.char(mid&0xff, (mid>>8)&0xff)..s
end

local function decode(s)
    local mid = string.byte(s,1,1)|(string.byte(s,2,2)<<8)
    return mid, pb.decode(MRES[mid], string.sub(s,3))
end

local function rpc(id, reqid, v)
    info_trace(reqid, "<")
    local resid = responseid(reqid)
    socket.send(id, encode(reqid, v)) 
    while true do
        local h = assert(socket.read(id, 2))
        h = sunpack('<I2', h)
        local s = assert(socket.read(id, h))
        local mid, r = decode(s)
        if mid == resid then
            info_trace(mid, ">")
            return r
        end
        info_trace(mid, "*")
    end
end

local function create_robot(account, rolename) 
    local id = assert(socket.connect(IP, PORT))
    socket.readon(id)
    
    local v = rpc(id, IDUM_LOGIN, {acc=account, passwd="123456"})
    if #v.roles == 0 then
        rpc(id, IDUM_CREATEROLE, {tpltid=1, name=rolename})
    end
    rpc(id, IDUM_SELECTROLE, {index=0})
    return id
end

shaco.start(function()
    pb.register_file("../res/pb/enum.pb")
    pb.register_file("../res/pb/struct.pb")
    pb.register_file("../res/pb/msg_client.pb")

    local account  = shaco.getenv("acc") or string.format("robot_acc_%u", ROBOTID)
    local rolename = shaco.getenv("name") or string.format("robot_name_%u", ROBOTID)

    local id = create_robot(account, rolename)

    print(WELCOME) 

    local history_file = ".gmrobot.history"
    linenoise.loadhistory(history_file)

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
            rpc(id, IDUM_GM, {command=s})
        end
    end
    linenoise.savehistory(history_file)
end)
