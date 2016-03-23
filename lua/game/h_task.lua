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
local gift_reward = require "gift_reward"

local REQ = {}

local function reward_gen()
    return {
        itemid = 0,
		itemcnt = 0,
		hole_cnt = 0,
		wash_cnt = 0,
    }
end

local function can_get_reward(ur,id)
	local tasks = ur.task.tasks
	local taskv = {}
	if not tasks then
		return false
	end
	for i = 1,#tasks do
		if tasks[i].taskid == id and tasks[i].finish == 1 then
			return true
		end
	end
	return false
end

local function delete_oldly(ur,id)
	local tasks = ur.task.tasks
	local taskv = {}
	if not tasks then
		return false
	end
    local i = 1
    while tasks[i] do
        if tasks[i].previd == id then
            tasks[i].previd = 0
        end
        if tasks[i].taskid == id then
            table.remove(tasks,i)
        else
            i = i + 1
        end

    end
	ur:db_tagdirty(ur.DB_TASK)
	ur:send(IDUM_TASKREWARD, {taskid = id,info = tasks})
	--ur:send(IDUM_TASKLIST, {info = taskv})
	return true
end

local function get_vip_task_reward(ur,taskid)
	--ur.info.vip.vip_level
	local itemcnt = ur:get_vip_value(VIP_MOPUP_TICKET_T)
	itemop.gain(ur,70000005,itemcnt)
	itemop.refresh(ur)
	delete_oldly(ur,taskid)
	ur:db_tagdirty(ur.DB_ITEM)
	ur:db_tagdirty(ur.DB_TASK)
end

