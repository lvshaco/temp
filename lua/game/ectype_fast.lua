local shaco = require "shaco"
local tbl = require "tbl"
local CTX = require "ctx"
local pb = require "protobuf"
local tbl = require "tbl"
local ipairs = ipairs
local ectype_fast = {}
local record = {}
local dirty_flag = {}

function ectype_fast.init()
end

function ectype_fast.load(all)
    record = {}
    for _, v in ipairs(all) do
        local one = pb.decode("ectype_fast", v.data)
        record[one.ectype_id] = one
    end 
end

local function _gen(id, ur, value, now)
    local name = ur.base.name
    local level = ur.base.level
    return {
        ectype_id=id,
        first_role_guild="",
        first_role_name=name,
        first_value=now,
        fast_role_guild="",
        fast_role_name=name,
        fast_value=value,
		star=0,
		pass_cnt = 1,
        first_level=level,
        fast_level=level,
    }
end

local function _tagdirty(id)
    for _, v in ipairs(dirty_flag) do
        if v == id then
            return
        end
    end
    dirty_flag[#dirty_flag+1] = id
end

function ectype_fast.try_replace(id, ur, time, pass_star)
    local et = record[id]
    local dirty = false
	local flag = 0
    if et == nil then
        record[id] = _gen(id, ur, time, shaco.now()//1000)
        dirty = true
		flag = FIRST_PASS_T
    elseif pass_star == 3 then
        if et.fast_value > time then
            et.fast_value = time 
            if et.fast_role_name ~= ur.base.name then
                et.fast_role_name = ur.base.name
            end
            et.fast_level = ur.base.level
			flag = FIRST_PASS_T
            dirty=true
        end
		et.pass_cnt = et.pass_cnt + 1
    end
    if dirty then
        _tagdirty(id)
        return true,flag
    end
    return false,flag
end

function ectype_fast.db_flush()
    if #dirty_flag == 0 then
        return
    end
    for _, id in ipairs(dirty_flag) do
        local et = record[id]
        assert(et)
       shaco.sendum(CTX.db, "S.global", {
            name="ectype_fast", id=id, data=pb.encode("ectype_fast", et)})
    end
    dirty_flag = {}
end

function ectype_fast.handle(ur, type, data)
    -- todo handle user info change
end

function ectype_fast.query(id)
    return record[id]
end

return ectype_fast
