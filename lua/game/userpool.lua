local shaco = require "shaco"
local user = require "user"
local util = require "util"
local floor = math.floor

-- user container
local conn2user = {}
local acc2user = {}
local oid2user = {} -- US_GAME state
local name2user = {} -- US_GAME state
local recharge_list = {} -- 
local userpool = {}

function userpool.find_byconnid(connid)
    return conn2user[connid]
end

function userpool.find_byid(roleid)
    return oid2user[roleid]
end
function userpool.find_byacc(acc)
    return acc2user[acc]
end

function userpool.isgaming(ur)
    return ur.status == user.US_GAME
end

function userpool.add_byconnid(connid, ur)
    conn2user[connid] = ur
end

function userpool.add_byacc(acc, ur)
    acc2user[acc] = ur
end

function userpool.add_byname(name, ur)
    name2user[name] = ur
end

function userpool.add_byid(roleid, ur)
    oid2user[roleid] = ur
end

function userpool.count()
    local n=0
    for k, v in pairs(oid2user) do
        n=n+1
    end
    return n
end

function userpool.logout(ur)
    conn2user[ur.connid] = nil
    if ur.status > user.US_LOGIN then
        acc2user[ur.acc] = nil
    end
    if ur.status > user.US_WAIT_SELECT then
        oid2user[ur.base.roleid] = nil
        name2user[ur.base.name] = nil
    end
end

local day_msec = 86400000
local last_day = util.msecond2day(shaco.now())

function userpool.foreach(now)
    local now_day  = util.msecond2day(now)
    local changed
    if now_day ~= last_day then
        last_day = now_day
        changed = true
    end
    for _, ur in pairs(oid2user) do
        if changed then
            ur:onchangeday(2)
        end
        ur:ontime(now)
    end
end

function userpool.get_conn2user()
	return conn2user
end

return userpool
