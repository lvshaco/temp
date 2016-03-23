--local shaco = require "shaco"
local shaco = require "shaco"
local pb = require "protobuf"
local sfmt = string.format
local tptask = require "__tptask"
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local task = require "task"
local tbl = require "tbl"
local itemop = require "itemop"
local card_container = require "card_container"
local tpgodcast = require "__tpgodcast"
local tpitem = require "__tpitem"
local tpskill = require "__tpskill"
local tpfestival_sign_base = require "__tpfestival_sign_base"
local tpfestival_bingtest_endlesstower = require "__tpfestival_bingtest_endlesstower"
local activity = require "activity"
local activity_fast = require "activity_fast"
local scene = require "scene"
local REQ = {}

REQ[IDUM_REQACTIVITYREWARD] = function(ur, v)
    shaco.debug("act request")
    local actid = v.activity_id
	local act_tp = activity_fast.get_activity_open(v.activity_id)
    if not act_tp then
        shaco.debug("act not open:"..actid)
		return SERR_ACTIVITY_NOT_OPEN
	end
    shaco.debug("act type:", actid)
	local result
	if actid == ACTIVITY_SIGN_IN_T then
		result = activity.deal_with_sign_in(ur)
	elseif actid == ACTIVITY_WAR_RESERVE then
		result = activity.deal_with_war_reserve(ur)
	elseif actid == ACTIVITY_ENDLESS then
		local tp = activity_fast.get_festival_bingtest_endlesstower(v.value)
		result = activity.deal_with_endless(ur,v,tp)
	elseif actid == ACTIVITY_ALCHEMY then
		result = activity.exchange_drawing(ur,v)
	elseif actid == ACTIVITY_EXCHANGE_COIN then
		result = activity.buy_coin(ur, v.value)
	elseif actid == ACTIVITY_LEVELUP then
		result = activity.os_levelup(ur, v)
	elseif actid == ACTIVITY_ECTYPE then
		result = activity.os_ectype(ur, v)
	elseif actid == ACTIVITY_DAILY_CHARGE1TH then
		result = activity.os_daily_charge1th(ur, v)
	--elseif actid == ACTIVITY_FIGHT then
	--	
	elseif actid == ACTIVITY_GOLD then
		result = activity.os_gold(ur)
	elseif actid == ACTIVITY_DIAMOND then
		result = activity.os_diamond(ur)
	elseif actid == ACTIVITY_CHARGE1TH then
		result = activity.charge1th(ur)
	elseif actid == ACTIVITY_SUM_CHARGE then
		result = activity.sum_charge(ur,v)
	elseif actid == ACTIVITY_BACK then
		result = activity.back(ur)
	end
    if result then
        return result
    else
        ur:send(IDUM_ACKACTIVITYREWARD, {activity_id=v.activity_id, value=v.value})
    end
end

REQ[IDUM_REQALCHEMY] = function(ur, v)
    local act_tp = activity_fast.get_activity_open(ACTIVITY_ALCHEMY)
    if not act_tp then
		--return SERR_ACTIVITY_NOT_OPEN
	end
    local result = activity.exchange_drawing(ur,v)
    if result then
        return result
    else
        ur:send(IDUM_ACKACTIVITYREWARD, 
        {activity_id=ACTIVITY_ALCHEMY, value=v.alchemy_id})
    end
end

REQ[IDUM_REQACTIVITY] = function(ur, v)
    local actid = v.activity_id
    local act_tp = activity_fast.get_activity_open(actid)
    if not act_tp then
        shaco.debug("act not open:"..actid)
	--	return SERR_ACTIVITY_NOT_OPEN
	end
    if actid == ACTIVITY_FIGHT then
        return activity.os_rank_fight(ur)
    end
end

REQ[IDUM_REQBUGCOIN] = function(ur, v)
	local result = activity.buy_coin(ur, v.buy_type)
	return result
end

REQ[IDUM_REQTOLLGATEECTYPE] = function(ur, v)
	local flag = activity.check_activity_ectype_cnt(ur,v)
	if flag == 2  then
		return SERR_ACTIVITY_CNT_OVER
	end
	local scene_id = activity_fast.check_activity_open(v.toll_gate_type)
	
	if scene_id > 0 then
		local ok = scene.enter(ur, scene_id)
		if ok then
			--print("scene_id === "..scene_id)
			activity.deal_with_activity_ectype(ur,v)
		end
	end
end

REQ[IDUM_REQBALANCEWOODBARREL] = function(ur, v)
	local total_score = activity.balance_wood_barrel_score(v.monster_list)
	local act = ur.activity
	--print("total_score === "..total_score)
	--tbl.print(act," ----- act ===== ")
	local rank_data = activity.get_activity_rank(act,v.ectype_type)
	if rank_data then
		--tbl.print(rank_data,"rank_data ----- total_score == "..total_score)
		rank_data.score = rank_data.score + total_score
		rank_data.ectype_cnt = rank_data.ectype_cnt + 1
		activity_fast.deal_with_wood_barrel(ur,rank_data)
		ur:db_tagdirty(ur.DB_ACTIVITY)
	else
		print(" ----------- IDUM_REQBALANCEWOODBARREL  is error -------")
	end
end

return REQ
