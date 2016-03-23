--local shaco = require "shaco"
local shaco = require "shaco"
local pb = require "protobuf"
local tbl = require "tbl"
local sfmt = string.format
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local tpmonster = require "__tpmonster" 
local tpitemdrop = require "__tpitemdrop"
local tpscene = require "__tpscene"
local BASE_VALUE = 100000 
local itemdrop = {}

local function item_list_gen()
	return {
		itemid = 0,
		cnt = 0,
	}
end

local function turn_card_gen()
	return {
		itemid = 0,
		cnt = 0,
		type = 0,
	}
end

local function item_drop_gen()
	return {
		itemid = 0,
		cnt = 0,
		drop_type = 0,
	}	
end

local function drop_item_gen()
	return {
		itemid = 0,
		cnt = 0,
		index = 0,
		weigh = 0,
		drop_type = 0,
	}	
end

local function reward_item_gen()
	return {
		itemid = 0,
		cnt = 0,
		index = 0,
		weigh = 0,
		floor_cnt = 0,
	}
end

function itemdrop.random_drop_item(rewards)
	local item_list = {}
	local total_weight = 0
	for i =1,#rewards do
		total_weight = total_weight + rewards[i][3]
	end
	if total_weight >= 1 then
		local random_weight = math.random(1,total_weight)
		local weight = 0
		for i =1,#rewards do
			weight = weight + rewards[i][3]
			if weight >= random_weight then
				item_list[#item_list+1] = item_list_gen()
				item_list[#item_list].itemid = rewards[i][1]
				item_list[#item_list].cnt = rewards[i][2]
				break
			end
		end
	end
	return item_list
end

local function turn_card_reward_gen()
	return {
		itemid = 0,
		cnt = 0,
		__type = 0,
	}
end

function itemdrop.compute_copy_result(ur,copyid)
	local tp = tpscene[copyid]
	if not tp then
		return
	end
	local turn_list = {}
	local turn_card_list = {}
	turn_list = itemdrop.random_drop_item(tp.items1)
	if not turn_list then
		return SERR_ERROR_LABEL
	end
	turn_card_list[#turn_card_list + 1] = turn_card_gen()
	turn_card_list[#turn_card_list].itemid = turn_list[1].itemid
	turn_card_list[#turn_card_list].cnt = turn_list[1].cnt
	turn_card_list[#turn_card_list].type = UN_GOLD_TURN
	turn_list = itemdrop.random_drop_item(tp.items2)
	if not turn_list then
		return SERR_ERROR_LABEL
	end
	if #turn_list > 0 then
		turn_card_list[#turn_card_list + 1] = turn_card_gen()
		turn_card_list[#turn_card_list].itemid = turn_list[1].itemid
		turn_card_list[#turn_card_list].cnt = turn_list[1].cnt
		turn_card_list[#turn_card_list].type = GOLD_TURN
		ur.info.turn_card = turn_card_list
	end
	ur:send(IDUM_TURNCARDRESULT, {info = turn_card_list})
end

local function get_drop_list(drop_list,items, __type)
	local temp_list = {}
	for i=1,#drop_list do
		local drop = drop_list[i]
		local flag = false
		for j =1,#items do
			local item = items[j]
			if drop.itemid == item.itemid and __type == item.drop_type and drop.index == item.index then
				flag = true
				break
			end
		end
		if flag == false then
			temp_list[#temp_list + 1] = drop
		end
	end
	return temp_list
end

local function  get_drop_data(drop_count,drop_data,__type,item_list)
	for i =1, drop_count do
		local drop_list = get_drop_list(drop_data,item_list, __type)
		local taotal_weight = 0
	--	tbl.print(drop_list,"---------11111-------11111------drop_list ----")
		for j =1,#drop_list do
			taotal_weight = drop_list[j].weigh + taotal_weight
		end
		if taotal_weight >= 1 then
			local weight = 0
			local random_weight =  math.random(1,taotal_weight)
			for j =1,#drop_list do
				local drop = drop_list[j]
				weight = drop.weigh + weight
				if weight >= random_weight then
					local info = drop_item_gen()
					info.itemid = drop.itemid
					info.cnt = drop.cnt
					info.drop_type = __type
					info.index = drop.index
					item_list[#item_list + 1] = info
					break
				end
			end
		end
	end
	return item_list
end

local function random_count(countv)
	local total_weight = 0
	local count_list = {}
	for i = 1,#countv do
		if #countv[i] > 0 and countv[i][2] then
			total_weight = total_weight + countv[i][2] 
			count_list[#count_list + 1] = countv[i]
		end
	end
	local itemcnt = 0
	if total_weight >= 1 then
		local weight = 0
		local random_value = math.random(1,total_weight)
		for i = 1,#count_list do
			weight = weight + count_list[i][2]
			if weight >= random_value then
				itemcnt = count_list[i][1]
				break
			end
		end
	end
	return itemcnt
end

local function check_total_weigh(drop_list)
	local taotal_weight = 0
	for j =1,#drop_list do
		taotal_weight = drop_list[j][3] + taotal_weight
	end
	if taotal_weight == 10000 then
		return true
	end
	return false
end

local function get_all_drop(drop_count,drop_data,__type,item_list)
	for i =1, drop_count do
		item_list[#item_list+1] = item_drop_gen()
		item_list[#item_list].itemid = drop_data[i][1]
		item_list[#item_list].cnt = drop_data[i][2]
		item_list[#item_list].drop_type = __type
	end
	return item_list
end

local function get_drop_info(drop_list,drop_type)
	local item_list = {}
	for i = 1,#drop_list do
		local item = drop_list[i]
		local info = drop_item_gen()
		info.itemid = item[1]
		info.cnt = item[2]
		info.weigh = item[3]
		info.index = i
		info.drop_type = drop_type
		item_list[#item_list + 1] = info
	end
	return item_list
end

function itemdrop.random_ectype_drop(copyid,drop_type)
	local tp = tpscene[copyid]
	if not tp then
		return
	end
	local drop_count = random_count(tp.monster_drop_count)
	local boss_count1 = random_count(tp.boss_drop_count1)
	local boss_count2 = random_count(tp.boss_drop_count2)
	local item_list = {}
	local randomcnt =  math.random(1,100)
	if randomcnt <= tp.monster_probability then
		get_drop_data(drop_count,get_drop_info(tp.monster_drop_list,MONSTER_DROP),MONSTER_DROP,item_list)
	end
	randomcnt =  math.random(1,100)
	if randomcnt <= tp.boss_probability1 then
		get_drop_data(boss_count1,get_drop_info(tp.boss_drop_list1,BOSS_DROP),BOSS_DROP,item_list)
	end
	randomcnt =  math.random(1,100)
	if randomcnt <= tp.boss_probability2 then
		get_drop_data(boss_count2,get_drop_info(tp.boss_drop_list2,HIDE_BOSS_DROP),HIDE_BOSS_DROP,item_list)
	end
	if drop_type == 1 then
		get_drop_data(1,get_drop_info(tp.items1,MONSTER_DROP),MONSTER_DROP,item_list)
	end
	local drop_list = {}	
	if #item_list > 0 then
		for i = 1,#item_list do
			local item = item_list[i]
			if item.cnt > 0 then
				local info = item_drop_gen()
				info.itemid = item.itemid
				info.cnt = item.cnt
				info.drop_type = item.drop_type
				drop_list[#drop_list + 1] = info
			end
		end
	end
	--tbl.print(drop_list, "=============init self.drop_list", shaco.trace)
	return drop_list
end

local function get_reward_list(rewards,items)
	local temp_list = {}
	for i=1,#drop_list do
		local drop = drop_list[i]
		local flag = false
		for j =1,#items do
			local item = items[j]
			if drop.itemid == item.itemid and __type == item.drop_type and drop.index == item.index then
				flag = true
				break
			end
		end
		if flag == false then
			temp_list[#temp_list + 1] = drop
		end
	end
	return temp_list
end

function itemdrop.random_reward_rule(rewards,count,item_list)
	local reward_list = get_drop_info(rewards,0)
	--tbl.print(reward_list,"-------------  reward_list ---- ")
	get_drop_data(count,get_drop_info(rewards,0),0,item_list)
	--tbl.print(item_list,"----------233333333---  item_list ---- ")
end

local function get_reward_info(reward_list)
	local item_list = {}
	for i = 1,#reward_list do
		local item = reward_list[i]
		local info = reward_item_gen()
		info.itemid = item.itemid
		info.cnt = item.itemcnt
		info.weigh = item.weigh
		info.index = i
		info.floor_cnt = item.cur_floor
		item_list[#item_list + 1] = info
	end
	return item_list
end

local function get_endless_reward_list(reward_data,items)
	local temp_list = {}
	for i=1,#reward_data do
		local drop = reward_data[i]
		local flag = false
		for j =1,#items do
			local item = items[j]
			if drop.floor_cnt == item.floor_cnt and drop.itemid == item.itemid  and drop.index == item.index then
				flag = true
				break
			end
		end
		if flag == false then
			temp_list[#temp_list + 1] = drop
		end
	end
	return temp_list
end

local function  get_reward_data(count,reward_data,item_list,__floor)
	for i =1, count do
		local rewrd_list = get_endless_reward_list(reward_data,item_list)
		local taotal_weight = 0
		for j =1,#rewrd_list do
			taotal_weight = rewrd_list[j].weigh + taotal_weight
		end
		if taotal_weight >= 1 then
			local weight = 0
			local random_weight =  math.random(1,taotal_weight)
			for j =1,#rewrd_list do
				local drop = rewrd_list[j]
				weight = drop.weigh + weight
				if weight >= random_weight then
					local info = reward_item_gen()
					info.itemid = drop.itemid
					info.cnt = drop.cnt
					info.floor_cnt = drop.floor_cnt
					info.index = drop.index
					item_list[#item_list + 1] = info
					break
				end
			end
		end
	end
	return item_list
end

function itemdrop.random_endless_reward_rule(rewards,count,item_list,__floor)
	local reward_list = get_reward_info(rewards)
	get_reward_data(count,get_reward_info(rewards),item_list,__floor)
end

return itemdrop

