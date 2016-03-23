local shaco = require "shaco"
local tbl = require "tbl"
local rcall = shaco.callum
local sfmt = string.format
local tinsert = table.insert
local tonumber = tonumber
local floor = math.floor
local pb = require "protobuf"
local user = require "user"
local userpool = require "userpool"
local CTX = require "ctx"
local tprole = require "__tpcreaterole"
local MSG_RESNAME = require "msg_resname"
local crypt = require "crypt.c"
local http = require "http"
local md5 = require"md5"
local cjson = require "cjson"
local sub = string.sub
local socket = require "socket"
local ssl = require "ssl"
local REQ = {}

local NODISCONN=0
local DISCONN=1
local __rsap = crypt.rsa_new("./100148_SignKey.pub", true)

local function role_base_gen(name, tpid, tp)
    return {
        name=name, 
        tpltid=tpid, 
        roleid=0, 
        create_time=shaco.now()//1000,
        race = tp.OccupationID,
        level = tp.Level,
        sex = tp.sex,
		game_key = 0,
    }
end

local function check_status(ur, status)
    if ur.status ~= status then
        shaco.warn(sfmt("user %s state need in %d, but real in %d", ur.acc, status, ur.status))
        return 1
    end
end

local function switch_status(ur, status)
    ur.status = status
    shaco.trace(sfmt("user %s switch state to %s", ur.acc, status))
end

local function conn_disconnect(connid, err)
    local msgid = IDUM_LOGOUT 
    local v = {err=err}
    local name = MSG_RESNAME[msgid]
    assert(name)
    shaco.sendum(CTX.gate, IDUM_GATE, connid, msgid, pb.encode(name, v))
end

local function logout(ur, err, disconn) 
	if ur then
		ur:log_in_out_log(0)
	end
    userpool.logout(ur)
    if ur.status >= user.US_GAME then
        ur:exitgame()
    end
    if disconn == DISCONN then
        ur:send(IDUM_LOGOUT, {err=err}) 
    end
    ur.status = user.US_LOGOUT
    shaco.trace(sfmt("user %s logout, err=%d, disconn=%d", ur.acc, err, disconn))
end

local function check_logout(ur)
    return ur.status == user.US_LOGOUT
end

local function verify_sign(ur,v)
	local flag = true
	local platform = shaco.getnum("platform")
	if platform == OUT_NET then
		local s_in = crypt.base64decode(v.sign)
		s_in = __rsap:public_decrypt(s_in)
		local str = v.struuid.."&"..v.strtimestamp
		if str ~= s_in then
			--ur:send(IDUM_ACKCHECKLOGIN, {result = eVerify_Fail})
			flag = false			
		end
	end
	return flag
end

local function select_role_list(acc,ur)
	
	local data = rcall(CTX.db, "L.rolelist", acc)
    if check_logout(ur) then
        return
    end
    if not data then
        conn_disconnect(connid, SERR_DB)
        return
    end
	--if not verify_sign(ur,v) then
		--return SERR_ACCOUNTS_INFO_ERROR
--	end
    local gms = {}
	local rl = {}
	local gm_level = 1
    for _, v in ipairs(data) do
        local base = pb.decode("role_base", v.base)
        base.roleid = tonumber(v.roleid)
        tinsert(rl, base)
		if gm_level < tonumber(v.gmlevel) then
            gm_level = tonumber(v.gmlevel)
        end
		tinsert(gms,gm_level)
    end
    local oldur = userpool.find_byacc(acc)
    if oldur then
        logout(oldur, SERR_ACCTHRUST, DISCONN)
    end
    ur.roles = rl
    ur.gms = gms
    switch_status(ur, user.US_WAIT_SELECT)
    userpool.add_byacc(acc, ur)

    ur:send(IDUM_ROLELIST, {roles=rl})
    shaco.trace(sfmt("user %s login ok", acc)) 
end

