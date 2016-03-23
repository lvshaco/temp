--local shaco = require "shaco"
local shaco = require "shaco"
local pb = require "protobuf"
local tbl = require "tbl"
local sfmt = string.format
local floor = math.floor
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local tpnormal_shop = require "__tpnormal_shop"

local shop = {}

local function normal_gen()
	return {
		start_time = 0,
		info = {},
		refresh_cnt = 0,
	}
end

local function normal_item_gen()
	return {
		itemid = 0,
		itemcnt = 0,
		pos = 0,
		falg = 0,
		mystery_id = 0,
		mystery_item_id = 0,
		money_type = 0,
		money = 0,
		hole_cnt = 0,
		wash_cnt = 0,
	}
end

local function random_normal_item(shop_info)
	local item_list = {}
	for i = 1,12 do
		local total_weight = 0
		local items = shop_info["position"..tostring(i).."_item"]
		if #items >0 then
			for j =1,#items do
				local info = items[j]
				total_weight = total_weight +info.weighing
			end
			local random_value = math.random(1,total_weight)
			local weight = 0
			for j =1,#items do
				local info = items[j]
				weight = weight +info.weighing
				if weight >= random_value then
					local item_info = mystery_item_gen()
					item_info.itemid = info.item_id
					item_info.itemcnt = info.count
					item_info.pos = i
					item_info.falg = 0
					item_info.mystery_id = shop_info.mystery_id
					item_info.mystery_item_id = info.mystery_item_id
					item_info.money_type = info.money
					item_info.money = info.money_count
					item_info.hole_cnt = shop_info.GemMax
					item_info.wash_cnt = shop_info.WashMax
					item_list[#item_list + 1] = item_info
					break
				end
			end
		end
	end
	return item_list
end

local function random_item(ur)
	local level = ur.base.level
	local mystery_list = {}
	local total_weight = 0
	for k,v in pairs(tpnormal_shop) do
		if v.user_level[1][1] <= level and v.user_level[1][2] >= level then
			mystery_list[#mystery_list + 1] = v
			total_weight = total_weight + v.weight
		end
	end
	local weight = 0
	local mystery_info = {}
	local random_weight = math.random(1,total_weight)
	for i =1,#mystery_list do
		weight = weight + mystery_list[i].weight
		if weight >= random_weight then
			mystery_info = random_mystery_item(mystery_list[i])
			break
		end
	end
	return mystery_info
	
end

function mystery.random_mystery_shop(ur,probability)
	local rand_value = math.random(1,100)
	if rand_value < probability then
		local mystery_info = normal_gen()
		mystery_info.start_time = shaco.now()//1000
		mystery_info.info = random_item(ur)
		ur.info.mystery = nil
		ur.info.mystery = mystery_info
		ur:send(IDUM_NOTICEMYSTERYSHOP, {info = mystery_info,start_time = mystery_info.start_time})
		return true
	end
	return false
end

function mystery.refresh_mystery_shop(ur)
	local item_list = {}
	item_list = random_item(ur)
	ur.info.mystery.refresh_cnt = ur.info.mystery.refresh_cnt + 1
	ur.info.mystery.info = item_list
	ur:send(IDUM_ACKREFRESHMYSTERYRESULT, {info = item_list,refresh_cnt = ur.info.mystery.refresh_cnt})
end

return shop
