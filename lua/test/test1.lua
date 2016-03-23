local shaco = require "shaco"
local mysql = require "mysql"
local tbl = require "tbl"
local pb = require "protobuf"
local sfmt = string.format
local t = select(1,...)
print("name == "..t.name)

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
   --[[ local dazzle = {
        dazzle_type = 1,
        fragment={},
    }
    tbl.print(dazzle, "-----rr")
    local c = pb.encode("dazzle_base_info", dazzle)
    local r = pb.decode("dazzle_base_info", c)
    tbl.print(r, "------r")]]
end


local function ping()
	init_pb()
    local conn = assert(mysql.connect{
        host = "192.168.1.200", 
        port = 3306,
        db = "game", 
        user = "game", 
        passwd = "123456",
    })
	local name = conn.escape_string(t.name)
    local result = conn:execute(sfmt("select * from x_role where name=%s", name))
	tbl.print(result)
	print("result.name === "..result[1].name)
	print("---------------------------")
	local base = pb.decode("role_base", result[1].base)
	tbl.print(base)
	print("************************")
	base.level = t.level
	base=pb.encode("role_base", base),
	tbl.print(base)
--	local to1 = conn.escape_string(base)
    local gm_level = 2
--	local result1 = conn:execute(sfmt("update x_role set gmlevel = %d where name =%s", gm_level,name))
	--tbl.print(base)
    local roleid = 729    
    local result2 = conn:execute(sfmt("select * from x_ladder_info where roleid=%d",roleid))
    print("------*********-------------")
	tbl.print(result2)
    local base = pb.decode("ladder_base", result2[1].data)
    
	tbl.print(base)
	os.exit(1)
end

shaco.start(function()
	shaco.fork(ping)
end)
