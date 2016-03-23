local shaco = require "shaco"
local sfmt = string.format
local floor = math.floor
local mysql = require "mysql"
local REQ = require "req"
local tbl = require "tbl"
local CTX = require "ctx"
local createlog = require "createlog"
REQ.__REG {
    "h_dblog"
}

local conn
local update_flag = false
local refresh_time = 0

--[[local function create_log()
	local t = {
		"`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`coin` int(11)  NOT NULL,`gold` int(11) NOT NULL,`create_time` datetime  NOT NULL",
		"`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`role_level` int(11)  NOT NULL,`create_time` datetime  NOT NULL",
		"`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`create_time` datetime  NOT NULL",
		"`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`buy_type` varchar(45)  NOT NULL,`cards` varchar(125) NOT NULL,`create_time` datetime  NOT NULL",
		"`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`itemid` int(11)  NOT NULL,`itemcnt` int(11) NOT NULL,`create_time` datetime  NOT NULL",
		"`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`login_state` varchar(125) NOT NULL,`create_time` datetime NOT NULL",
		"`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`ectypeid` int(11)  NOT NULL,`clubid` int(11) NOT NULL,"..
			"`pos_level_breakthrough_guarantee` varchar(64) NOT NULL,`battle_value` int(11) NOT NULL,`opponent_battle` int(11) NOT NULL,`robot_id` int(11) NOT NULL,`create_time` datetime NOT NULL",
		"`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`florderid` varchar(125) NOT NULL,`orderid` varchar(125)  NOT NULL,`cardno` varchar(125)  NOT NULL,`productid` varchar(125)  NOT NULL,"..
			"`merpriv` varchar(125) NOT NULL,`amount` int(11) NOT NULL,`cardstatus` int(10) NOT NULL,`ret` int(10) NOT NULL,`create_time` datetime NOT NULL"
	}
	local now_s = shaco.now()//1000
	local tb_name = {os.date("x_log_money_%Y%m%d", now_s),os.date("x_log_level_%Y%m%d",now_s),os.date("x_log_create_%Y%m%d",now_s),os.date("x_log_card_%Y%m%d",now_s),os.date("x_log_item_%Y%m%d", now_s),
						os.date("x_log_in_out_%Y%m%d", now_s),os.date("x_log_role_cheat_%Y%m%d",now_s),os.date("x_log_recharge_%Y%m%d",now_s)}
	local indx = 1
	for k, u in pairs(t) do
		local tb = {}
		table.insert(tb,string.format("%s",u))
		local s =table.concat(tb,",")
		local sql = string.format("CREATE TABLE IF NOT EXISTS `%s`( %s ,PRIMARY KEY (`logid`))ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;",tb_name[indx],s)
		local result = conn:execute(sql)
		if result.err_code then
			shaco.warn(sfmt("role %s savefail: %s", tb_name[indx], result.message))
		else
			shaco.trace(sfmt("role v.name = = %s save ok",tb_name[indx]))
		end
		indx = indx + 1
	end
	refresh_time = shaco.now()
end
]]
local function ping()
    while true do
        conn:ping()
        shaco.info("logdb ping")
        shaco.sleep(1800*1000)
    end
end


shaco.start(function()    
    conn = assert(mysql.connect{
        host = shaco.getenv("logdb_host"), 
        port = shaco.getenv("logdb_port"),
        db = shaco.getenv("logdb_name"), 
        user = shaco.getenv("logdb_user"), 
        passwd = shaco.getenv("logdb_passwd"),
    })
    shaco.info("logdb connect ok")

    local function tick()
        shaco.timeout(1000, tick)
        local now = shaco.now()
		local now_day = (now//1000)//86400
		local last_day = (refresh_time//1000)//86400
		if now_day ~= last_day then
			refresh_time = now
			shaco.fork(createlog.create_log,conn,'',now//1000,1)
		end
    end
    shaco.timeout(1000, tick)
    shaco.dispatch("um", function(source, session, name, v)
        local h = REQ[name]
        if h then
            h(conn, source, session, v)
        else
            shaco.warn(sfmt("logdb recv invalid msg %s", name))
        end
    end)
    --shaco.uniquemodule("game", false)
	createlog.create_log(conn,'',shaco.now()//1000,1)
    --create_log()
    --shaco.publish("dblog")
    shaco.fork(ping)
end)
