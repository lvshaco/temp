local shaco = require "shaco"
local tbl = require "tbl"
local CTX = require "ctx"
local pb = require "protobuf"
local card_container = require "card_container"
local sfmt = string.format
local itemop = require "itemop"
local userpool = require "userpool"
local tppayprice = require "__tppayprice"
local tpexptower = require "__tpexptower"
local tpmoneytower = require "__tpmoneytower"
local util = require "util"

local endless_fast = {}
local endless_rank = {}
local front_hundred = {}
local front_five = {}
local sync_update_time = 0

local function endless_fast_gen(roleid)
	return {
		roleid = roleid,
		name = "",
		max_floor = 0 ,
		create_time = 0,
		rank = 0,
	}
end

local function sort_score_Asc(a,b)
	if a.max_floor == b.max_floor then return a.create_time <= b.create_time 
	else return a.max_floor >= b.max_floor end
end

local function sort_endless_rank()
	table.sort(endless_rank,sort_score_Asc)
	front_hundred = {}
	for i =1,#endless_rank do
		endless_rank[i].rank = i
		if i <= 5 then
			front_five[i] = endless_rank[i]
		end
		if i <= 100 then
			front_hundred[i] = endless_rank[i]
		end
	end
	
end

function endless_fast.load(all)
	local now = shaco.now()//1000
    local now_day = util.second2day(now)
	local same_day = false
    for _, v in ipairs(all) do
		local one = pb.decode("endless_rank_data", v.data).data
		local last_day = util.second2day(one.create_time)
		if now_day == last_day then
			local endless_info = endless_fast_gen(tonumber(v.roleid))
			endless_info.name = one.name
			endless_info.max_floor = tonumber(one.max_floor)
			endless_info.create_time = tonumber(one.create_time)
			endless_info.rank = tonumber(one.rank)
			endless_rank[#endless_rank + 1] = endless_info
			same_day = true
		end
	end
	if same_day then
		sort_endless_rank()
	end
end

local function get_own_endless_info(roleid)
	for i = 1,#endless_rank do
		local info = endless_rank[i]
		if info.roleid == roleid then
			return info
		end
	end
end

function endless_fast.req_endless_rank(ur,flag)
	local own_endless = get_own_endless_info(ur.base.roleid)
	if not own_endless then
		local data = endless_fast_gen(ur.base.roleid)
		data.name = ur.base.name
		data.max_floor = 0
		data.create_time = 0
		data.rank = 0
		own_endless = data
	end
	if flag == 1 then
		ur:send(IDUM_ACKRANKINGLIST,{ranks = front_hundred,own_rank = own_endless,five_ranks = front_five})
	elseif flag == 2 then
		ur:send(IDUM_ACKRANKINGLIST,{ranks = front_hundred,own_rank = own_endless,five_ranks = {}})
	elseif flag == 3 then
		ur:send(IDUM_ACKRANKINGLIST,{ranks = {},own_rank = own_endless,five_ranks = {}})
	elseif flag == 4 then
		ur:send(IDUM_ACKRANKINGLIST,{ranks = {},own_rank = own_endless,five_ranks = front_five})
	end
end

local function check_hundred_rank(roleid)
	for i =1,#front_hundred do
		local info = front_hundred[i]
		if info.roleid == roleid then
			return info.rank
		end
	end
	return false
end

local function endless_tower_gen()
	return {
		name = "",
		max_floor = 0,
		create_time = 0,
		rank = 0,
	}
end

function endless_fast.balance_endless_rank(ur,max_floor)
	local roleid = ur.base.roleid
	local own_endless = get_own_endless_info(roleid)
	local flag = false
	if not own_endless then
		own_endless = endless_fast_gen(roleid)
		own_endless.name = ur.base.name
		own_endless.max_floor = max_floor
		own_endless.create_time = shaco.now()//1000
		own_endless.rank = 0
		endless_rank[#endless_rank + 1] = own_endless
		flag = true
	else
		if max_floor >= own_endless.max_floor then
			flag = true
			own_endless.max_floor = max_floor 
			own_endless.create_time = shaco.now()//1000
		end
	end
	if flag then
		sort_endless_rank()
		local own_info = get_own_endless_info(roleid)
		if own_info.rank <= 5 then
			endless_fast.req_endless_rank(ur,1)
		elseif own_info.rank > 5 and own_info.rank <= 100 then
			endless_fast.req_endless_rank(ur,2)
		else
			endless_fast.req_endless_rank(ur,3)
		end
		
		local endless_info = endless_tower_gen()
		endless_info.name = own_info.name
		endless_info.max_floor = own_info.max_floor
		endless_info.create_time = own_info.create_time
		endless_info.rank = own_info.rank
		shaco.sendum(CTX.db, "S.ex", {
            name="endless_tower",
            roleid=roleid,
            data=pb.encode("endless_rank_data", {data = endless_info}),
            })
	end
	
end

local function check_same_day(now)
--	print("---------------------- time == "..now.." #front_hundred == "..#front_hundred)
	for i = 1,#endless_rank do
		local now_day = util.second2day(now)
	--	print("------------------")
		local last_day = util.second2day(endless_rank[i].create_time)
	--	print("endless_rank[i].create_time == "..endless_rank[i].create_time.."  --- now == "..now.." -- now_day == "..now_day.."  ---last_day == "..last_day)
		if now_day ~= last_day then
		--	print(" -- now_day == "..now_day.."  ---last_day == "..last_day)
			return false
		else
			return true
		end
	end
--	print("*************************")
	return true
end

local function sync_update_rank_info()
	sort_endless_rank()
	for i =1,#endless_rank do
		local ur = userpool.find_byid(endless_rank[i].roleid)
		if ur then
			endless_fast.req_endless_rank(ur,1)
		end
	end
end

function endless_fast.update(now)
	local time = now//1000
    local cur_time=os.date("*t",time)
	if cur_time.hour == 24 or cur_time.hour == 0  then
		if not check_same_day(time) then
			print("___-------------_______-----------____ cur_time.hour == "..cur_time.hour)
			front_hundred = {}
			front_five = {}
			for i =1,#endless_rank do
				local ur = userpool.find_byid(endless_rank[i].roleid)
				if ur then
					endless_rank[i].roleid = 0
					endless_fast.req_endless_rank(ur,3)
				end
			end
			endless_rank = {}
		end
	end
	if sync_update_time > 0 then
		local difference_time = time - sync_update_time
		local flag,temp = math.modf(difference_time/300)
		if flag >= 1 then
			sync_update_time = time
			sync_update_rank_info()
		end
	else
		if sync_update_time == 0 then
			sync_update_time = time
		end
	end
	
--	if ur.five_rank_update > 0 and ur.five_rank_update < five_rank_update then
	
	--end
end

return endless_fast
