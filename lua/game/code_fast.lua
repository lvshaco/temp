--local shaco = require "shaco"
local shaco = require "shaco"
local pb = require "protobuf"
local tbl = require "tbl"
local CTX = require "ctx"
local sfmt = string.format
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local tpgift_treasure = require "__tpgift_treasure"
local gift_reward = require "gift_reward"
local itemop = require "itemop"
local tpcode = require "__tpcode"

local code_fast = {} 

local function code_data_gen()
	return {
		batchid = 0,
		gift_array = "",
		use_level = 0,
		effective_time = "",
		roleid = 0,
		code_type = 0,
		code = "",
	}
end

local code_data = {}

function code_fast.load(code_info)
	for _, v in ipairs(code_info) do
		local data = code_data_gen()
		data.batchid = tonumber(v.batchid)
		data.gift_array = v.gift_treasure
		data.use_level = tonumber(v.use_level)
		data.effective_time = v.effective_time
		data.roleid = tonumber(v.roleid)
		data.code_type = tonumber(v.exchange_type)
		data.code = v.exchange
		code_data[#code_data + 1] = data
	end
	
end

local function check_time(temp_time,cur_time,temp_type)
	local __time = {}
	for w in string.gmatch(temp_time, "[^/]+") do
		__time[#__time + 1] = tonumber(w)
	end
	if cur_time.year > __time[1] then
		return 4
	end
	if temp_type == 1 then
		if cur_time.month < __time[2] then
			return 4
		elseif cur_time.month == __time[2] then
			if cur_time.day < __time[3] then
				return 4
			end
		end
	else
		if cur_time.month > __time[2] then
			return 4
		elseif cur_time.month == __time[2] then
			 if cur_time.day > __time[3] then
				return 4
			 end
		end
	end
end

local function check_code_table_data(ur,code)
	local global_code = ur.info.global_code
	local flag = false
	for k,v in ipairs(tpcode) do
		if v.Code == code and v.type == 2 then
			flag = true
		end
	end
	if flag then	
		local global_array = {}
		for w in string.gmatch(global_code, "[^;]+") do
			
			global_array[#global_array + 1] = w
			if w == code then
				return 1
			end
		end 
	else
		return 5
	end
	return 0
end

local function check_code(ur,code)
	--print("string.len(code) == "..string.len(code))
	if string.len(code) < 16 then
		return check_code_table_data(ur,code)
	end
	local code_type = 0
	local batchid = 0
	local exchage_level = 0
	local effective_time = ""
	for i = 1,#code_data do
		local data = code_data[i]
		--print(" data.code == ".. data.code)
		if data.code == code then
			if data.roleid ~= 0 then
				return 1 ---此兑换码已被兑换
			end
			code_type = data.code_type
			batchid = data.batchid
			exchage_level = data.use_level
			effective_time = data.effective_time
			break
		end
	end
	if batchid == 0 then
		return 5 ---兑换码不存在
	end
	for i = 1,#code_data do
		local data = code_data[i]
		if data.roleid == ur.base.roleid and data.code_type == code_type and data.batchid == batchid then
			return 2  ----此类兑换码已经兑换
		end
	end
	if exchage_level < ur.base.level then
		return 3   ---已超过使用等级上限，无法兑换
	end
	local limit_time = {}
	for w in string.gmatch(effective_time, "[^:]+") do
		print(w) 
		limit_time[#limit_time + 1] = w
	end 
	
	local cur_time = shaco.now()//1000 --当前时间
	local __time=os.date("*t",cur_time)
	for i = 1,#limit_time do
		if check_time(limit_time[i],__time,i) == 4 then
			return 4 ---此兑换码已过期
		end
	end
	return 0
end

local function get_local_code_reward(ur,code)
	local gift_array = ""
	for i = 1,#code_data do
		local data = code_data[i]
		if data.code == code and data.roleid == 0 then
			data.roleid = ur.base.roleid
			gift_array = data.gift_array
			print("----- gift_array ==== "..gift_array) 
			shaco.sendum(CTX.db, "U.code",{name = "exchange",exchange = code,roleid = ur.base.roleid})
			break
		end
	end
	local reward_info = {}
	for w in string.gmatch(gift_array, "[^:]+") do
		
		reward_info[#reward_info + 1] = tonumber(w)
	end
	return reward_info[1], reward_info[2]
end

local function get_global_code_reward(ur,code)
	local global_code = ur.info.global_code
	local flag = false
	for k,v in ipairs(tpcode) do
		if v.Code == code and v.type == 2 then
			ur.info.global_code = global_code..code
			ur:db_tagdirty(ur.DB_ROLE)
			return v.gift_treasure[1],v.gift_treasure[2]
		end
	end
end

function code_fast.exchage_code(ur,code)
	local exchage_result = check_code(ur,code)
	if exchage_result ~= 0 then
		return exchage_result
	end
	local groupid = 0
	local num = 0
	if string.len(code) == 18 then
		groupid,num = get_local_code_reward(ur,code)
	else
		groupid,num = get_global_code_reward(ur,code)
	end
	gift_reward.get_gift_reward(ur,{{groupid,1,1}},num,1)
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
	return 0
end



return code_fast
