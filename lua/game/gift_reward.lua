local shaco = require "shaco"
local itemop = require "itemop"
local tpitem = require "__tpitem"
local tbl = require "tbl"
local tpgamedata = require "__tpgamedata"
local tpgift_treasure = require "__tpgift_treasure"
local card_container = require "card_container"
local club = require "club"
local sfmt = string.format
local gift_reward = {}

local function get_gift_arrary(reward_arrary,tp_content)
	local temp_arrary = {}
	for i = 1,#tp_content do
		local flag = false
		local tp = tp_content[i]
		--[[for j = 1,#reward_arrary do
			local info = reward_arrary[j]
			if tp.item_id == info.item_id then
				flag = true
				break
			end
		end]]
		if not flag then
			temp_arrary[#temp_arrary + 1] = tp
		end
	end
	return temp_arrary
end

local function get_total_weigh(reward_arrary)
	local weigh = 0
	for i = 1,#reward_arrary do
		local tp = reward_arrary[i]
		weigh = weigh + tp.weighing
	end
	return weigh
end

local function gift_gen()
	return {
		item_id = 0,
		count = 0,
		item_type = 0,
	}
end

local function __gift_reward(ur,tp_content,send_flag,hole_cnt,wash_cnt)
	local idnum = {}
	local cardnum = {}
	local card_total_num = 0
	local card_fragment_num = {} 
	local coin = 0
	local gold = 0
	local reward_arrary = {}
	for i = 1,#tp_content do
		local info = tp_content[i]
		if not info then
			return 0
		end
		local gift_info = gift_gen()
		gift_info.item_id = info.item_id
		gift_info.count = info.count
		gift_info.item_type = info.type
		reward_arrary[#reward_arrary + 1] = gift_info
		if info.type == 1 or info.type == 3 then
			idnum[#idnum + 1] = {info.item_id,info.count}
			
		elseif info.type == 2 then
			cardnum[#cardnum + 1] = {info.item_id,info.count}
			card_total_num = card_total_num + info.count
		--elseif info.type == 3 then
		--	card_fragment_num[#card_fragment_num + 1] = {info.item_id,info.count}
		elseif info.type == 4 then
			coin = info.count
			ur:coin_got(coin)
			ur:db_tagdirty(ur.DB_ROLE)
			ur:sync_role_data()
		elseif info.type == 5 then
			gold = info.count
			ur:gold_got(gold)
			ur:db_tagdirty(ur.DB_ROLE)
			ur:sync_role_data()
		end
	end
	--tbl.print(idnum, "=============init idnum", shaco.trace)
	if itemop.can_gain(ur, idnum) then
		for i =1,#idnum do
			itemop.gain(ur,idnum[i][1] , idnum[i][2],hole_cnt,wash_cnt)
		end
		itemop.refresh(ur)
		ur:db_tagdirty(ur.DB_ITEM)
	else
		
		return 1
	end
	if card_container.enough(ur,card_total_num) then
		local cards = ur.cards
		for i =1,#cardnum do
			cards:put(ur,cardnum[i][1],cardnum[i][2])
		end
		card_container.refresh(ur)
        ur:db_tagdirty(ur.DB_CARD)
	else
		return 2
	end
	--for i = 1,#card_fragment_num do
	--	club.add_fragment(ur,card_fragment_num[i][1],card_fragment_num[i][2])	
	--	ur:send(IDUM_NOTICEADDFRAGMENT, {fragmentid =card_fragment_num[i][1],fragment_cnt = card_fragment_num[i][2]})
	--end
	if send_flag == 1 then
		--tbl.print(reward_arrary,"--------------------------------------- reward_arrary ==== ")
		ur:send(IDUM_NOTICEITEMGIFT, {gift_data = reward_arrary})
	end
end

local function check_gift_arrary(reward_arrary,item_id)
    for i = 1,#reward_arrary do
        local info =reward_arrary[i]
        if info.item_id == item_id then
            return true
        end
    end
    return false
end

local function integration_reward_gen(v)
	return {
		item_id = v.item_id,
		count = v.count,
		type = v.type,
	}
end

local function integration_reward(gift_arrary)
	local reward_arrary = {}
	for k,v in pairs(gift_arrary) do
		local flag = false
		for i = 1 ,#reward_arrary do
			local reward = reward_arrary[i]
			if reward.item_id == v.item_id then
				reward.count = reward.count + v.count
				flag = true
			end
		end
		if not flag then
			local info = integration_reward_gen(v)
			reward_arrary[#reward_arrary + 1] = info
		end
	end
	return reward_arrary
end

local function resolve_gift_reward(ur,id,num,item_cnt,hole_cnt,wash_cnt)
	local tp_content = tpgift_treasure[id]
	if not tp_content then
		return 0
	end
	local tp = tp_content[1]
    local gift_arrary = {}
	if tp.weighing == 0 then
       -- for i = 1,item_cnt do
            for j = 1,#tp_content do
                gift_arrary[#gift_arrary + 1] = tp_content[j]
            end
       -- end
	elseif tp.weighing > 0 then
		local temp_arrary = {}
		local reward_arrary = get_gift_arrary(temp_arrary,tp_content)
        for k = 1,item_cnt do    
		    for i = 1,num do
                local total_weigh = get_total_weigh(reward_arrary)
                if not total_weigh  then
                    return
                end
			    local random_weigh = math.random(1,total_weigh)
			    local temp_weigh = 0
			    for j = 1,#reward_arrary do
				    local info = reward_arrary[j]
				    temp_weigh = temp_weigh + info.weighing
				    if temp_weigh >= random_weigh then
                        temp_arrary[#temp_arrary + 1] = info
                        gift_arrary[#gift_arrary + 1] = info
					    break
				    end
			    end
            end
         end
	end
	local integration_arrary = integration_reward(gift_arrary)
	--tbl.print(integration_arrary," integration_arrary ====== ")
	return __gift_reward(ur,integration_arrary,hole_cnt,wash_cnt)
end

function gift_reward.get_gift_reward(ur,items,item_cnt,send_flag,hole_cnt,wash_cnt)
    local id = items[1][1]
    local num = items[1][2]
	local tp_content = tpgift_treasure[id]
	if not tp_content then
		return 0
	end
	local tp = tp_content[1]
    local gift_arrary = {}
	if tp.weighing == 0 then
        for i = 1,item_cnt do
            for j = 1,#tp_content do
                gift_arrary[#gift_arrary + 1] = tp_content[j]
            end
        end
	elseif tp.weighing > 0 then
		local temp_arrary = {}
		local reward_arrary = get_gift_arrary(temp_arrary,tp_content)
        for k = 1,item_cnt do    
		    for i = 1,num do
                local total_weigh = get_total_weigh(reward_arrary)
                if not total_weigh  then
                    return
                end
			    local random_weigh = math.random(1,total_weigh)
			    local temp_weigh = 0
			    for j = 1,#reward_arrary do
				    local info = reward_arrary[j]
				    temp_weigh = temp_weigh + info.weighing
				    if temp_weigh >= random_weigh then
                        temp_arrary[#temp_arrary + 1] = info
                        gift_arrary[#gift_arrary + 1] = info
					    break
				    end
			    end
            end
         end
	end
	--tbl.print(gift_arrary," ------ gift_arrary ====== ")
	local integration_arrary = integration_reward(gift_arrary)
	--tbl.print(integration_arrary," integration_arrary ====== ")
	return __gift_reward(ur,integration_arrary,send_flag,hole_cnt,wash_cnt)
	--resolve_gift_reward(ur,id,num,hole_cnt,wash_cnt)
end

function gift_reward.open_gift_item(ur,itemid,itemcnt,hole_cnt,wash_cnt)
	resolve_gift_reward(ur,itemid,itemcnt,hole_cnt,wash_cnt)
end

return gift_reward
