local shaco = require "shaco"
local tinsert = table.insert
local sfmt = string.format
local sub = string.sub
local char = string.char
local snapshot = require "snapshot"
local mysql = require "mysql"
local tbl = require "tbl"
 --local conn=env:connect(host='localhost',user='jie',passwd='123456',db='jie',port=3306)
 
 --local conn = env:connect("jie","jie","123456","localhost",3306)
 --conn:execute"SET NAMES GB2312"
 


local function random(n,m)
	math.randomseed(os.time() * math.random(1000000,90000000))
	return math.random(n,m)
end

local function randomNumber(len)  --------随机数字
	local rt = ""
	for i = 1,len do
		if i == 1 then
			rt = rt..random(1,9)
		else
			rt = rt..random(0,9)
		end
	end
	return rt
end

local function randomLetter(len)  -------随机小写
	local rt = ""
	for i = 1,len do
		rt = rt..char(random(97,122))
	end
	return rt
end

local function randomCapital(len)    --------随机大写
	local rt = ""
	for i = 1,len do
		rt = rt..char(random(65,90))
	end
	return rt
end

local RDModle = {
	RSM_Capital = 1,   ---纯大写
	RSM_Letter  = 2,   ---纯小写
	RSM_Cap_Let = 3,   ---大小写
	RSM_Number  = 4,   ---纯数字
	RSM_Cap_Num = 5,   ---大写与数字
	RSM_Let_Num = 6,   ---小写与数字
	RSM_All     = 7,   ---大小写与数字
}

local function RandomString(len,modl)
	local BC = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local SC = "abcdefghijklmnopqrstuvwxyz"
	local NO = "0123456789"
	local maxLen = 0
	local templete = ""
	if modl == nil then
		templete = BC
		maxLen = 26
	elseif modl == RDModle.RSM_Capital then
		templete = BC
		maxLen = 26
	elseif modl == RDModle.RSM_Letter then
		templete = SC
		maxLen = 26
	elseif modl == RDModle.RSM_Cap_Let then
		templete = BC..SC
		maxLen = 52
	elseif modl == RDModle.RSM_Number then
		templete = NO
		maxLen = 10
	elseif modl == RDModle.RSM_Cap_Num then
		templete = BC..NO
		maxLen = 36
	elseif modl == RDModle.RSM_Let_Num then
		templete = SC..NO
		maxLen = 36
	elseif modl == RDModle.RSM_All then
		templete = NO..SC..BC
		maxLen = 62
	else
		templete = BC
		maxLen = 26
	end
	local str = {}
	for i =1,len do
		local indx = random(1,maxLen)
		str[i] = sub(templete,indx,indx)
	end
	return table.concat(str,"")
end



local code_arrary = {}

local function check_code(code)
	for i = 1,#code_arrary do
		if code_arrary[i] == code then
			return false
		end
	end
	return true
end


--local conn=MySQLdb.connect(host='127.0.0.1',user='jie',passwd='123456',port=3306)

	--local string_daily = batchid..";"..code_type..";"..gift_treasure..";"..code_level..";"..code_time..";"..str_code
	--f:write(tostring(string_daily))

--[[	local result = Split(string_list,"#")
		daily_time = tonumber(result[1])
		local record = Split(result[2],";")
		for i =1,#record do
			if record[i] ~= "" and  i <= 10 then
				daily_first[#daily_first + 1] = tonumber(record[i])
			elseif record[i] ~= "" and  i <= 20 and i >= 11 then
				daily_second[#daily_second + 1] = tonumber(record[i])
			elseif record[i] ~= "" and  i >= 21 then
				daily_third[#daily_third + 1] = tonumber(record[i])
			end
		end
		local now_day = shaco.now()//1000//86400
		local last_day = daily_time//86400
		if now_day ~= last_day then
			local string_daily = init_daily_task()
			f:write(tostring(string_daily))
		end]]



local function ping()
	print("--------------------------------")
    local conn = assert(mysql.connect{
        host = "127.0.0.1", 
        port = 3306,
        db = "jie", 
        user = "jie", 
        passwd = "123456",
    })
	--local str_code = ""
	local index = 1
	while index <= 20000  do
		local str_code = ""
		local code = ""
		--print(RandomString(10,7))
		code = code..RandomString(9,7)
		if index <= 5000 then
			code = code..""..'A'
		elseif index > 5000 and index <= 10000 then
			code = code..""..'B'
		elseif index > 10000 then
			code = code..""..'C'
		end
		if check_code(code) then
			code_arrary[#code_arrary + 1] = code
				--str_code = str_code..code..";"
			index = index + 1
		end
		local result = conn:execute(sfmt("insert into x_game_key set game_key = '%s'",code))
		if result.err_code then
			shaco.warning(sfmt("role str_code == %s \n savefail: message == %s",str_code, result.message))
		else
			--shaco.trace(sfmt("role str_code = = %s save ok",str_code))
		end
	end
	--[[while index <= 100  do
		local str_code = ""
		local code = "050804"
		print(RandomString(10,7))
		code = code..RandomString(10,7)
		if check_code(code) then
			code_arrary[#code_arrary + 1] = code
			str_code = str_code..code..";"
			index = index + 1
		end
		local result = conn:execute(sfmt("insert into x_exchange set exchange = '%s', batchid = %d, exchange_type = %d,gift_treasure = '%s',use_level = %d,effective_time = '%s'"
			,code,batchid,code_type,gift_treasure,code_level,code_time))
		local id = 10000 + index
	--	local result = conn:execute(sfmt("insert into x_ladder_info (roleid) values (%u)", id))
		if result.err_code then
			shaco.warning(sfmt("role str_code == %s\n savefail: message == %s", str_code, result.message))
		else
			shaco.trace(sfmt("role str_code = = %s save ok",str_code))
		end
		--tbl.print(result, "=============init result", shaco.trace)
	end]]
	--local f = io.open(".code.tmp", "a+")
--	local string_list = f:read("*a")
	--if string_list == "" then
--		local string_daily = batchid..";"..code_type..";"..gift_treasure..";"..code_level..";"..code_time..";"..str_code
	--	f:write(tostring(string_daily))
--	else
		--[[local result = Split(string_list,"#")
		daily_time = tonumber(result[1])
		local record = Split(result[2],";")
		for i =1,#record do
			if record[i] ~= "" and  i <= 10 then
				daily_first[#daily_first + 1] = tonumber(record[i])
			elseif record[i] ~= "" and  i <= 20 and i >= 11 then
				daily_second[#daily_second + 1] = tonumber(record[i])
			elseif record[i] ~= "" and  i >= 21 then
				daily_third[#daily_third + 1] = tonumber(record[i])
			end
		end
		local now_day = shaco.now()//1000//86400
		local last_day = daily_time//86400
		if now_day ~= last_day then
			local string_daily = init_daily_task()
			f:write(tostring(string_daily))
		end]]
--	end
--	f:close()
--	conn:close()
	os.exit(1)
end
shaco.start(function()
	print("------------------------------------((((((((((((((()))))))))))))))")
	shaco.fork(ping)
end)





