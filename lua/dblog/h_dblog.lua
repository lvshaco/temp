local shaco = require "shaco"
local tbl = require "tbl"
local pairs = pairs
local sfmt = string.format
local createlog = require "createlog"
local REQ = {}


--[[local function create_log(conn,name,now_s)
	local t = {}
	t["x_log_money"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`coin` int(11)  NOT NULL,`gold` int(11) NOT NULL,`create_time` datetime  NOT NULL"
	t["x_log_level"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`role_level` int(11)  NOT NULL,`create_time` datetime  NOT NULL"
	t["x_log_create"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`create_time` datetime  NOT NULL"
	t["x_log_card"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`buy_type` varchar(45)  NOT NULL,`cards` varchar(125) NOT NULL,`create_time` datetime  NOT NULL"
	t["x_log_item"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`itemid` int(11)  NOT NULL,`itemcnt` int(11) NOT NULL,`create_time` datetime NOT NULL"
	t["x_log_in_out"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`login_state` varchar(125) NOT NULL,`create_time` datetime NOT NULL"
	t["x_log_role_cheat"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`ectypeid` int(11)  NOT NULL,`clubid` int(11) NOT NULL,"..
			"`pos_level_breakthrough_guarantee` varchar(64) NOT NULL,`battle_value` int(11) NOT NULL,`opponent_battle` int(11) NOT NULL,`robot_id` int(11) NOT NULL,``create_time` datetime NOT NULL"
	t["x_log_recharge"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`florderid` varchar(125) NOT NULL,`orderid` varchar(125)  NOT NULL,`cardno` varchar(125)  NOT NULL,`productid` varchar(125) NOT NULL,"..
			"`merpriv` varchar(125) NOT NULL,`amount` int(11) NOT NULL,`cardstatus` int(10) NOT NULL,`ret` int(10) NOT NULL,`create_time` datetime NOT NULL"
	
	local db_name  = os.date(name.."_%Y%m%d", now_s)
	local sql = string.format("CREATE TABLE IF NOT EXISTS `%s`( %s ,PRIMARY KEY (`logid`))ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;",db_name,t[name])
    local result = conn:execute(sql)
	if result.err_code then
		shaco.warn(sfmt("role %s createfail: %s", db_name,result.message))
	else
		shaco.trace(sfmt("role %s save ok",db_name))
	end
end]]

REQ["S.insert"] = function(conn, source, session,v) --os.date("%Y-%m-%d %X", os.time()
	local fields = v.fields
	local name  = os.date(v.name.."_%Y%m%d", fields.create_time)
	local create_time = fields.create_time
	local s = string.format("insert into %s set ",name)
	fields.create_time = os.date("%Y-%m-%d %X", fields.create_time)
	local tb = {}
	for k, u in pairs(fields) do
		table.insert(tb,string.format("%s='%s'",k,u))
	end
	local sql = s..table.concat(tb,",")
	local result = conn:execute(sql)
	if result.err_code then
		shaco.warn(sfmt("role %s createfail: %s", name,result.message))
		if result.err_code  == 1146 then
			createlog.create_log(conn,v.name,create_time,2)
			conn:execute(sql)
		end
    else
        shaco.trace(sfmt("role %s save ok",name))
    end
end



return REQ
