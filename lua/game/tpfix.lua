local shaco = require "shaco"
local pb = require "protobuf"
local tptask = require "__tptask"
local tpforge = require "__tpforge"
local tpgodcast = require "__tpgodcast"
local find = string.find
local sub = string.sub
local len = string.len
local sfmt = string.format
local tbl = require "tbl"
local tpendlesstower = require "__tpendlesstower"
local tonumber = tonumber
local gmatch = string.gmatch
local tpfix = {}

local tp_forge = {}
local tp_endlesstower = {}
local function reward_gen()
	return {
		itemid = 0,
		itemcnt = 0,
		weigh = 0,
		cur_floor = 0,
	}
end

local function endless_tower_reward()
	return {
		num = 0,
		reward_list = {}
	}
end

local function change_endless_tower()
	for k,v in pairs (tpendlesstower) do
		local streward = v.Reward
		local __list = {}
		for w in gmatch(streward, "[^}]+") do
			local temp_list = {}
			for k in gmatch(w, "[^{]+") do
				temp_list[#temp_list + 1] = k
			end
			local data = endless_tower_reward()
			data.num = tonumber(temp_list[1])
			local reward_list = {}
			for m in gmatch(temp_list[2], "[^;]+") do
				local index = 1
				local info = reward_gen()
				for j in gmatch(m, "[^:]+") do
					local value = tonumber(j)
					if index == 1 then
						info.itemid = value
					elseif index == 2 then
						info.itemcnt = value
					elseif index == 3 then
						info.weigh = value
					end
					index = index + 1
				end
				info.cur_floor = v.Number
				reward_list[#reward_list + 1] = info
			end
			data.reward_list = reward_list
			__list[#__list + 1] = data
		end
		v.Reward = __list
	end
end

function tpfix.init()
	local tempforge = {}
	for i =1,#tpforge do
		local tp = tpforge[i]
		local indx = (tp.ID << 2) + tp.needRole
		tempforge[indx] = tp
	end
	tp_forge = tempforge
	change_endless_tower()
end

function tpfix.get_forge()
	return tp_forge
end

return tpfix
