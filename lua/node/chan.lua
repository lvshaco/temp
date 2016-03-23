local shaco = require "shaco"
local gateserver = require "gateserver"
local sfmt = string.format
local pairs = pairs

local chan = {}

local chanl = {}

function chan.subscribe(chanid, actor)
    local c = chanl[chanid]
    if not c then
        chanl[chanid] = {[actor] = true}
    else
        if c[actor] == nil then
            c[actor] = true
        end
    end
    shaco.trace(sfmt("chan[%s] subscribe by %d", chanid, actor))
end

function chan.unsubscribe(chanid, actor)
    local c = chanl[chanid]
    if c then
        if c[actor] ~= nil then
            c[actor] = nil
        end
    end
    shaco.trace(sfmt("chan[%s] unsubscribe by %d", chanid, actor))
end

local function sendpackage(id, data)
    gateserver.send(id, spack('<s2', data))
end

local function route2client(connid, msgid, msg)
    sendpackage(connid, spack('<I2', msgid)..msg)
end


function chan.publish(chanid, msgid, msg)
    local c = chanl[chanid]
    if c then
        for connid, _ in pairs(c) do
            route2client(connid, msgid, msg)
        end
    end
    shaco.trace(sfmt("chan[%s] publish msg:%d", chanid, msgid))
end

function chan.exit(actor)
    for _, c in pairs(chanl) do
        if c[actor] ~= nil then
            c[actor] = nil
        end
    end
    shaco.trace(sfmt("chan subscriber %d exit", actor))
end

return chan
