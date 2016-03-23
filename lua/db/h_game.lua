local shaco = require "shaco"
local tbl = require "tbl"
local sfmt = string.format

local REQ = {}

REQ["L.allrole"] = function(conn, source, session)
    local result = assert(conn:execute(sfmt("select roleid from x_role ")))
    if result.err_code then
        shaco.warn(result.message)
        shaco.ret(shaco.pack(nil))
    else
        shaco.ret(shaco.pack(result))
    end
end

REQ["L.rolelist"] = function(conn, source, session, acc)
    shaco.trace(sfmt("user %s load rolelist ...", acc))

    local result = assert(conn:execute(sfmt("select roleid, base,gmlevel from x_role where acc=%s", conn.escape_string(acc))))
    if result.err_code then
        shaco.warn(result.message)
        shaco.ret(shaco.pack(nil))
    else
        shaco.ret(shaco.pack(result))
    end
end

REQ["L.key"] = function(conn, source, session, acc)
    local result = assert(conn:execute(sfmt("select game_key from x_game_key where acc=%s", conn.escape_string(acc))))
    if result.err_code then
        shaco.warn(result.message)
        shaco.ret(shaco.pack(nil))
    else
        shaco.ret(shaco.pack(result))
    end
end  

REQ["L.checkkey"] = function(conn, source, session, game_key)
    local result = assert(conn:execute(sfmt("select * from x_game_key where game_key=%s", conn.escape_string(game_key))))
    if result.err_code then
        shaco.warn(result.message)
        shaco.ret(shaco.pack(nil))
    else
        shaco.ret(shaco.pack(result))
    end
end  

REQ["L.updatekey"] = function(conn, source, session,v)
	 local acc = conn.escape_string(v.acc)
    local game_key = conn.escape_string(v.game_key)
	local result = conn:execute(sfmt("update x_game_key set acc=%s where game_key=%s",acc,game_key))
     if result.err_code then
        shaco.warn(sfmt("game_key save fail: %s",acc))
    else
        shaco.trace(sfmt("role %s game_key save ok", v.acc))
    end
end

REQ["C.name"] = function(conn, source, session, name)
    shaco.trace(sfmt("User ask check role name %s ...", name))
    local name = conn.escape_string(name)
    local result = conn:execute(sfmt("select roleid from x_role where name=%s", name))
    local err
    if result.err_code then
        err = 2
    elseif #result > 0 then
        err = 1
    else
        err = 0
    end 
    shaco.ret(shaco.pack(err))
end

REQ["I.role"] = function(conn, source, session, v)
    local acc = conn.escape_string(v.acc)
    local name = conn.escape_string(v.name)
    local base = conn.escape_string(v.base)
	local create_time = conn.escape_string(v.create_time)
    local result = conn:execute(sfmt("insert into x_role (acc,name,base,gmlevel,create_time) values (%s,%s,%s,%d,%s)", acc,name,base,v.gmlevel,create_time))
    local roleid
    if result.err_code then
        roleid = 0
        shaco.warn(sfmt("user %s insert fail: %s", v.acc, result.message))
    else
        roleid = result.last_insert_id
        shaco.trace(sfmt("user %s insert role ok", v.acc))
    end
    -- todo
    shaco.ret(shaco.pack(roleid))
end

REQ["L.role"] = function(conn, source, session, roleid)
    shaco.trace(sfmt("user %u load role ...", roleid))
    local result = conn:execute(sfmt("select info from x_role where roleid=%u", roleid))
    result = result[1]
    shaco.ret(shaco.pack(result.info))
end

REQ["L.roleall"] = function(conn, source, session)
    shaco.trace("load role all")
    local result = conn:execute("select roleid, info,base from x_role")
    shaco.ret(shaco.pack(result))
end


REQ["L.base"] = function(conn, source, session, roleid)
    --shaco.trace(sfmt("user %u load role ...", roleid))
    local result = conn:execute(sfmt("select base from x_role where roleid=%u", roleid))
    result = result[1]
    shaco.ret(shaco.pack(result.base))
end

REQ["S.role"] = function(conn, source, session, v)
    local to1 = conn.escape_string(v.base)
    local to2 = conn.escape_string(v.info)
    local result = conn:execute(sfmt("update x_role set base=%s,info=%s where roleid=%u", to1, to2, v.roleid))
    if result.err_code then
        shaco.warn(sfmt("role %u save fail: %s", v.roleid, result.message))
    else
        shaco.trace(sfmt("role %u save ok", v.roleid))
    end
end

REQ["L.ex"] = function(conn, source, session, v)
	-- shaco.trace(sfmt("user load %d ...-----------------------", v.roleid))
    shaco.trace(sfmt("user %u load %s ...", v.roleid, v.name))
    local result = conn:execute(sfmt("select data from x_%s where roleid=%u", v.name, v.roleid))
    result = result[1]
    shaco.ret(shaco.pack(result and result.data or nil))
end

REQ["S.ex"] = function(conn, source, session, v)
    local to = conn.escape_string(v.data)
    local result = conn:execute(sfmt("insert into x_%s (roleid,data) values (%d,%s) on duplicate key update data=%s", 
        v.name, v.roleid, to, to))
    if result.err_code then
        shaco.warn(sfmt("role %u save %s fail: %s", v.roleid, v.name, result.message))
    else
        shaco.trace(sfmt("role %u save %s ok", v.roleid, v.name))
    end
end


