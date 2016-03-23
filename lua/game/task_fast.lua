-------------------interface---------------------
--function task_check_state(task, task_type, parameter1, parameter2)
--function task_accept(task,id)
-------------------------------------------------
local shaco = require "shaco"
local tptask = require "__tptask"
local bit32 = require"bit32"
local tbl = require "tbl"
local ipairs = ipairs
local sfmt = string.format
local sfind = string.find
local sub = string.sub
local len = string.len
local floor = math.floor
local tpgamedata = require "__tpgamedata"
local task_fast = {}
--math.randomseed(os.time())
local daily_list = {}
local daily_update = 0
local daily_first = {}
local daily_second = {}
local daily_third = {}
local daily_forth = {}
local daily_fifth = {}
local daily_time = 0
local function Split(szFullString, szSeparator)
	local nFindStartIndex = 1
	local nSplitIndex = 1
	local nSplitArray = {}
	while true do
		local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
		if not nFindLastIndex then
			nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
			break
		end
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
		nFindStartIndex = nFindLastIndex + string.len(szSeparator)
		nSplitIndex = nSplitIndex + 1
	end
	return nSplitArray
end

local function get_daily_task(task_list)
	local temp_list = {}
--	temp_list[#temp_list + 1] = shaco.now()//1000
	local idx = 1
	while( idx < 1000 )
	do
		idx = idx + 1
		local index = math.random(#task_list)
		local flag = 0
		for j = 1,#temp_list do
			if task_list[index] == temp_list[j] then
				flag = 1
				break
			end
		end
		if flag == 0 then
			temp_list[#temp_list + 1] = task_list[index]
		end
		if #task_list == #temp_list then
			break
		end
		if #temp_list >= 10 then
			break
		end
	end
	return temp_list
end

local function init_daily_task()
	local task_list = {}
	local task_first = {}
	local task_second = {}
	local task_third = {}
	local task_forth = {}
	local task_fifth = {}
	for k, v in pairs(tptask) do
		if v.type == DAILY_TASK and v.level == tpgamedata.LevelgroupStart1 and v.maxlevel == tpgamedata.LevelgroupEnd1 then
			--task_list[#task_list + 1] = k
			task_first[#task_first + 1] = k
		elseif v.type == DAILY_TASK and v.level == tpgamedata.LevelgroupStart2 and v.maxlevel == tpgamedata.LevelgroupEnd2 then
			task_second[#task_second + 1] = k
		elseif v.type == DAILY_TASK and v.level == tpgamedata.LevelgroupStart3 and v.maxlevel == tpgamedata.LevelgroupEnd3 then
			task_third[#task_third + 1] = k
		elseif v.type == DAILY_TASK and v.level == tpgamedata.LevelgroupStart4 and v.maxlevel == tpgamedata.LevelgroupEnd4 then
			task_forth[#task_forth + 1] = k
		elseif v.type == DAILY_TASK and v.level == tpgamedata.LevelgroupStart5 and v.maxlevel == tpgamedata.LevelgroupEnd5 then
			task_fifth[#task_fifth + 1] = k
		end 
	end

	daily_first = get_daily_task(task_first)
	daily_second = get_daily_task(task_second)
	daily_third = get_daily_task(task_third)
	daily_forth = get_daily_task(task_forth)
	daily_fifth = get_daily_task(task_fifth)
	daily_time = shaco.now()//1000
	local string_daily = ""..daily_time.."#"
	for i =1,#daily_first do
		string_daily = string_daily..daily_first[i]..";"
	end
	for i =1,#daily_second do
		string_daily = string_daily..daily_second[i]..";"
	end
	for i =1,#daily_third do
		string_daily = string_daily..daily_third[i]..";"
	end
	for i =1,#daily_forth do
		string_daily = string_daily..daily_forth[i]..";"
	end
	for i =1,#daily_fifth do
		string_daily = string_daily..daily_fifth[i]..";"
	end
	--tbl.print(daily_first, "=============init daily_first", shaco.trace)
	return string_daily
end

function task_fast.init()
	local f = io.open(".task.tmp", "a+")
	local string_list = f:read("*a")
	if string_list == "" then
		local string_daily = init_daily_task()
		f:write(tostring(string_daily))
	else
		local result = Split(string_list,"#")
		daily_time = tonumber(result[1])
		local record = Split(result[2],";")
		for i =1,#record do
			if record[i] ~= "" and  i <= 10 then
				daily_first[#daily_first + 1] = tonumber(record[i])
			elseif record[i] ~= "" and  i <= 20 and i >= 11 then
				daily_second[#daily_second + 1] = tonumber(record[i])
			elseif record[i] ~= "" and  i <= 30 and i >= 21 then
				daily_third[#daily_third + 1] = tonumber(record[i])
			elseif record[i] ~= "" and  i <= 40 and i >= 31 then
				daily_forth[#daily_forth + 1] = tonumber(record[i])
			elseif record[i] ~= "" and  i >= 41 then
				daily_fifth[#daily_fifth + 1] = tonumber(record[i])
			end
		end
		local now_day = shaco.now()//1000//86400
		local last_day = daily_time//86400
		if now_day ~= last_day then
			local string_daily = init_daily_task()
			f:write(tostring(string_daily))
		end
	end
	daily_update = 1
	f:close()
end

function task_fast.update(now)
	if daily_update ==1 then
		local now_day = (now//1000)//86400
		
		local last_day = daily_time//86400
		if now_day ~= last_day then
			local f = io.open(".task.tmp", "w")
			local string_daily = init_daily_task()
			f:write(tostring(string_daily))
			f:close()
		end
	end
end

function task_fast.update_daliy(level)
	local task_list ={}
	local now_day = (shaco.now()//1000)//86400
	local last_day = daily_time//86400
	--print("now_day == "..now_day.."last_day == "..last_day.."  level == "..level)
	if now_day == last_day then
		return false,task_list
	else
		if tpgamedata.LevelgroupStart1 <= level and level <= tpgamedata.LevelgroupEnd1 then
			task_list = daily_first
		elseif tpgamedata.LevelgroupStart2 <= level and level <= tpgamedata.LevelgroupEnd2 then
			task_list = daily_second
		elseif tpgamedata.LevelgroupStart3 <= level and level <= tpgamedata.LevelgroupEnd3 then
			task_list = daily_third
		elseif tpgamedata.LevelgroupStart4 <= level and level <= tpgamedata.LevelgroupEnd4 then
			task_list = daily_forth
		elseif tpgamedata.LevelgroupStart5 <= level and level <= tpgamedata.LevelgroupEnd5 then
			task_list = daily_fifth
		end
		return true,task_list
	end
	return false,task_list
end

function task_fast.get_daily_info(level)
	local task_list = {}
	if tpgamedata.LevelgroupStart1 <= level and level <= tpgamedata.LevelgroupEnd1 then
		task_list = daily_first
	elseif tpgamedata.LevelgroupStart2 <= level and level <= tpgamedata.LevelgroupEnd2 then
		task_list = daily_second
	elseif tpgamedata.LevelgroupStart3 <= level and level <= tpgamedata.LevelgroupEnd3 then
		task_list = daily_third
	elseif tpgamedata.LevelgroupStart4 <= level and level <= tpgamedata.LevelgroupEnd4 then
		task_list = daily_forth
	elseif tpgamedata.LevelgroupStart5 <= level and level <= tpgamedata.LevelgroupEnd5 then
		task_list = daily_fifth
	end
	return task_list
end

return task_fast