local function sdk_login(connid,accountId,nickName)
	local acc = accountId--nickName--v.acc
    shaco.trace(sfmt("user %s login ... ", connid, acc))
    local ur = userpool.find_byconnid(connid)
    ur = user.new(connid, user.US_LOGIN, acc)
    userpool.add_byconnid(connid, ur)
    -- todo check
    if #acc <= 0 then
        conn_disconnect(connid, SERR_ACCVERIFY)
        return
    end
    local data = rcall(CTX.db, "L.rolelist", acc)
    if check_logout(ur) then
        return
    end
	
    if not data then
        conn_disconnect(connid, SERR_DB)
        return
    end
	--if not verify_sign(ur,v) then
	--	return SERR_ACCOUNTS_INFO_ERROR
	--end
    local gms = {}
	local rl = {}
	local gm_level = 1
    for _, v in ipairs(data) do
        local base = pb.decode("role_base", v.base)
        base.roleid = tonumber(v.roleid)
        tinsert(rl, base)
		if gm_level < tonumber(v.gmlevel) then
            gm_level = tonumber(v.gmlevel)
        end
		tinsert(gms,gm_level)
    end
    local oldur = userpool.find_byacc(acc)
    if oldur then
        logout(oldur, SERR_ACCTHRUST, DISCONN)
    end
    ur.roles = rl
    ur.gms = gms
    switch_status(ur, user.US_WAIT_SELECT)
    userpool.add_byacc(acc, ur)
	--local result = rcall(CTX.db, "L.key", acc)
	--if #result == 0 then
		--ur:send(IDUM_NOTICEWRITEGAMEKEY, {acc = accountId})
	--else
		ur:send(IDUM_ROLELIST, {roles=rl})
	--end
	--tbl.print(rl,"------------ rl ===== ")
	shaco.trace(sfmt("user %s login ok", acc)) 
end


REQ[IDUM_SDKREQLOGIN] = function(connid, v)
	--tbl.print(v,"------------- v ----------- ")
	if v.platform == T_UC_PLATFORM then
		local sid = v.sid
		local _sign = "sid="..sid.."0ee95ce35197bb31e221574088275611"
	
		local sign = md5.sumhexa(_sign)
		local host = "sdk.g.uc.cn"
		local headers = {["content-type"] = "application/json" }
		local uri  = shaco.getenv("uri") or "/cp/account.verifySession"
		local _time = shaco.now()
		local value = '{"id":'.._time..',"game":{"gameId":666956},"data":{"sid":"'..sid..'"},"sign":"'..sign..'"}'
		local code, body = http.post(host, uri, headers, value)
		print (code, body)
		local t = cjson.decode(body)
		local result = {}
		for k, u in pairs(t) do
			if type(u) == "table" then
				result[""..k] = u
			else
			end 
		end
		if result.state.msg == "操作成功" then
			--print("creator === "..result.data.creator)
			--print("accountId === "..result.data.accountId)
			--print("nickName === "..result.data.nickName)
			local accountId = result.data.accountId--md5.sum16(result.data.accountId)
			sdk_login(connid,accountId,result.data.nickName)
		elseif result.state.msg == "用户未登陆" then
			return SERR_USER_NOT_LOGIN
		end
	else	
		local host = "openapi.360.cn"
		 local headers = {["Content-Type"]="application/json", charset="utf-8"}
		local uri = "/user/me.json?access_token="..v.sid
		local port = 443
		local form = nil
		local id = assert(socket.connect(host, port))
		socket.readenable(id, true)
		local body
		print("uri ==== "..uri)
		local ok, err = pcall(function()
			local code, _body = ssl.request(id, host, uri, headers, form)
			body = _body
			print ("[code] "..code)
			print ("[body]")
			print(body)
		end)
		socket.close(id)
		--local uri  = shaco.getenv("uri") or "/user/me.json?access_token=26533467991e837d16b7d521af0feacf878352e307afa0862a"
		--local value = '{"id":'.._time..',"game":{"gameId":666956},"data":{"sid":"'..sid..'"},"sign":"'..sign..'"}'
		--local value = '{"access_token":"'..v.sid..'"}'
		--local value = '{access_token='..v.sid..'}'
		--print("------- value === "..value)
		--local body = '{"id":"2653424268","name":"qwer123alqs","avatar":"http://quc.qhimg.com/dm/48_48_100/t00df551a583a87f4e9.jpg?f=903220e415a2fd5429254ac7ae8b921b","sex":"未知","area":""}'
		--{"id":"2653346799","name":"GW160316114539","avatar":"http://quc.qhimg.com/dm/48_48_100/t00df551a583a87f4e9.jpg?f=903220e415a2fd5429254ac7ae8b921b","sex":"未知","area":""}
		--{"id":"2653423306","name":"GV160316151829","avatar":"http://quc.qhimg.com/dm/48_48_100/t00df551a583a87f4e9.jpg?f=903220e415a2fd5429254ac7ae8b921b","sex":"未知","area":""}
		--{"id":"2653424268","name":"qwer123alqs","avatar":"http://quc.qhimg.com/dm/48_48_100/t00df551a583a87f4e9.jpg?f=903220e415a2fd5429254ac7ae8b921b","sex":"未知","area":""}
		--local code, body =  --http.get(host, uri, headers)--http.get(host, uri, headers, '{"access_token='..v.sid..'"}')
		local t = cjson.decode(body)
		local result = {}
		for k, u in pairs(t) do
			result[""..k] = u
		end
		sdk_login(connid,result.id,result.name)
	end
