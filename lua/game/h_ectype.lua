local shaco = require "shaco"
local pb = require "protobuf"
local tbl = require "tbl"
local sfmt = string.format
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local floor = math.floor
local ectype = require "ectype"
local ectype_fast = require "ectype_fast"
local task = require "task"
local tpscene = require "__tpscene"
local itemdrop = require "itemdrop"
local itemop = require "itemop"
local mystery = require "mystery"
local tpgamedata = require "__tpgamedata"
local mail = require "mail"
local tpvip = require "__tpvip"
local tpfestival_honorrank = require "__tpfestival_honorrank"
--local tpitem = require "__tpitem"
local REQ = {}


local function compute_ectype_result(ur,ectypeid)
	local tp = tpscene[ectypeid]
	if not tp then
		return
	end
	ur:addexp(tp.exp)
	--ur:sync_role_data()
end

local function get_drop_item(ur,ectypeid)
	local tp = tpscene[ectypeid]
	if not tp then
		return 
	end
	local idnums = {}
	for j= 1,#ur.info.drops do
		local drop = ur.info.drops[j]
		idnums[#idnums + 1] = {drop.itemid,drop.cnt}
	end
	if itemop.can_gain(ur, idnums) then
	else
		return 
	end
	for i =1,#idnums do
		itemop.gain(ur,idnums[i][1],idnums[i][2],tp.DropGemMax,tp.DropWashMax)
	end
	ur:coin_got(tp.gold_drop)
	ur.info.drops = {}
	itemop.refresh(ur)
	ur:sync_role_data()
	ur:db_tagdirty(ur.DB_ITEM)
	ur:db_tagdirty(ur.DB_ROLE)
end

local function kill_monster_count(ur,tp,kill_cnt)
	if tp.quantity < kill_cnt then
		kill_cnt = tp.quantity
	end
	task.change_task_progress(ur,50,1,kill_cnt)
	task.refresh_toclient(ur, 50)
end

local function get_honorrank_reward(ur,_type)
	local tp = tpfestival_honorrank[_type]
	if tp then
		local items = tp.Items
		local cnt = items[3]
		if items[1] == 0 then -- money
			if items[2] == 0 then --coin
				ur:coin_got(cnt)
			else
				ur:gold_got(cnt)
			end
		else
			itemop.gain(ur,items[2],cnt,0,0)
			ur:db_tagdirty(ur.DB_ITEM)
		end
	end
end

REQ[IDUM_PASSECTYPE] = function(ur, v)
	local ectypeid = v.ectypeid
	local pass_star = 0
	if v.user_hp < (tpgamedata.Appraisal2//100) then
		pass_star = 1
	elseif v.user_hp >= (tpgamedata.Appraisal2//100) and v.user_hp < (tpgamedata.Appraisal3//100) then
		pass_star = 2
	elseif v.user_hp >= (tpgamedata.Appraisal3//100) then
		pass_star = 3
	end
	ectype.save_ectype(ur,ectypeid,pass_star)
    local flag,state = ectype_fast.try_replace(ectypeid, ur, v.pass_time, pass_star)
    local recordv = ectype_fast.query(ectypeid)
	recordv.star = pass_star
   
	compute_ectype_result(ur,ectypeid)
	task.change_task_progress(ur,42,1,1)
	task.refresh_toclient(ur, 42)
	task.set_task_progress(ur,1,ectypeid,0)
	task.refresh_toclient(ur, 1)
	if pass_star == 3 then
		task.set_task_progress(ur,2,ectypeid,0)
		task.refresh_toclient(ur, 2)
	end
    ectype_fast.db_flush()
	local tp = tpscene[ectypeid]
	if not tp then
		return SERR_ERROR_LABEL
	end
	if tp.physicalNeed > 0 then
		ur.info.physical = ur.info.physical - tp.physicalNeed + 1
	end
	if tp.mystery_shop > 0 then
		mystery.random_mystery_shop(ur,tp.mystery_shop)
	end
	if not ur.battle_verify then
		ur:x_log_role_cheat(ectypeid,0,0,0)
	end
	local  new_record = 0
	if flag then
		new_record = state
		get_honorrank_reward(ur,state)
		--local conn2user = userpool.get_conn2user()
	--	for _, ur in pairs(conn2user) do
		--	ur:send(IDUM_NEWNOTICEBROADCAST,{content = str})
		--end
	end
	ur:db_tagdirty(ur.DB_ROLE)
	ur:sync_role_data()
	kill_monster_count(ur,tp,v.kill_cnt)
	get_drop_item(ur,ectypeid)
	ur:send(IDUM_COPYRECORD, {record = recordv,new_record = new_record})
end

REQ[IDUM_PASSECTYPEFAIL] = function(ur, v)
	ectype.save_ectype(ur,v.ectypeid,0)
end

REQ[IDUM_GETTURNCARDREWARD] = function(ur, v)
	--ur:get_turn_card_reward(v.turn_type)
	local tp = tpscene[v.ectype_id]
	if not tp then
		return SERR_ERROR_LABEL_SECENE
	end
	if v.turn_type == GOLD_TURN then
		if ur.info.vip then
			local tp_vip = tpvip[ur.info.vip.vip_level + 1]
			if tp_vip then
				if tp_vip.turn_card < 1 then
					return SERR_VIP_LEVEL_NOT_ENOUGH
				end
			else
				return SERR_ERROR_LABEL_VIP
			end
		else
			return SERR_VIP_LEVEL_NOT_ENOUGH
		end
	end
	local itemid = 0
	for i = 1,#ur.info.turn_card do
		local turn = ur.info.turn_card[i]
		if turn.type == v.turn_type then
			itemid = turn.itemid
			local idnums = {{itemid,turn.cnt}}
			if itemop.can_gain(ur, idnums) then
				itemop.gain(ur,itemid , turn.cnt,tp.DropGemMax,tp.DropWashMax)
			else
				return SERR_PACKAGE_SPACE_NOT_ENOUGH
			end
			break
		end
	end
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
	ur:send(IDUM_GETTURNCARDRESULT, {itemid = itemid})
end

REQ[IDUM_REQSWEEPECTYPE] = function(ur, v)
	local physical = ur.info.physical
	local ectype_id = v.ectype_id
	--tbl.print(v)
	local tp = tpscene[ectype_id]
	if not tp then
		return SERR_ERROR_LABEL
	end
	--tbl.print(v)
	local star = ectype.get_ectype_star(ur,ectype_id)
	if star < 3 then
		return SERR_ECTYPE_STAR_NOT_ENOUGH
	end
	if physical < tp.physicalNeed then
		return SERR_PYSICAL_NOT_ENOUGH
	end
	local itemid = 70000005
	local flag = false
	local drop_items = {}
	local drop_money = tp.gold_drop
	local drop_exp = tp.exp
	local cnt = 0
	local drop_info = {}
	if v.sweep_type == SINGLE_T then
		--local drop_list = itemdrop.random_ectype_drop(ectype_id,1)
		--drop_items[#drop_items + 1] = drop_list
		cnt = 1
	elseif v.sweep_type == REPEATEDLY_T then
		cnt = physical//tp.physicalNeed
		if cnt > 10 then
			cnt = 10
		end
	end
	local sweep_ticket = itemop.count(ur, itemid)
	if sweep_ticket == 0 then
		if cnt == 0 then
			cnt = 10
		end
	   local gold = ur.info.gold 
       local gold_cnt,temp = math.modf(gold/tpgamedata.Raidsprice)
       if gold_cnt < cnt then
            cnt = gold_cnt
       end
	   --print("出纳台=== cnt === "..cnt.."  gold_cnt === "..gold_cnt)
       if cnt == 0 then
           return SERR_GOLD_NOT_ENOUGH
       end
       local total_gold = cnt * tpgamedata.Raidsprice
       ur:gold_take(total_gold)
        --	return SERR_SWEEP_TICKET_NOT_ENOUGH
    else
		if sweep_ticket < cnt then
			cnt = sweep_ticket
		end
	    itemop.take(ur, itemid, cnt)
    end
	local mystery_flag = false
	for i= 1,cnt do
		if (not mystery_flag) and tp.mystery_shop > 0 then
			mystery_flag = mystery.random_mystery_shop(ur,tp.mystery_shop)
		end
		local drop_list = itemdrop.random_ectype_drop(ectype_id,1)
		local function get_sweep_drop_gen()
			return {
				drop_list = {}
			}
		end
		local sweep_drop = get_sweep_drop_gen()
		sweep_drop.drop_list = drop_list
		drop_items[#drop_items + 1] = drop_list
		drop_info[#drop_info + 1]= sweep_drop
	end
	drop_money = drop_money * cnt
	drop_exp = drop_exp * cnt
	physical = physical - tp.physicalNeed * cnt
	
	task.change_task_progress(ur,42,1,cnt)
	task.refresh_toclient(ur, 42)
	ur.info.physical = physical
	ur:coin_got(drop_money)
	ur:addexp(drop_exp)
	local idnums = {}
	local test_idnums = {}
	for i = 1,#drop_items do
		local drops = drop_items[i]
		for j =1,#drops do
			local info = drops[j]
			idnums[#idnums + 1] = {info.itemid,info.cnt}
		end
	end
	local mail_items ={}	
	for i =1,#idnums do
		local items = idnums[i]
		local idnum = {}
		idnum[#idnum + 1] = {items[1],items[2]}
		--if itemop.can_gain(ur, idnum) then
			itemop.gain(ur,idnums[i][1] , idnums[i][2],tp.DropGemMax,tp.DropWashMax)
	--	else
		--	mail_items[#mail_items + 1] = {items[1],items[2]}
	--	end
	end
	itemop.refresh(ur)
	ur:sync_role_data()
	ur:db_tagdirty(ur.DB_ITEM)
	ur:db_tagdirty(ur.DB_ROLE)
	ur:send(IDUM_ACKSWEEPECTYPE, {drop_info = drop_info,coin = drop_money})
end

return REQ