REQ[IDUM_GETREWARD] = function(ur, v)
	local update = 0
    local tasks = {}
    local taskid = v.taskid
    local rewardlist = {}
    local reward_list = {}
	local reward_data = {}
    local tp = tptask[v.taskid]
	if not tp then
		shaco.warn("the ask not exsit") 
		return 
	end
	if not can_get_reward(ur,v.taskid) then
		return
	end
	if v.taskid == 30063000 then
		get_vip_task_reward(ur,v.taskid)
		return
	end
	local rewardarray = tp.submitItems
	for j = 1,#rewardarray do
		local templist = reward_gen()
		local id = 0
		id = tonumber(rewardarray[j][1])
    	local num = 0
    	num = tonumber(rewardarray[j][2])
    	templist.itemid = id
    	templist.itemcnt = num
		templist.hole_cnt = tonumber(rewardarray[j][3])
		templist.wash_cnt = tonumber(rewardarray[j][4])
		local race = tonumber(rewardarray[j][5])
		local flag = false
		if race > 0 then
			if ur.base.race == race then
				flag = true
			end
		else
			flag = true
		end
		if flag then
			reward_list[#reward_list + 1] = templist
			rewardlist[#rewardlist + 1] = {id,num}
		end
	end
	
	if itemop.can_gain(ur, rewardlist) then
		for i = 1, #reward_list do
			local item = reward_list[i]
			local item_tp = tpitem[item.itemid]
			if item_tp then
				--print("item_tp.itemType ==== "..item_tp.itemType)
				if  item_tp.itemType == ITEM_BAG and item_tp.items[1][3] == 1 then
					--print(" item.itemid === "..item.itemid.."  item.itemcnt == "..item.itemcnt)
					--tbl.print(item_tp.items,"------- item_tp.items ==== ")
					gift_reward.get_gift_reward(ur,item_tp.items,item.itemcnt,1,item.hole_cnt,item.wash_cnt)
					--gift_reward.open_gift_item(ur,item.itemid,item.itemcnt,item.hole_cnt,item.wash_cnt)
				else
					itemop.gain(ur, item.itemid, item.itemcnt,item.hole_cnt,item.wash_cnt)
				end
			end
		end
	end
	local cardreward = tp.submitCards
	local cards = ur.cards
	for j = 1,#cardreward do
		local templist = reward_gen()
		local id = 0
		id = tonumber(cardreward[j][1])
    	local num = 0
    	num = tonumber(cardreward[j][2])
		if not card_container.enough(ur,num) then
			break
		end
		cards:put(ur,id,num)
	end
	if tp.submitPhysical > 0 then
		ur.info.physical = ur.info.physical + tp.submitPhysical
	end
	local submitArms = tp.submitArms
	for i = 1,#submitArms do
		local reward_weapon = submitArms[i]
		local cardid = reward_weapon[1]
		local weapon_id = reward_weapon[2]
		local hole_cnt = reward_weapon[3]
		card_container.add_equip(ur,cardid,weapon_id,hole_cnt)
	end
	card_container.refresh(ur)
    ur:db_tagdirty(ur.DB_CARD)
	ur:addexp(tptask[taskid].submitExp)
	ur:gold_got(tptask[taskid].submitDiamond)
	ur:coin_got(tptask[taskid].submitGold)
	ur:sync_role_data()
	itemop.refresh(ur)
	if delete_oldly(ur,v.taskid) then
    	--ur:send(IDUM_TASKREWARD, {taskid = taskid})
    end
    ur:db_tagdirty(ur.DB_ITEM)
    ur:db_tagdirty(ur.DB_TASK)
	
	--[[if tp.type ~= DAILY_TASK then
		local task_array = get_next_task(taskid,ur.base.race)
		for i =1,#task_array do
			local tempv = {taskid = task_array[i]}
			REQ[IDUM_ACCEPTTASK](ur, tempv)
		end
	end]]
end

local function get_card_max_level(ur)
	local cards = ur.cards.__card.__cards
	local max_level =  0
    for i =1, #cards do
    	local card = cards[i] 
		if card.level > max_level then
			max_level = card.level
		end
    end
	return max_level
end

local function get_card_max_break_through(ur)
	local cards = ur.cards.__card.__cards
	local max_num =  0
    for i =1, #cards do
    	local card = cards[i] 
		if card.break_through_num > max_num then
			max_num = card.break_through_num
		end
    end
	return max_num
end

local function get_refine_cnt(itemid)
	local indx = 0
	for k,v in pairs(tpgodcast) do
		if v.equipID == itemid then
			for i =1,10 do
				if #v["star"..i] > 0 then
					indx = indx + 1
				end
			end
		end
	end
	return indx
end

local function get_weapon_godcast_num(ur)
	local max_star = 0
	local cards = ur.cards.__card.__cards
	for i =1, #cards do
    	local card = cards[i] 
		local bag = card.equip
		if bag then
			local item = itemop.get(bag, EQUIP_WEAPON)
			if item then
				local star = get_refine_cnt(item.tpltid)
				if star > max_star then
					max_star = star
				end
			end
		end
	end
	local bag = ur:getbag(BAG_EQUIP)
	if bag then
		local item = itemop.get(bag,EQUIP_WEAPON)
		if item then
			local star = get_refine_cnt(item.tpltid)
			if star > max_star then
				max_star = star - item.info.refinecnt
			end
		end
	end
	return max_star
end

local function get_weapon_quality(ur)
	local quality = 0
	local cards = ur.cards.__card.__cards
	for i =1, #cards do
    	local card = cards[i] 
		local bag = card.equip
		if bag then
			local item = itemop.get(bag, EQUIP_WEAPON)
			if item then
				local tp_item = tpitem[item.tpltid]
				if tp_item.quality > quality then
					quality = tp_item.quality
				end
			end
		end
	end
	local bag = ur:getbag(BAG_EQUIP)
	if bag then
		local item = itemop.get(bag,EQUIP_WEAPON)
		if item then
			local tp_item = tpitem[item.tpltid]
			if tp_item.quality > quality then
				quality = tp_item.quality
			end
		end
	end
	return quality
end

local function get_skill_level(ur)
	local max_level = 0
	local skill = ur.info.skills
	for i = 1,#skill do
		local tp = tpskill[skill[i].skill_id]
		if tp.level > max_level then
			max_level = tp.level
		end
		for j =1,#skill[i].gift do
			local gift_info = skill[i].gift[j]
			if gift_info.level > max_level then
				max_level = gift_info.level
			end
		end
	end
	return max_level
end

local function check_task_finish(ur,taskid)
	local flag = false
	local tp = tptask[taskid]
	local condition1 = tp.condition1
	if tp.method == 1 then
		local ectype_list = ur.info.ectype
		for i = 1,#ectype_list do
			if ectype_list[i].ectypeid == condition1 then
				flag = true 
			end
		end
	--elseif tp.method == 3 then
	--	local level = ur.base.level 
	--	if level >= condition1 then
	--		flag = true
	--	end
	elseif tp.method == 4 then
		local own_cards = ur.cards.__own_cards
		if #own_cards >= condition1 then
			flag = true
		end
	elseif tp.method == 5 then
		local bag = ur:getbag(BAG_EQUIP)
		if bag then
			local item = itemop.get(bag,EQUIP_WEAPON)
			if item then
				if item.info.level >= condition1 then
					flag = true
				end
			end
		end
	elseif tp.method == 22 then
		local max_num = get_card_max_break_through(ur)
		if max_num >= condition1 then
			flag = true
		end
	elseif tp.method == 24 then
		local quality = get_weapon_quality(ur)
		if quality >= condition1 then
			flag = true
		end
	elseif tp.method == 25 then
		if ur.battle_value >= condition1 then
			flag = true
		end
	elseif tp.method == 27 then
		local level = get_card_max_level(ur)
		if level >= condition1 then
			flag = true
		end
	elseif tp.method == 47 then
		local max_level = get_skill_level(ur)
		if max_level >= condition1 then
			flag = true
		end
	elseif tp.method == 53 then
		local max_star = get_weapon_godcast_num(ur)
		if max_star >= condition1 then
			flag = true
		end
	end
	
	return flag
end

REQ[IDUM_ACCEPTTASK] = function(ur, v)
    local update = 0
    local taskv = {}
    update,taskv = task.accept(ur,v.taskid)
    if update ~= 1 then
    	return update
    end 
	local flag = check_task_finish(ur,v.taskid)
	if flag == true then
		task.finish(ur,v.taskid)
		ur:send(IDUM_SYNCTASKLIST, {info = ur.task.tasks})
	else
		ur:send(IDUM_UPDATETASK, {taskid = taskv.taskid})
	end
    ur:db_tagdirty(ur.DB_TASK)
end

REQ[IDUM_TASKCHECK] = function(ur, v)
	--refresh_toclient(ur, 1,v.ectypeid,1)
	--task.pass_ectype(ur,v.ectypeid)
	--ur:db_tagdirty(ur.DB_ROLE)
end

return REQ
