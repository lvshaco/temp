local shaco = require "shaco"
local sfmt = string.format
local floor = math.floor
local mysql = require "mysql"
local REQ = require "req"
local tbl = require "tbl"
local CTX = require "ctx"

local createlog = {}

function createlog.create_log(conn,name,now_s,flag)
	local t = {}
	t["x_log_money"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`coin` int(11)  NOT NULL,`gold` int(11) NOT NULL,`create_time` datetime  NOT NULL"
	t["x_log_level"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`role_level` int(11)  NOT NULL,`create_time` datetime  NOT NULL"
	t["x_log_create"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`create_time` datetime  NOT NULL"
	t["x_log_card"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`buy_type` varchar(45)  NOT NULL,`cards` varchar(125) NOT NULL,`create_time` datetime  NOT NULL"
	t["x_log_item"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`itemid` int(11)  NOT NULL,`itemcnt` int(11) NOT NULL,`create_time` datetime NOT NULL"
	t["x_log_in_out"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`login_state` varchar(125) NOT NULL,`create_time` datetime NOT NULL"
	t["x_log_role_cheat"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`ectypeid` int(11)  NOT NULL,`clubid` int(11) NOT NULL,"..
			"`pos_level_breakthrough_guarantee` varchar(64) NOT NULL,`battle_value` int(11) NOT NULL,`opponent_battle` int(11) NOT NULL,`robot_id` int(11) NOT NULL,`create_time` datetime NOT NULL"
	t["x_log_recharge"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`florderid` varchar(125) NOT NULL,`orderid` varchar(125)  NOT NULL,`cardno` varchar(125)  NOT NULL,`productid` varchar(125) NOT NULL,"..
			"`merpriv` varchar(125) NOT NULL,`amount` int(11) NOT NULL,`cardstatus` int(10) NOT NULL,`ret` int(10) NOT NULL,`create_time` datetime NOT NULL"
	t["x_log_gm"] = "`logid` int(11) NOT NULL AUTO_INCREMENT,`roleid` int(11) NOT NULL,`gm_name` varchar(125) NOT NULL,`create_time` datetime  NOT NULL"
	
	local db_name  = os.date(name.."_%Y%m%d", now_s)
	if flag == 1 then
		for k, u in pairs(t) do
			local tb = {}
			local log_name = os.date(k.."_%Y%m%d", now_s)
			table.insert(tb,string.format("%s",u))
			local s =table.concat(tb,",")
			local sql = string.format("CREATE TABLE IF NOT EXISTS `%s`( %s ,PRIMARY KEY (`logid`))ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;",log_name,s)
			local result = conn:execute(sql)
			if result.err_code then
				shaco.warn(sfmt("role %s savefail: %s", log_name, result.message))
			else
				shaco.trace(sfmt("role log_name = %s save ok",log_name))
			end
		end
	elseif flag == 2 then
		local sql = string.format("CREATE TABLE IF NOT EXISTS `%s`( %s ,PRIMARY KEY (`logid`))ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;",db_name,t[name])
		local result = conn:execute(sql)
		if result.err_code then
			shaco.warn(sfmt("role %s createfail: %s", db_name,result.message))
		else
			shaco.trace(sfmt("role %s save ok",db_name))
		end
	end
end
return createlog
