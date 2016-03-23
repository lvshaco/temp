local shaco = require "shaco"
local pb = require "protobuf"
local tbl = require "tbl"
local sfmt = string.format
local sgsub = string.gsub
local sgmatch = string.gmatch
local tinsert = table.insert
local tconcat = table.concat
local find = string.find
local sub = string.sub
local len = string.len
local rcall = shaco.callum

require "msg_error"
require "msg_client"
require "msg_server"
require "struct"
require "enum"

local REQ = require "req"
local CTX = require "ctx"
local tpfix = require "tpfix"
local CMD = require "cmd"
local userpool = require "userpool"
local ectype_fast = require "ectype_fast"
local itemop = require "itemop"
local config = require "config"
local mail_fast = require "mail_fast"
local task_fast = require "task_fast"
local ladder_fast = require "ladder_fast"
local code_fast = require "code_fast"
local endless_fast = require "endless_fast"
local broad_cast = require "broad_cast"
local activity_fast = require "activity_fast"
local rank_fight = require "rank_fight"
local gm_mail = require "gm_mail"

REQ.__REG {
    "h_scene",
    "h_login",
    "h_item",
    "h_gm",
    "h_task",
    "h_equip",
    "h_ectype",
    "h_skill",
    "h_card",
    "h_shop",
	"h_dazzle",
	"h_mystery",
	"h_club",
	"h_ladder",
	"h_mail",
	"h_function",
	"h_spectype",
	"h_activity",
	"h_code",
}

local MSG_REQNAME = require "msg_reqname"
--extra REQ, add by hand
MSG_REQNAME[IDUM_NETDISCONN] = "UM_NETDISCONN"

local function init_pb()
    local path = "../res/pb"
    local files = {
        "enum",
        "struct",
        "msg_client",
        "msg_server",
    }
    for _, v in ipairs(files) do
        pb.register_file(sfmt("%s/%s.pb", path, v))
    end
end

local function splitstringinfo(szfullstring,szseparator)
	local nfindstartindex = 1
	local nsplitindex = 1
	local nsplitarray = {}
	for w in string.gmatch(s, "[^"..szseparator.."]+") do
		nsplitarray[#nsplitarray + 1] = w                   
    end 
	return nsplitarray;
end

local lastb = 0

shaco.start(function()
    local function tick()
        shaco.timeout(2000, tick)
        local now = shaco.now()
        userpool.foreach(now)
        ladder_fast.update(now)
        mail_fast.update(now)
        task_fast.update(now)
        endless_fast.update(now)
		activity_fast.update(now)
		gm_mail.update(now)
        --collectgarbage("collect")
    end

    shaco.timeout(2000, tick)
    
    shaco.dispatch("um", function(_,_, msgid, connid, subid, msg)
        if msgid == IDUM_GATE then
            assert(connid)
            assert(subid)
            local h = REQ[subid]
            if h then
                shaco.trace(sfmt("Client %d recv %d sz %d", connid, subid, #msg))
                local v = pb.decode(MSG_REQNAME[subid], msg)
                if subid ~= IDUM_LOGIN and subid ~= IDUM_SDKREQLOGIN then
                    local ur = userpool.find_byconnid(connid)
                    if ur then -- check ur ?
                        shaco.trace(h)
                        local r = h(ur, v)
                        if not r then
                            r = SERR_OK
                        end
                        if subid ~= IDUM_NETDISCONN then
                            shaco.trace("response:", r)
                            ur:send(IDUM_RESPONSE, {msgid=subid, err=r})
                        end
                        if userpool.isgaming(ur) then
                            ur:db_flush()
                        end
                    end
                else
                    h(connid, v) 
                end
            else
                shaco.warn(sfmt("Client %d recv invalid msgid %d", connid, subid))
            end
        end
		if msgid == "B.Success" then
			local nsplitarray = splitstringinfo(connid.orderid,"-")
			local roleid = tonumber(nsplitarray[2])
			--print("roleid : ",roleid)
			local ur = userpool.find_byid(roleid)
            if ur then -- check ur 
				ur:deal_with_recharge(connid)
			end
		elseif msgid == "B.Fail" then
			local nsplitarray = splitstringinfo(connid.orderid,"-")
			local roleid = tonumber(nsplitarray[2])
			local ur = userpool.find_byid(roleid)
			if ur then
				ur:delete_order(connid.orderid)
			end
		end
    end)

    config.init()  
    tpfix.init()
    init_pb()
   
    ectype_fast.init()
    itemop.init()
	mail_fast.init()
	task_fast.init()
	broad_cast.init()
	activity_fast.init()

    function CMD.open(conf)
        CTX.gate = assert(conf.gate)
        CTX.logdb = assert(conf.logdb)
        CTX.db = assert(conf.db)

        local vhandle = CTX.db
        local result = rcall(vhandle, "L.roleall")
        if not result then
            os.exit(1)
        end
        rank_fight.load(result)
        local info = rcall(vhandle, "R.ladder")
        if not info then
            os.exit(1)
        end
        ladder_fast.load(info)
        local ectype_info = rcall(vhandle, "R.global")
        if not ectype_info then
            os.exit(1)
        end
        ectype_fast.load(ectype_info)
        local code_info = rcall(vhandle, "R.code")
        if not code_info then
            os.exit(1)
        end
        code_fast.load(code_info)
        local endless_info = rcall(vhandle, "L.endless")
        if not endless_info then
            os.exit(1)
        end
        endless_fast.load(endless_info)
        local activity_money = rcall(vhandle, "R.activity",{name = "activity_money"})
        if not activity_money then
            os.exit(1)
        end
        activity_fast.load(activity_money)
        local activity_exp = rcall(vhandle, "R.activity",{name = "activity_exp"})
        if not activity_exp then
            os.exit(1)
        end
        activity_fast.load_activity_exp(activity_exp)
        local activity = rcall(vhandle, "R.activity",{name = "activity"})
        if not activity then
            os.exit(1)
        end
        activity_fast.load_activity_data(activity)
    end

    shaco.dispatch('lua', function(source, session, cmd, ...)
        local f = CMD[cmd]
        if f then
            shaco.ret(shaco.pack(f(...)))
        end
    end)
end)