end

REQ[IDUM_ACTIVATEACC] = function(ur,v)
	ur:send(IDUM_ROLELIST, {roles = ur.roles})
end

REQ[IDUM_GAMEKEY] = function(ur, v)
	--print("----- game_key ==== "..v.game_key)
	local _result = rcall(CTX.db, "L.checkkey", v.game_key)
	if #_result == 0 then
		return SERR_GAME_KEY_ERROR
	else	
		if _result[1].acc == "" then
			local str_key = v.game_key
			local _key = sub(str_key, string.len(str_key), string.len(str_key))
			local flag = false
			if v.platform == T_UC_PLATFORM then
				if _key == 'B' then
					flag = true
				end
			elseif v.platform == T_360_PLATFORM then
				if _key == 'C' then
					flag = true
				end
			else
				if _key == 'A' then
					flag = true
				end
			end
			if flag then
				shaco.sendum(CTX.db, "L.updatekey", {acc = v.acc,game_key = v.game_key})
			else
				return SERR_GAME_KEY_PLATFORM_ERROR
			end
		else
			return SERR_GAME_KEY_OLD
		end 
	end
	ur:send(IDUM_ACKGAMEKEY, {})
end
-- handle
REQ[IDUM_LOGIN] = function(connid, v)
    local acc = v.acc
    shaco.trace(sfmt("user %s login ... ", connid, acc))
    local ur = userpool.find_byconnid(connid)
    if ur then
		if not verify_sign(ur,v) then
			return SERR_ACCOUNTS_INFO_ERROR
		end
        return
    end
    ur = user.new(connid, user.US_LOGIN, acc)
    userpool.add_byconnid(connid, ur)
    -- todo check
    if #acc <= 0 then
        conn_disconnect(connid, SERR_ACCVERIFY)
        return
    end
    local data = rcall(CTX.db, "L.rolelist", acc)
    if check_logout(ur) then
        return
    end
    if not data then
        conn_disconnect(connid, SERR_DB)
        return
    end
	--if not verify_sign(ur,v) then
	--	return SERR_ACCOUNTS_INFO_ERROR
	--end
    local gms = {}
	local rl = {}
	local gm_level = 1
    for _, v in ipairs(data) do
        local base = pb.decode("role_base", v.base)
        base.roleid = tonumber(v.roleid)
        tinsert(rl, base)
		if gm_level < tonumber(v.gmlevel) then
            gm_level = tonumber(v.gmlevel)
        end
		tinsert(gms,gm_level)
    end
    local oldur = userpool.find_byacc(acc)
    if oldur then
        logout(oldur, SERR_ACCTHRUST, DISCONN)
    end
    ur.roles = rl
    ur.gms = gms
    switch_status(ur, user.US_WAIT_SELECT)
    userpool.add_byacc(acc, ur)
	--local result = rcall(CTX.db, "L.key", acc)
--	if #result == 0 then
	--	ur:send(IDUM_NOTICEWRITEGAMEKEY, {})
	--else
		ur:send(IDUM_ROLELIST, {roles=rl})
	--end
	--tbl.print(rl,"------------ rl ===== ")
	shaco.trace(sfmt("user %s login ok", acc)) 
end

