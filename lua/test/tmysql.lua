local shaco = require "shaco"
local sfmt = string.format
local mysql = require "mysql"
local pb = require "protobuf"
local tbl = require "tbl"
local conn

shaco.start(function()
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

    conn = assert(mysql.connect{
        host = shaco.getstr("gamedb_host"), 
        port = shaco.getstr("gamedb_port"),
        db = shaco.getstr("gamedb_name"), 
        user = shaco.getstr("gamedb_user"), 
        passwd = shaco.getstr("gamedb_passwd"),
    })
local roleid = 39;    
    shaco.trace(sfmt("user %u load role ...", roleid))
    local result = conn:execute(sfmt("select data from x_task where roleid=%u", roleid))
    result = result[1]
--tbl.print(result, "result")
	local r = pb.decode("task_list", result.data)
tbl.print(r, "result")
end)
