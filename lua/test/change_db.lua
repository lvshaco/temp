local shaco = require "shaco"
local mysql = require "mysql"
local tbl = require "tbl"
local pb = require "protobuf"
local sfmt = string.format
local f = loadfile("../lua/test/change_dbdata.lua")
local t = f(1)
local db_list = {role = "role",card = "card",club = "club_info",item = "item",ladder = "ladder_info",
                    recharge = "recharge",spectype = "special_ectype",task = "task"}
local db_data
local struct_list = {card = "card_list",club = "club_data",item = "item_list",ladder = "ladder_base",
                        recharge = "recharge_data",spectype = "spectype_data",task = "task_list"}
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


local function change_db_data()
	init_pb()
    local conn = assert(mysql.connect{
        host = "192.168.1.220", 
        port = 3306,
        db = "jie", 
        user = "jie", 
        passwd = "123456",
    })
    local base
    local role_info
    local gm_level = 0
    if t.acc ~= ""and t.acc then
    	local acc = conn.escape_string(t.acc)
        local role_list = conn:execute(sfmt("select * from x_role where acc=%s", acc))
        local indx = 0
        for _,v in pairs(role_list) do
            indx = indx + 1
            if indx == t.num then
	            base = pb.decode("role_base", v.base)
                role_info = pb.decode("role_info",v.info)
                gm_level = tonumber(v.gmlevel)
            end
        end
    end

    if t.name ~= "" and t.name then
        local name = conn.escape_string(t.name)
        local result = conn:execute(sfmt("select * from x_role where name=%s", name))
        base = pb.decode("role_base", result[1].base)
        role_info = pb.decode("role_info",result[1].info)
        gm_level = tonumber(result[1].gmlevel)
    end
    local roleid = base.roleid
    if t.role == "role_base" then
        local return_data = f(0,0,0,base)
    	return_data = pb.encode("role_base", base)
    	local to = conn.escape_string(base)
        conn:execute(sfmt("update x_role set base = %s where roleid =%d", to,roleid))
    elseif t.role == "role_info" then
        local return_data = f(0,0,0,role_info)
        if return_data then
            role_info = pb.encode("role_info",return_data)
    	    local to = conn.escape_string(role_info)
            conn:execute(sfmt("update x_role set info = %s where roleid =%d", to,roleid))
        end
    elseif t.role == "role_gm" then
        local return_data = f(0,0,0,gm_level)
        conn:execute(sfmt("update x_role set gmlevel = %d where roleid =%d",return_data,roleid))
    else
        local result = conn:execute(sfmt("select data from x_%s where roleid=%d", db_list[t.db_name],roleid))
        if result[1] then
            db_data = pb.decode(struct_list[t.db_name], result[1].data)
        end
        if db_data then
            local return_data =  f(0,db_data)
            if return_data then
                return_data = pb.encode(struct_list[t.db_name],return_data)
                local to = conn.escape_string(return_data) 
                conn:execute(sfmt("update x_%s set data = %s where roleid =%d",db_list[t.db_name],to,roleid))
            end
        else
            f(0,0,1)
        end
    end
	os.exit(1)
end

shaco.start(function()
	change_db_data()
end)