REQ[IDUM_CREATEROLE] = function(ur, v)
    shaco.trace(sfmt("user %s create role %s...", ur.acc, v.name))
    if check_status(ur, user.US_WAIT_SELECT) then
        return
    end
    local rl = ur.roles
    if #rl >= 3 then
        return SERR_TOMUCHROLE
    end
    local name = v.name
    -- todo check name
    if #name <= 0 then
        return SERR_NAMEINVALID
    end
	local gm_level = 1
    local err = rcall(CTX.db, "C.name", name)
    if check_logout(ur) then
        return
    end
    if err == 0 then 
        local tp = tprole[v.tpltid]
        if not tp then
            return SERR_ROLETP
        end
        local base = role_base_gen(name, v.tpltid, tp)
        tinsert(rl, base)
		local cur_time = os.date("%Y-%m-%d %X", shaco.now()//1000)
        local roleid = rcall(CTX.db, "I.role", 
            {acc=ur.acc, name=name, base=pb.encode("role_base", base),gmlevel=gm_level,create_time = cur_time})
        if check_logout(ur) then
            return
        end
        if roleid <= 0 then
            logout(ur, SERR_DB, DISCONN)
            return
        end
        base.roleid = tonumber(roleid)
        ur.gm_level = 1
        ur:send(IDUM_ROLELIST, {roles=rl})
        switch_status(ur, user.US_WAIT_SELECT)
		ur:create_log(roleid)
        shaco.trace(sfmt("user %s create role ok", ur.acc))
    elseif err == 1 then
        return SERR_NAMEEXIST
    else
        logout(ur, SERR_DB, DISCONN)
    end
end

REQ[IDUM_SELECTROLE] = function(ur, v)
    shaco.trace(sfmt("user %s select role index=%d...", ur.acc, v.index))
    if check_status(ur, user.US_WAIT_SELECT) then
        return
    end
    local rl = ur.roles
    if #rl == 0 then
        return SERR_NOROLE
    end
    local index = v.index+1
    if index<1 or index>#rl then
        return
    end
    local base = rl[index]
    assert(base)
	if #ur.gms > 0 then
		ur.gm_level = ur.gms[index]
	else
		ur.gm_level = 0
	end
    ur.base = base
	--tbl.print(base,"-0-------------base ==== ")
    local info = rcall(CTX.db, "L.role", base.roleid)
    if check_logout(ur) then 
        return 
    end
	
    if info then
		
        info = pb.decode("role_info", info)
		
    end 
    local item = rcall(CTX.db, "L.ex", {roleid=base.roleid, name="item"})
    if check_logout(ur) then
        return
    end
    if item then
        item = pb.decode("item_list", item)
    end
	local task = rcall(CTX.db, "L.ex", {roleid=base.roleid, name="task"})
    if check_logout(ur) then
        return
    end
    if task then
		
        task = pb.decode("task_list", task)
    end
    local card = rcall(CTX.db, "L.ex", {roleid=base.roleid, name="card"})
    if check_logout(ur) then
        return
    end
    if card then
        card = pb.decode("card_list", card).list
    end
	local club= rcall(CTX.db, "L.ex", {roleid=base.roleid, name="club_info"})
    if check_logout(ur) then
        return
    end
    if club then
        club = pb.decode("club_data", club).data
    end
	local mail= rcall(CTX.db, "L.ex", {roleid=base.roleid, name="mail"})
    if check_logout(ur) then
        return
    end
    if mail then
        mail = pb.decode("mail_list", mail)
    end
	local ladder = rcall(CTX.db, "L.ladder", {roleid=base.roleid, name="ladder_info"})
    if check_logout(ur) then
        return
    end
    if ladder then
		local rank = tonumber(ladder.rank)
        ladder = pb.decode("ladder_base", ladder.data).ladder_data
		if rank > 0 then
			ladder.last_rank = rank
			shaco.sendum(CTX.db, "S.ladder", {
            name="ladder_info",
            roleid=base.roleid,
            rank = 0,
            })
		end
    end
	local recharge = rcall(CTX.db, "L.ex", {roleid=base.roleid, name="recharge"})
    if check_logout(ur) then
        return
    end
    if recharge then
        recharge = pb.decode("recharge_data", recharge)
    end
	local spectype = rcall(CTX.db, "L.ex", {roleid=base.roleid, name="special_ectype"})
    if check_logout(ur) then
        return
    end
    if spectype then
		
        spectype = pb.decode("spectype_data", spectype).sp_data
    end
	local activity = rcall(CTX.db, "L.ex", {roleid=base.roleid, name="activity"})
    if check_logout(ur) then
        return
    end
    if activity then
        activity = pb.decode("activity_data", activity).data
    end
    ur:init(info, item, task, card,club,mail,ladder,recharge,spectype,activity)

    switch_status(ur, user.US_GAME)

    userpool.add_byid(base.roleid, ur)
    userpool.add_byname(base.name, ur)
	ur:log_in_out_log(1)
    ur:entergame()
   
    shaco.trace(sfmt("user %s select %s enter game", ur.acc, base.name))
end

REQ[IDUM_EXITGAME] = function(ur, v)
    logout(ur, SERR_OK, DISCONN)
	
end

REQ[IDUM_NETDISCONN] = function(ur, v)
    logout(ur, SERR_OK, NODISCONN)
end

return REQ
