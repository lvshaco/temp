local shaco = require "shaco"
local pb = require "protobuf"
local tbl = require "tbl"
local sfmt = string.format
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local tpgamedata = require "__tpgamedata"
local card_container = require "card_container"
local spectype = require "spcial_ectype"
local endless_fast = require "endless_fast"
local scene = require "scene"
local activity_fast = require "activity_fast"

local REQ = {}

REQ[IDUM_REQSETCANDIDATE] = function(ur, v)
	return spectype.set_candidate(ur,v)
end

REQ[IDUM_REQSTARTCHALLENGE] = function(ur, v)
	local spectypev = ur.spectype
	local __sceneid = 6001
	local ok = scene.enter(ur, __sceneid)
	if ok then	
		spectype.enter_endless_tower(ur,v.enter_type)
	end
end

REQ[IDUM_SENDENDLESSTOWERDATA] = function(ur, v)
	local front_floor = spectype.sync_endless_tower_ectype(ur, v)
	endless_fast.balance_endless_rank(ur,front_floor)
end

REQ[IDUM_REQAUTOMATICCHALLENGE] = function(ur, v)
	local front_floor = spectype.auto_matic_challenge(ur)
	if front_floor > 0 then
		endless_fast.balance_endless_rank(ur,front_floor)
	end
end

REQ[IDUM_NOTICEENDLESSTOWEROVER] = function(ur, v)
	spectype.notice_endless_tower_over(ur)
	local spectypev = ur.spectype
	endless_fast.balance_endless_rank(ur,spectypev.front_floor)
end

REQ[IDUM_REQBUYREVIVE] = function(ur, v)
	spectype.buy_revive(ur)
end

REQ[IDUM_REQSTARTSPECTYPE] = function(ur, v)
	spectype.start_spectype(ur,v)
end

REQ[IDUM_REQMOMENTREWARD] = function(ur, v)
	if v.result == 1 then
		local difficulty = spectype.get_moment_reward(ur,v.number,v.pass_time)
		activity_fast.balance_exp_rank(ur,difficulty,v.pass_time)
	end 
end

REQ[IDUM_REQCHALLENGEREWARD] = function(ur, v)
	local coin,difficulty = spectype.get_challenge_coin(ur, v)
	--tbl.print(v,"------------v -------===== ")
	--print("coin == "..coin.." --- difficulty ==  "..difficulty)
	activity_fast.balance_money_rank(ur,difficulty,coin)
end

REQ[IDUM_REQBUYENDLESSCHALLENGECNT] = function(ur, v)
	local cnt = 0
	if v.buy_type == 1 then
		cnt = ur:get_vip_value(VIP_ENDLESS_TOWER_T)
	elseif v.buy_type == 2 then
		cnt = ur:get_vip_value(VIP_EXP_TOWER_T)
	elseif v.buy_type == 3 then
		cnt = ur:get_vip_value(VIP_MONEY_TOWER_T)
	end
	if cnt > 0 then
		spectype.req_buy_challenge_cnt(ur,v.buy_type,cnt)
	end
end


return REQ
