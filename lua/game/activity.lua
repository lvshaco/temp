-------------------interface---------------------
--function task_check_state(task, task_type, parameter1, parameter2)
--function task_accept(task,id)
-------------------------------------------------
local shaco = require "shaco"
local util = require "util"
local ectype = require "ectype"
local tptask = require "__tptask"
local bit32 = require"bit32"
local tbl = require "tbl"
local ipairs = ipairs
local sfmt = string.format
local sfind = string.find
local sub = string.sub
local len = string.len
local task_fast = require "task_fast"
local tpgamedata = require "__tpgamedata"
local itemop = require "itemop"
local tpskill = require "__tpskill"
local tpitem = require "__tpitem"
local tpfestival_alchemy = require "__tpfestival_alchemy"
local tpbuygold_cost = require "__tpbuygold_cost"
local tppayprice = require "__tppayprice"
local tpfestival_sign_base = require "__tpfestival_sign_base"
local tpfestival_bingtest_endlesstower = require "__tpfestival_bingtest_endlesstower"
local tpfestival_openservice = require "__tpfestival_openservice"
local tpfestival_3activities = require "__tpfestival_3activities"
local tpfestival_battle_boar = require "__tpfestival_battle_boar "
local tpdeadcanyon = require "__tpdeadcanyon"
local rank_fight = require "rank_fight"
local card_container = require "card_container"

local function activity_ectype_unrank_gen()
	return {
		difficulty = 0,
		ectype_cnt = 0,
		ectype_type = 0,
	}
end

local function activity_ectype_rank_gen()
	return {
		score = 0,
		ectype_cnt = 0,
		ectype_type = 0,
	}
end

local function act3_max(type, param)
    local t = tpfestival_3activities[type]
    if t then
        local tp 
        for _, v in ipairs(t) do
            if param>=v.Parameter then
                tp = v
            else break
            end
        end
        return tp
    end
end

local function act3_get(type, param)
    local t = tpfestival_3activities[type]
    if t then
        for _, v in ipairs(t) do
            if param==nil or v.Parameter == param then
                return v
            end
        end
    end
end

local function actos_get(type, param)
    local t = tpfestival_openservice[type]
    if t then
        for _, v in ipairs(t) do
            if param == nil or v.Parameter == param then
                return v
            end
        end
    end
end

local activity = {}
--math.randomseed(os.time())
local function daily_charge1th_gen(i)
	return {
		recharge_indx = i,
		reward_state = 0,
	}
end

