local shaco = require "shaco"
local tbl = require "tbl"
local card_container = require "card_container"
local sfmt = string.format
local itemop = require "itemop"
local tppayprice = require "__tppayprice"
local tpexptower = require "__tpexptower"
local tpmoneytower = require "__tpmoneytower"

local endless_tower = {}

local function endless_tower_gen()
	return {
		name = "",
		max_floor = 0,
		create_time = 0,
		rank = 0,
	}
end

function endless_tower.new(endless_towerv,name)
	local __endless_tower = endless_tower_gen()
	if endless_towerv then
		return endless_towerv
	else
		__endless_tower.name = name
	end
	return __endless_tower
end













return endless_tower