REQ["L.ladder"] = function(conn, source, session, v)
    shaco.trace(sfmt("user %u load %s ...", v.roleid, v.name))
    local result = conn:execute(sfmt("select data,rank from x_%s where roleid=%u", v.name, v.roleid))
    result = result[1]
    shaco.ret(shaco.pack(result))
end

REQ["S.ladder"] = function(conn, source, session, v) 
    local result = conn:execute(sfmt("insert into x_%s (roleid,rank) values (%d,%d) on duplicate key update rank=%d", 
        v.name, v.roleid,v.rank,v.rank))
    if result.err_code then
        shaco.warn(sfmt("role %u save %s fail: %s", v.roleid, v.name, result.message))
    else
        shaco.trace(sfmt("role %u save %s ok", v.roleid, v.name))
    end
end


REQ["R.ladder"] = function(conn, source, session)
    local result = assert(conn:execute(sfmt("select roleid, data,rank from x_ladder_info")))
	 if result.err_code then
        shaco.warn(result.message)
        shaco.ret(shaco.pack(nil))
    else
        shaco.ret(shaco.pack(result))
    end
end

REQ["S.global"] = function(conn, source, session, v)
    local to = conn.escape_string(v.data)
    local result = conn:execute(sfmt("insert into x_%s (id,data) values (%u,%s) on duplicate key update data=%s", 
        v.name, v.id, to, to))
    if result.err_code then
        shaco.warn(sfmt("%s save %u fail: %s", v.name, v.id,result.message ))
    else
        shaco.trace(sfmt("%s save %u ok", v.name, v.id))
    end
end

REQ["R.global"] = function(conn, source, session)
    local result = assert(conn:execute(sfmt("select id, data from x_ectype_fast")))
	 if result.err_code then
        shaco.warn(result.message)
        shaco.ret(shaco.pack(nil))
    else
        shaco.ret(shaco.pack(result))
    end
end

REQ["S.code"] = function(conn, source, session, v)
	local fields = v.fields
	local code = conn.escape_string(fields.code)
	local batchid = fields.batchid
	local code_type = fields.code_type
	local gift_treasure	= conn.escape_string(fields.gift_treasure)
	local use_level	= fields.use_level
	local effective_time = conn.escape_string(fields.effective_time)
    local result = conn:execute(sfmt("insert into x_%s (code,batchid,code_type,gift_treasure,use_level,effective_time) values (%s,%d,%d,%s,%d,%s)", 
        v.name,code,batchid,code_type,gift_treasure,use_level,effective_time))
    if result.err_code then
        shaco.warn(sfmt("%s save %s fail: %s", v.name, v.code,result.message ))
    else
        shaco.trace(sfmt("%s save %s ok", v.name, v.code))
    end
end

REQ["U.code"] = function(conn, source, session, v)
	local code = conn.escape_string(v.exchange)
    local result = conn:execute(sfmt("update x_%s set roleid = %d where exchange =%s", v.name,v.roleid,code))
    if result.err_code then
        shaco.warn(sfmt("role %u save fail: %s", v.roleid, result.message))
    else
        shaco.trace(sfmt("role %s save ok", code))
    end
end

REQ["R.code"] = function(conn, source, session)
    local result = assert(conn:execute(sfmt("select * from x_exchange ")))
	 if result.err_code then
        shaco.warn(result.message)
        shaco.ret(shaco.pack(nil))
    else
        shaco.ret(shaco.pack(result))
    end
end

REQ["L.endless"] = function(conn, source, session)
    local result = conn:execute(sfmt("select * from x_endless_tower"))
     if result.err_code then
        shaco.warn(result.message)
        shaco.ret(shaco.pack(nil))
    else
        shaco.ret(shaco.pack(result))
    end
end

REQ["S.actmoney"] = function(conn, source, session, v) 
	local name = conn.escape_string(v.name)
	local num = 0
	local result = conn:execute(sfmt("insert into x_activity_money (roleid,name,reward_money,difficulty,date_time) values (%d,%s,%d,%d,%d)"..
	" on duplicate key update reward_money=%d",v.roleid,name,v.reward_money,v.difficulty,v.date_time,v.reward_money))
    if result.err_code then
        shaco.warn(sfmt("role %u update x_activity_money fail: %s", v.roleid, result.message))
    else
        shaco.trace(sfmt("role %u save x_activity_money ok", v.roleid))
    end
end

REQ["S.actexp"] = function(conn, source, session, v) 
	local name = conn.escape_string(v.name)
	local num = 0
	local result = conn:execute(sfmt("insert into x_activity_exp (roleid,name,over_time,difficulty,date_time) values (%d,%s,%d,%d,%d)"..
	" on duplicate key update over_time=%d",v.roleid,name,v.over_time,v.difficulty,v.date_time,v.over_time))
    if result.err_code then
        shaco.warn(sfmt("role %u update x_activity_money fail: %s", v.roleid, result.message))
    else
        shaco.trace(sfmt("role %u save x_activity_money ok", v.roleid))
    end
end

REQ["R.activity"] = function(conn, source, session,v)
    local result = conn:execute(sfmt("select * from x_%s",v.name))
     if result.err_code then
        shaco.warn(result.message)
        shaco.ret(shaco.pack(nil))
    else
        shaco.ret(shaco.pack(result))
    end
end

REQ["L.delete"] = function(conn, source, session,v)
    local result = conn:execute(sfmt("delete from x_%s",v.name))
     if result.err_code then
        shaco.warn(result.message)
       -- shaco.ret(shaco.pack(nil))
    else
      --  shaco.ret(shaco.pack(result))
    end
end

return REQ