local function init_daily_charge1th()
	local daily_charge1th_list = {}
	for i = 1,3 do
		local info = daily_charge1th_gen(i)
		daily_charge1th_list[#daily_charge1th_list + 1] = info
	end
	return daily_charge1th_list
end

local function activity_info_gen()
	return {
		teamid = 1,
		count = 0,
		war_reserve = 0,
		base_floor = 0,
		cur_floor = 0,
		money_difficulty = 0,
		money_cnt = 0,
		exp_difficulty = 0,
		exp_time = 0,
		sign_in_flag = 0,
		exchange_coin_cnt = 0,
        floor_award_flags = {},
        levelup_award = {},
        ectype_award= {},
        daily_charge1th_award_times = 0,
        daily_charge1th_award = 0,
        gold_award=0,
        diamond_award=0,
        charge1th_award =0,
        sum_charge_award ={},
        back_award=0,
		alchemys = {},
		activity_rank = {},
		activity_unrank = {},
		daily_charge1th_list = init_daily_charge1th(),
    }
end

local function init_alchemy(level)
	local tmp_list = {}
	local total_weigh = 0
    for k,v in ipairs(tpfestival_alchemy) do
        if v.LV <= level then
            total_weigh = total_weigh + v.Item_Id[2]
            tmp_list[#tmp_list+1] = {v,total_weigh}
		end
	end
	local alchemy_list = {}
    for i=1,10 do
        if #tmp_list ==0 then
            break
        end
        local randvalue = math.random(1,total_weigh)
        for k,v in ipairs(tmp_list) do
            if v[2] >= randvalue then
                alchemy_list[#alchemy_list + 1] = v[1]
                table.remove(tmp_list, k)
                total_weigh = 0
                for k, v in ipairs(tmp_list) do
                    total_weigh = total_weigh+v[1].Item_Id[2]
                    v[2] = total_weigh
                end
                break
            end
        end
    end
	for k,v in ipairs(alchemy_list) do
        alchemy_list[k] = v.ID
	end
	return alchemy_list
end

function activity.new(ur, activityv)
	if activityv then
        if #activityv.alchemys==0 then
            activityv.alchemys = {}
        end
        if #activityv.floor_award_flags==0 then
            activityv.floor_award_flags={}
        end
        if #activityv.levelup_award==0 then
            activityv.levelup_award={}
        end
        if #activityv.ectype_award==0 then
            activityv.ectype_award={}
        end
        if #activityv.sum_charge_award==0 then
            activityv.sum_charge_award={}
        end
		if not activityv.activity_rank or #activityv.activity_rank == 0 then
			activityv.activity_rank = {}
		end
		if not activityv.activity_unrank or #activityv.activity_unrank == 0 then
			activityv.activity_unrank = {}
		end
		if not activityv.daily_charge1th_list or #activityv.daily_charge1th_list == 0 then
			activityv.daily_charge1th_list = init_daily_charge1th()
		end
		return activityv	
	end
	local act = activity_info_gen()
	act.alchemys = init_alchemy(ur.base.level)
	act.exchange_coin_cnt = 0
    if ur.info.logout_time > 0 then
		local offline_day = (ur.info.login_time - ur.info.logout_time)//86400
		local tp = act3_get(3, nil)
		--print("new ------ ur.info.login_time == "..ur.info.login_time.."  ur.info.logout_time  === "..ur.info.logout_time.."  offline_day ==== "..offline_day)
		if tp then
			if offline_day >= tp.Parameter then
				act.back_award = offline_day
			end
		end
	end
	local level = ur.base.level
	for i =2,3 do
		local tp = tpdeadcanyon[i]
		for k,v in ipairs(tp.NeedLevel) do
			if v[2] <= level then
				if i == 2 then
					act.money_difficulty = v[1]
				elseif i == 3 then
					act.exp_difficulty = v[1]
				end
			end
		end
	end
	if act.money_difficulty == 0 then
		act.money_difficulty = 1
	end
	if act.exp_difficulty == 0 then
		act.exp_difficulty = 1
	end
	return act
end


function activity.onchangeday(ur,login_state)
	local act = ur.activity
	act.sign_in_flag = 0
	act.alchemys = init_alchemy(ur.base.level)
	act.exchange_coin_cnt = 0
	act.daily_charge1th_award_times = 0
    act.daily_charge1th_award = 0
	act.war_reserve = 0
	for i = 1,3 do
		local daily_charge = act.daily_charge1th_list[i]
		daily_charge.reward_state = 0
	end
	if ur.info.logout_time > 0 then
		local offline_day = (ur.info.login_time - ur.info.logout_time)//86400
		--print("ur.info.login_time == "..ur.info.login_time.."  ur.info.logout_time  === "..ur.info.logout_time.."  offline_day ==== "..offline_day)
		local tp = act3_get(3, nil)
		if tp then
			if offline_day >= tp.Parameter then
				act.back_award = offline_day
			end
		end
	end
	ur:db_tagdirty(ur.DB_ACTIVITY)
	local level = ur.base.level
	for i =2,3 do
		local tp = tpdeadcanyon[i]
		for k,v in ipairs(tp.NeedLevel) do
			if v[2] <= level then
				if i == 2 then
					act.money_difficulty = v[1]
				elseif i == 3 then
					act.exp_difficulty = v[1]
				end
			end
		end
	end
	if login_state == 2 then
		ur:send(IDUM_NOTICEOPENACTIVITYINFO, {own_activity = act})
	end
end

-- helper
local function has_awarded(flags, value)
    for k, v in ipairs(flags) do
        if v == value then
            return true
        end
    end
    return false
end

local function give_award(ur, awards)
    local items = {}
    for _, v in ipairs(awards) do
        if v[1] == 1 then
            table.insert(items, {v[2],v[3]})
        end
    end
    if not itemop.can_gain(ur, items) then
        return false, SERR_PACKAGE_SPACE_NOT_ENOUGH 
    end
    for _, v in ipairs(items) do
        itemop.gain(ur, v[2], v[3],0,0)
		ur:db_tagdirty(ur.DB_ITEM)
    end
    for _, v in ipairs(awards) do
        if v[1] == 0 then
            if v[2] == 0 then
                ur:coin_got(v[3])
                ur:db_tagdirty(ur.DB_ROLE)
            elseif v[2] == 1 then
                ur:gold_got(v[3])
                ur:db_tagdirty(ur.DB_ROLE)
            end
        end
    end
    return true
end

local function give_award_back(ur, awards, times)
    local v = awards[1]
    ur:coin_got(v[1] *times)
    ur:gold_got(v[2] *times)
    ur:addexp(v[3] *times)
    ur:db_tagdirty(ur.DB_ROLE)
end

local function give_award4(ur, awards)
	local cards = {}
    local items = {}
	local sunc_flag = false
	local item_flag = false
	local card_flag = false
    local myrace = ur.base.race
    for _, v in ipairs(awards) do
        local race = v[1]
        if race==0 or race==myrace then
            if v[2] == 0 then
				 if v[3] == 1 then
                    ur:coin_got(v[4])
                    sunc_flag = true
                elseif v[3] == 2 then
                    ur:gold_got(v[4])
                    sunc_flag = true
                else
					table.insert(items, {v[3],v[4]})
				end
			elseif v[2] == 1 then
				table.insert(cards, {v[3],v[4]})
            end
        end
    end
    if not itemop.can_gain(ur, items) then
        return false, SERR_PACKAGE_SPACE_NOT_ENOUGH 
    end
    for _, v in ipairs(items) do
        itemop.gain(ur, v[1], v[2],0,0)
		item_flag = true
    end
	for _, v in ipairs(cards) do
		if ur.cards:put(ur,v[1], v[2]) > 0 then
			card_flag = true
		end
	end
	if card_flag then
		card_container.refresh(ur)
		ur:db_tagdirty(ur.DB_CARD)
	end
	if sunc_flag then
		ur:db_tagdirty(ur.DB_ROLE)
		ur:sync_role_data()
	end
	if item_flag then
		itemop.refresh(ur)
		ur:db_tagdirty(ur.DB_ITEM)
	end
    return true
end


local function check_material_cnt(bag,quality,Pay)
	local material_cnt = 0
	local item_posv = {}
	local flag = false
	local material_list = itemop.getall(bag)
	for _,v in ipairs(material_list) do
		local tp_item = tpitem[v.tpltid]
		if tp_item.quality == quality and tp_item.itemType == itemType then
			local posv = {}
			posv[1] = v.posv
			posv[2] = v.stack
			item_posv[#item_posv + 1] = posv
			material_cnt = material_cnt + v.stack
			if material_cnt >= Pay then
				flag = true
				break
			end
		end
	end
	return flag,item_posv
end

function activity.exchange_drawing(ur,v)
    local alchemy_id = v.alchemy_id
    local item_list = v.item_list
	local _exist = false
	local activityv = ur.activity
	for i = 1,#activityv.alchemys do
        shaco.trace(activityv.alchemys[i], alchemy_id)
		if activityv.alchemys[i] == alchemy_id then
			_exist = true
		end
	end
	if not _exist then
		return SERR_ALCHEMY_NOT_EXIST
	end
	local tp = tpfestival_alchemy[alchemy_id]
	local mat = ur:getbag(BAG_MAT)
    local gain_itemid = tp.Item_Id[1]
    local gain_count = tp.Item_Id[2]

    if not itemop.can_gain(ur, {{gain_itemid, gain_count}}) then
        return SERR_PACKAGE_SPACE_NOT_ENOUGH 
    end
	local tp_target = tpitem[gain_itemid]
    local sum = 0
    for k, v in ipairs(item_list) do
        sum = sum + v.int2
    end
    if sum ~= tp.Pay then
        return SERR_MATERIAL_NOT_ENOUGH
    end
    for k, v in ipairs(item_list) do
        local item = mat:get(v.int1)
        if not item or 
            item.stack < v.int2 then
            return SERR_MATERIAL_NOT_ENOUGH
        end
        local tp = tpitem[item.tpltid]
        if not tp then
            return SERR_NOTPLT
        end
        if tp.quality ~= tp_target.quality or
           tp.itemType ~= tp_target.itemType then
            return SERR_UNKNOW
        end
    end
    for k, v in ipairs(item_list) do
        if itemop.remove_bypos(mat, v.int1, v.int2) ~= v.int2 then
            return SERR_UNKNOW
        end
    end
    itemop.gain(ur, gain_itemid, gain_count)

	for i = 1,#activityv.alchemys do
		if activityv.alchemys[i] == alchemy_id then
            table.remove(activityv.alchemys, i)
            break
		end
	end
    itemop.refresh(ur)
    ur:db_tagdirty(ur.DB_ITEM)
	ur:db_tagdirty(ur.DB_ACTIVITY)
end

local function get_buy_coin_cnt(level)
	local flag = 0
	local tp = tpbuygold_cost[level]
	if not tp then
		tp = tpbuygold_cost[#tpbuygold_cost]
	end
	local total_cnt = 0
	local CritBouns = 1
	local randvalue = math.random(1,10000)
	if randvalue < tp.Crit then
		local multiple,_decimals = math.modf(tp.CritBouns/10000)
		CritBouns = multiple
		flag = 1
	end
	total_cnt = total_cnt + tp.Gold * CritBouns
	return flag,total_cnt
end

local function buy_coin_gen()
	return {
		coin = 0,
		state = 0,
	}
end

local function cost_gold(count)
	local money_type = 0
	local take = 0
	for k,v in pairs(tppayprice) do
		if v.type == 8 and v.start <= count and v.stop >= count then
			money_type = v.money_tpye
			take = v.number
			break
		end
	end
	return money_type,take
end
 --摇钱树
function activity.buy_coin(ur,buy_type)
--	print("------ buy_type == "..buy_type)
	--local activityv = ur.activity
    local max_cnt = ur:get_vip_value(VIP_BUYGOLD_T)
   
    local cur_cnt = ur.info.exchange_coin_cnt
	if cur_cnt >= max_cnt then
		return SERR_BUY_CNT_NOT_ENOUGH
	end
    local remain_cnt = max_cnt - cur_cnt
    local buy_cnt
	if buy_type == BUY_ONCE then
        buy_cnt = 1
    else
        buy_cnt = remain_cnt > 10 and 10 or remain_cnt
    end
    local cost = 0
    for i = 1,buy_cnt do
        local money_type,take = cost_gold(cur_cnt + i)
        cost = cost + take
    end
    if ur:gold_take(cost) == false then
        return SERR_GOLD_NOT_ENOUGH
    end
	local result_list = {}
	local total_coin = 0
    for i=1,buy_cnt do
        local flag,total_cnt = get_buy_coin_cnt(ur.base.level)
        result_list[#result_list + 1] = {coin = total_cnt, state=flag}
		total_coin = total_coin + total_cnt
    end
	ur:coin_got(total_coin)
    ur.info.exchange_coin_cnt = cur_cnt + buy_cnt
	ur:db_tagdirty(ur.DB_ACTIVITY)
	ur:db_tagdirty(ur.DB_ROLE)
	ur:sync_role_data()
	ur:send(IDUM_ACKBUGCOIN, {info = result_list})
end

function activity.deal_with_endless(ur,v,tp)
	local activityv = ur.activity
    if v.value <= 0 or v.value > activityv.cur_floor-activityv.base_floor then
		return SERR_ACTIVITY_ENDLESS_REWARD_NOT_GET
    end
	--if activityv.cur_floor + v.value < activityv.base_floor then
	--	return SERR_ACTIVITY_ENDLESS_REWARD_NOT_GET
	--end
    if not tp then
        return SERR_NOTPLT
    end 
    if has_awarded(activityv.floor_award_flags, v.value) then
        return SERR_HAS_AWARDED
    end
	local item_flag = false
	local card_flag = false
	local sunc_flag = false
	local items = tp.BOUNS
	for i = 1,#items do
		local item = items[i]
		if item[1] == 0 then
			local tp_item = tpitem[item[2]]
			if tp_item.itemType == ITEM_RESOURCE then
				if item[2] == 1 then --coin
					ur:coin_got(item[3])
				elseif item[2] == 2 then
					ur:gold_got(item[3])
				end
				sunc_flag = true
			else
				--print("item[2] === "..item[2].."  item[3] =-==  "..item[3])
				 itemop.gain(ur,item[2],item[3])
				 item_flag = true
			end
		else
			if ur.cards:put(ur,item[2],item[3]) > 0 then
				card_flag = true
			end
		end
	end
	if item_flag then
		itemop.refresh(ur)
		ur:db_tagdirty(ur.DB_ITEM)
	end
	if card_flag then
		card_container.refresh(ur)
		ur:db_tagdirty(ur.DB_CARD)
	end
	if sunc_flag then
		ur:db_tagdirty(ur.DB_ROLE)
		ur:sync_role_data()
	end
	--activityv.cur_floor = activityv.cur_floor + v.value
    table.insert(activityv.floor_award_flags, v.value)
	ur:db_tagdirty(ur.DB_ACTIVITY)
end

local function get_vip_power_reward(ur)
	local reward = ur:get_power_reward()
	if not reward then
		return 
	end
	local _type = reward[1]
	local value = reward[2]
	local flag = false
	if _type == 1 then
		ur.info.physical = ur.info.physical + value
		flag = true
	elseif _type == 2 then
		ur.info.coin = ur.info.coin + value
		flag = true
	elseif _type == 3 then
		ur.info.gold = ur.info.gold + value
		flag = true
	elseif _type == 4 then
		local ladder_info = ur.ladder
		ladder_info.challengecnt = ladder_info.challengecnt + 1
		ur:db_tagdirty(ur.DB_LADDER)
	end
	if flag then
		ur:sync_role_data()
		ur:db_tagdirty(ur.DB_ROLE)
	end
	ur:send(IDUM_SYNCPOWERREWARD, {reward_type = _type,reward_cnt = value})
end

function activity.deal_with_war_reserve(ur)
	local activityv = ur.activity
	if activityv.war_reserve >= 2 then
		return SERR_WAR_RESERVE_CNT_NOT_ENOUGH
	end
	local now = shaco.now()//1000 --当前时间
	local cur_time=os.date("*t",now)
	if cur_time.hour >= 12 and cur_time.hour < 15 then
		if activityv.war_reserve >= 1 then
			return SERR_WAR_RESERVE_CNT_NOT_ENOUGH
		end
		activityv.war_reserve = 1--activityv.war_reserve + 1
	elseif cur_time.hour >= 18 and cur_time.hour < 21 then
		activityv.war_reserve = 2--activityv.war_reserve + 1
	else
		return SERR_ACTIVITY_NOT_OPEN
	end
    shaco.debug("--------aaaa", activityv.war_reserve)
	ur.info.physical = ur.info.physical + tpgamedata.Power
	ur:sync_role_data()
	ur:db_tagdirty(ur.DB_ROLE)
	get_vip_power_reward(ur)
	ur:db_tagdirty(ur.DB_ACTIVITY)
end

local function get_sign_in_reward(ur,awards)
	local rate = 1
	local vip_level = ur.info.vip.vip_level
	if vip_level >= awards[1] then
		rate = awards[2]
	end
	if rate == 0 then
		rate = 1
	end
	local item_flag = false
	local card_flag = false
	local sunc_flag = false
	if awards[3] == 0 then
		local tp_item = tpitem[awards[4]]
		if tp_item and tp_item.itemType == ITEM_RESOURCE then
				if awards[4] == 1 then --coin
					ur:coin_got(awards[5] * rate)
				elseif awards[4] == 2 then
					ur:gold_got(awards[5] * rate)
				end
				sunc_flag = true
		else
			itemop.gain(ur,awards[4],awards[5] * rate)
			item_flag = true
		end
	else
		if ur.cards:put(ur,awards[4],awards[5] * rate) > 0 then
			card_flag = true
		end
	end
	if item_flag then
		itemop.refresh(ur)
		ur:db_tagdirty(ur.DB_ITEM)
	end
	if card_flag then
		card_container.refresh(ur)
		ur:db_tagdirty(ur.DB_CARD)
	end
	if sunc_flag then
		ur:db_tagdirty(ur.DB_ROLE)
		ur:sync_role_data()
	end
end

function activity.deal_with_sign_in(ur)
    shaco.debug("sign in")
	local activityv = ur.activity
    if activityv.sign_in_flag ~= 0 then
        return SERR_HAS_AWARDED
    end
	local teamid = activityv.teamid
	local sign_in_cnt = activityv.count
	local tp
	local tp_sign_in = tpfestival_sign_base[teamid]
	if tp_sign_in then
		for k,u in pairs(tp_sign_in) do
			if u.Count == sign_in_cnt + 1 then
				tp = u
			end
		end
	end
	if not tp then
		tp_sign_in = tpfestival_sign_base[teamid + 1]
		activityv.count = 1
		activityv.teamid = activityv.teamid + 1
		tp = tp_sign_in[1]
	else
		activityv.count = activityv.count + 1
	end
	get_sign_in_reward(ur, tp.BOUNS)
	activityv.sign_in_flag = 1
	ur:db_tagdirty(ur.DB_ACTIVITY)
    shaco.debug("sign in ok")
end

-- 首冲
function activity.charge1th(ur)
    local act  = ur.activity
    local tp = act3_get(1, nil)
    if not tp then 
        return SERR_NOTPLT
    end
    if act.charge1th_award == 2 then
        return SERR_HAS_AWARDED
	elseif act.charge1th_award == 1 then
		return SERR_NO_RECHARGE
    end
    if ur:getrmb() <= 0 then
        return SERR_UNKNOW
    end
    local ok, err = give_award(ur, tp.Items)
    if not ok then
        return err
    end
    act.charge1th_award = 2
    ur:db_tagdirty(ur.DB_ACTIVITY)
end

-- 累积充值
function activity.sum_charge(ur, v)
    local act = ur.activity
    local tp = act3_get(2, v.value)
    if not tp then
        return SERR_NOTPLT
    end
    if has_awarded(act.sum_charge_award, v.value) then
        return SERR_HAS_AWARDED
    end
    if ur:getrmb() < v.value then
        return SERR_UNKNOW
    end
    local ok, err = give_award(ur, tp.Items)
    if not ok then
        return err
    end
    table.insert(act.sum_charge_award, v.value)
    ur:db_tagdirty(ur.DB_ACTIVITY)
end

-- 回归
function activity.back(ur)
    local act = ur.activity
    if act.back_award== 0 then
        return SERR_NO_COND
    end
    local tp = act3_get(3, nil)
    if not tp then
        return SERR_NOTPLT
    end
    local times = act.back_award-tp.Parameter+1
	give_award_back(ur, tp.Items, times)
    act.back_award = 0
    ur:db_tagdirty(ur.DB_ACTIVITY)
end

-- 冲级大礼包
function activity.os_levelup(ur, v)
    shaco.debug("os_levelup", v.value)
    local act = ur.activity
    local tp = actos_get(1, v.value)
    if not tp then
        return SERR_NOTPLT
    end
    if has_awarded(act.levelup_award, v.value) then
        return SERR_HAS_AWARDED
    end
    local level = ur.base.level
    if level < v.value then
        return SERR_NO_COND
    end
    local ok, err = give_award4(ur, tp.Items)
    if not ok then
        return err
    end
    table.insert(act.levelup_award, v.value)
    ur:db_tagdirty(ur.DB_ACTIVITY)
    shaco.debug("os_levelup ok")
end

-- 推图大礼包
function activity.os_ectype(ur, v)
    local act = ur.activity
    local tp = actos_get(2, v.value)
    if not tp then
        return SERR_NOTPLT
    end
    if has_awarded(act.ectype_award, v.value) then
        return SERR_HAS_AWARDED
    end
    local all_star = 0
    local ectype_list = ur.info.ectype
    for i = 1,#ectype_list do
        all_star = all_star + ectype_list[i].star
    end
    if all_star < tp.Parameter then
        return SERR_NO_COND
    end
    local ok, err = give_award4(ur, tp.Items)
    if not ok then
        return err
    end
    table.insert(act.ectype_award, v.value)
    ur:db_tagdirty(ur.DB_ACTIVITY)
end

-- 每日首冲大礼包
function activity.os_daily_charge1th(ur,v)
	local pos = v.value
    local act = ur.activity
	local flag = false
	for i = 1,3 do
		local daily_charge = act.daily_charge1th_list[i]
		if daily_charge.recharge_indx == pos and daily_charge.reward_state == 1 then
			daily_charge.reward_state = 2
			flag = true
		end 
	end
	if not flag then
		return SERR_HAS_AWARDED
	end
    local tp = actos_get(3,pos) 
    if not tp then
        return SERR_NOTPLT
    end
	--[[local now_day = util.second2day(shaco.now()//1000)
    local rmb_day = util.second2day(ur.info.rmb_last_time)
    if rmb_day ~= now_day then
        return SERR_NO_COND
    end]]
    local ok, err = give_award4(ur, tp.Items)
    if not ok then
        return err
    end
    ur:db_tagdirty(ur.DB_ACTIVITY)
end

-- 开服黄金礼包
function activity.os_gold(ur)
    local act = ur.activity
    if act.gold_award ~=0 then
        return SERR_HAS_AWARDED
    end
    local viplv = ur.info.vip.vip_level
    if viplv < 1 then
        return SERR_NO_COND
    end
    local tp = actos_get(5,nil) 
    if not tp then
        return SERR_NOTPLT
    end
    local cost = tp.Parameter
	if not ur:coin_enough(cost) then 
		return SERR_COIN_NOT_ENOUGH
	end
    local ok, err = give_award4(ur, tp.Items)
    if not ok then
        return err
    end
    ur:coin_take(cost)
	print("cost === "..cost)
    ur:db_tagdirty(ur.DB_ROLE)
    act.gold_award=1
    ur:db_tagdirty(ur.DB_ACTIVITY)
end

-- 开服钻石礼包
function activity.os_diamond(ur)
    local act = ur.activity
    if act.diamond_award ~=0 then
        return SERR_HAS_AWARDED
    end
    local viplv = ur.info.vip.vip_level
    if viplv < 1 then
        return SERR_NO_COND
    end
    local tp = actos_get(6,nil) 
    if not tp then
        return SERR_NOTPLT
    end
    local cost = tp.Parameter
	if not ur:coin_enough(cost) then 
		return SERR_COIN_NOT_ENOUGH
	end
    local ok, err = give_award4(ur, tp.Items)
    if not ok then
        return err
    end
    ur:coin_take(cost)
    ur:db_tagdirty(ur.DB_ROLE)
    act.diamond_award=1
    ur:db_tagdirty(ur.DB_ACTIVITY)
end

function activity.os_rank_fight(ur)
    local tpv = tpfestival_openservice[4]
    if not tpv then
        return SERR_NOTPLT
    end
	local need_list = rank_fight.get_need_rank_list()
	local own_rank = rank_fight.get_own_rank_info(ur.base.roleid)
    --[[local last_rank = rank_fight.get_lastrank()
    local values = {}
    for k, v in ipairs(tpv) do
        local cur_rank = v.Parameter
        if cur_rank >= last_rank then
            cur_rank = last_rank
        end
        local info = rank_fight.get_rankinfo(cur_rank)
        if info then
            table.insert(values, info.fight)
        else
            table.insert(values, 0)
        end
        if cur_rank>= last_rank then
            break
        end
    end]]
    ur:send(IDUM_ACKBATTLERANK, {ranks =need_list,own_rank = own_rank})
end

local function get_total_count(ectype_type)
	local total_cnt = 0
	if ectype_type == TOLL_GATE_MECHANINICALBREAKER_T then --车辆破坏
		total_cnt = 3
	elseif ectype_type == TOLL_GATE_DEADTOMBSTON_T then --亡灵墓碑
		total_cnt = 3
	elseif ectype_type == TOLL_GATE_VAMPIREKNIGHT_T then -- 吸血鬼骑士的诅咒
		total_cnt = 3
	elseif ectype_type == TOLL_GATE_SKILLS_T then -- 赏金猎人
		total_cnt = 3
	elseif ectype_type == TOLL_GATE_GOBLINSTORM_T then -- 哥布林风暴
		total_cnt = 3
	elseif ectype_type == TOLL_GATE_PIGCHARGE_T then --猪突猛进
		total_cnt = tpgamedata.Festival_Battle_bucket
	elseif ectype_type == TOLL_GATE_TITAN_T then -- 泰坦来袭
		total_cnt = 3
	elseif ectype_type == TOLL_GATE_RANK_OILDRUM_T then --油桶阵
		total_cnt = tpgamedata.Festival_Battle_boar
	elseif ectype_type == TOLL_GATE_RANK_DEADPASS_T then --死亡穿越
		total_cnt = 3
	elseif ectype_type == TOLL_GATE_RANK_OXHEADONRUSH_T then --牛头向前冲
		total_cnt = 3
	end
end

function activity.get_activity_unrank(act,toll_gate_type)
	for i = 1,#act.activity_unrank do
		local unrank = act.activity_unrank[i]
		if unrank.ectype_type == toll_gate_type then
			return unrank
		end
	end
end

function activity.get_activity_rank(act,toll_gate_type)
	for i = 1,#act.activity_rank do
		local rank = act.activity_rank[i]
		if rank.ectype_type == toll_gate_type then
			return rank
		end
	end
end

function activity.check_activity_ectype_cnt(ur,v)
	local act = ur.activity
	local flag = 0
	local total_cnt = get_total_count(v.toll_gate_type)
	if v.toll_gate_type < TOLL_GATE_RANK_OILDRUM_T then
		local unrank = activity.get_activity_unrank(act,v.toll_gate_type)
		if unrank then
			if unrank.ectype_cnt < total_cnt then
				flag = 3 --can enter
			else
				flag = 2 --not enter
			end
		end
	else
		local rank = activity.get_activity_rank(act,v.toll_gate_type)
		if rank then
			if rank.ectype_cnt < total_cnt then
				flag = 3 --can enter
			else
				flag = 2 --not enter
			end
		end
	end
end

function activity.deal_with_activity_ectype(ur,v)
	local act = ur.activity
	local flag = false
	if v.toll_gate_type < TOLL_GATE_RANK_OILDRUM_T then
		local unrank = activity.get_activity_unrank(act,v.toll_gate_type)
		if unrank then
			unrank.difficulty = v.difficulty
		else
			local unrank_data = activity_ectype_unrank_gen()
			unrank_data.difficulty = v.difficulty
			unrank_data.ectype_type = v.toll_gate_type
			act.activity_unrank[act.activity_unrank + 1] = unrank_data
		end
	else
		local rank = activity.get_activity_rank(act,v.toll_gate_type)
		if not rank then
			local rank_data = activity_ectype_rank_gen()
			rank_data.ectype_type = v.toll_gate_type
			act.activity_rank[#act.activity_rank + 1] = rank_data
			--act.activity_rank[v.toll_gate_type] = rank_data
		end
	end
	 ur:db_tagdirty(ur.DB_ACTIVITY)
end

function activity.balance_wood_barrel_score(monster_list)
	local total_cnt = 0
	for i = 1,#monster_list do
		local monster = monster_list[i]
		local tp = tpfestival_battle_boar[monster.monster_id]
		total_cnt = total_cnt + tp.Point * monster.kill_cnt
	end
	return total_cnt
end

return activity
