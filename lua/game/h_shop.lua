--local shaco = require "shaco"
local shaco = require "shaco"
local pb = require "protobuf"
local tbl = require "tbl"
local sfmt = string.format
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local tpcardrandom = require "__tpcardrandom"
local tpcardwarehouse = require "__tpcardwarehouse"
local tpcard = require "__tpcard"
local tpgamedata = require "__tpgamedata"
local tpvip = require "__tpvip"
local card_container = require "card_container"
local task = require "task"
local club = require "club"
local broad_cast = require "broad_cast"
local itemop = require "itemop"

local REQ = {}
local function random_cards(tp)
	local totalvalue = 0
	for i = 1,10 do
		totalvalue = totalvalue + tp["CardProportion"..i]
	end
	local randvalue = math.random(1,totalvalue)
	local randomsum = 0
	for i = 1,10 do
		randomsum = randomsum + tp["CardProportion"..i]
		if randomsum >= randvalue then
			return i
		end
	end
	return 0
end

local function card_gen()
	return {
		cardid = 0,
		card_type = 0,
		num = 0,	
	}
end

local function random_card(random_list)
	local allvalue = 0
	for i=1,#random_list do
		allvalue = allvalue + random_list[i].Proportion
	end
	local rand_value = math.random(1,allvalue)
	local random_sum = 0
	for i = 1,#random_list do
		random_sum = random_sum + random_list[i].Proportion
		if random_sum >= rand_value then
			return random_list[i].CardID,random_list[i].type,random_list[i].count
		end
	end
	return 0,0,0
end

local function check_money_enough(ur,take,price_type)
	if price_type == 0 then
		if ur:coin_enough(take) == false then
			return false
		end 
	elseif price_type == 1 then
		if ur:gold_enough(take) == false then
			return false
		end
	end 	
	return true
end

local function cost_money(ur,take,price_type,buy_type)
	if price_type == 0 then
		if ur:coin_take(take) == false then
			return false
		end 
	elseif price_type == 1 then
		if ur.info.free_card_cnt == 1 and buy_type == BUY_SINGLE then
			ur.info.free_card_cnt = 0
			ur.info.free_card_time = shaco.now()//1000
			ur:send(IDUM_FREEEXTRACTCARD, {free_card_time = ur.info.free_card_time})
		else
			if ur:gold_take(take) == false then
				return false
			end
		end
	end 	
	return true
end

local function check_random_card(array,quality,compensation_random)
	local flag = 0
	for i = 1, #array do
		if array[i].card_type == 1 then
			local tp = tpcard[array[i].cardid]
			if not tp then
				return false
			end
			if tp.quality >= quality and tp.quality < 10 then
				flag = 1
				break 
			end
		end
	end
	if flag == 0 then
		local random_list = {}
		for i = 1,#tpcardwarehouse do
			if tpcardwarehouse[i].ID == compensation_random then
				random_list[#random_list + 1] = tpcardwarehouse[i]
			end
		end
		local cardid,card_type,num = random_card(random_list)
		if cardid == 0 then
			return false
		end
		local rand_value = math.random(#array)
		if rand_value == 0 then
			rand_value = 1
		end
		local card_info = card_gen()
		card_info.cardid = cardid
		card_info.card_type = card_type
		card_info.num = num
		array[rand_value] = card_info
	end
	return true
end

REQ[IDUM_SHOPBUYITEM] = function(ur, v)
	local open_bit = ur.info.open_bit
	if (open_bit >> FUNC_BUY_CARD) & 1 == 0 then
		return SERR_FUNCTION_NOT_OPEN
	end
	local count = 0
	if v.buy_type == BUY_SINGLE then
		count = 1
	elseif v.buy_type == BUY_TEN then
		count = 10
	end
	if not card_container.enough(ur,count) then
		return SERR_CARD_GRID_NOT_ENOUGH
	end
	local tp = tpcardrandom[v.random_id]
	if not tp then
		return SERR_ERROR_LABEL
	end
	local indx = random_cards(tp)
	if indx == 0 then
		return SERR_ERROR_LABEL1
	end
	local random_list = {}
	for i = 1,#tpcardwarehouse do
		if tpcardwarehouse[i].ID == tp["CardStar"..indx] then
			random_list[#random_list + 1] = tpcardwarehouse[i]
		end
	end
	if v.buy_type == BUY_SINGLE then
		if cost_money(ur,tp.UnitPrice,tp.PriceType,BUY_SINGLE) == false then
			if tp.PriceType == 0 then
				return SERR_COIN_NOT_ENOUGH
			elseif tp.PriceType == 1 then
				return SERR_GOLD_NOT_ENOUGH
			end
		end
	elseif v.buy_type == BUY_TEN then
		if cost_money(ur,tp.TenPrice,tp.PriceType,BUY_TEN) == false then
			if tp.PriceType == 0 then
				return SERR_COIN_NOT_ENOUGH
			elseif tp.PriceType == 1 then
				return SERR_GOLD_NOT_ENOUGH
			end
		end
	end
	local card_array = {}
	if v.buy_type == BUY_SINGLE then
		local cardid,card_type,num = random_card(random_list)
		if cardid == 0 then
			return SERR_ERROR_LABEL2
		end
		local card_info = card_gen()
		card_info.cardid = cardid
		card_info.card_type = card_type
		card_info.num = num
		card_array[#card_array + 1] = card_info
	elseif v.buy_type == BUY_TEN then
		for i = 1,10 do
			indx = random_cards(tp)
			if indx == 0 then
				return SERR_ERROR_LABEL1
			end
			random_list = {}
			for i = 1,#tpcardwarehouse do
				if tpcardwarehouse[i].ID == tp["CardStar"..indx] then
					random_list[#random_list + 1] = tpcardwarehouse[i]
				end
			end
			local cardid,card_type,num = random_card(random_list)
			if cardid == 0 then
				return SERR_ERROR_LABEL2
			end
			local card_info = card_gen()
			card_info.cardid = cardid
			card_info.card_type = card_type
			card_info.num = num
			card_array[#card_array + 1] = card_info
		end
	else
		return SERR_TYPE_ERROR
	end
	if tp.FPOpen == 1 and v.buy_type == BUY_TEN then
		if check_random_card(card_array,tp.TenType,tp.TenStart) == false then
			return SERR_ERROR_LABEL
		end
	end
	local card_ids = {}
	for i =1,#card_array do
		local cardv = card_array[i]
		if cardv.card_type == 1 then
			local tp = tpcard[cardv.cardid]
			if tp and tp.quality >= 4 and tp.quality <= 5 then
				card_ids[#card_ids + 1] = cardv.cardid
			end
			card_container.check_collect_task(ur,cardv.cardid)
			ur.cards:put(ur,cardv.cardid,1)
		elseif cardv.card_type == 2 or cardv.card_type == 3 then
			itemop.gain(ur,cardv.cardid,cardv.num)
		end
	end
	--broad_cast.check_buy_card(ur,card_array,tp.PriceType)
	if #card_ids > 0 then
		local _type = 0
		if v.random_id == 103 then
			_type = NOTICE_MYSTERY_BAG_T
		else
			if tp.PriceType == 0 then
				_type = NOTICE_COIN_CARD_T
			elseif tp.PriceType == 1 then
				_type = NOTICE_GOLD_CARD_T
			end
		end
		broad_cast.set_borad_cast(ur,card_ids,_type)
	end
	card_container.refresh(ur)
	ur:sync_role_data()
    ur:db_tagdirty(ur.DB_CARD)
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
	ur:card_log(v.buy_type,tp.PriceType,card_array)
	ur:db_tagdirty(ur.DB_ROLE)
	task.set_task_progress(ur,14,1,0)
	task.refresh_toclient(ur, 14)
	if tp.PriceType == 0 then
		task.set_task_progress(ur,58,1,0)
		task.refresh_toclient(ur, 58)
	elseif tp.PriceType == 1 then
		task.set_task_progress(ur,59,1,0)
		task.refresh_toclient(ur, 59)
	end
	ur:send(IDUM_BUYCARDSUCCESS, {cards = card_array,random_id = v.random_id})
end

local function get_upper_limit(ur)
	local vip = ur.info.vip
	local vip_lvl = 0
	if vip then
		vip_lvl = vip.vip_level
	end
	local upper_limit = 0
	for i = 1,(vip_lvl + 1) do
		local tp = tpvip[i + 1]
		if tp then
			upper_limit = upper_limit + tp.card_bag
		end
	end
	upper_limit = upper_limit + tpgamedata.CardBackpack
	return upper_limit
end

REQ[IDUM_BUYCARDSIZE] = function(ur, v)
	--local cnt = ur:get_vip_value(VIP_BUY_CARD_BAG_T)
	--if cnt == 0 then
		--return SERR_VIP_LEVEL_NOT_ENOUGH
	--end
	--local upper_limit = get_upper_limit(ur)
	local card_size = ur.info.cards_size
	local max_size = tpgamedata.CardBackpackMax
	--if card_size >= upper_limit then
	--	return SERR_VIP_LEVEL_NOT_ENOUGH
	--end
	if card_size >= max_size then
		return SERR_CARD_GRID_MAX
	end
	if not ur:gold_take(tpgamedata.CardBackpackPrice) then
		return SERR_GOLD_NOT_ENOUGH
	end
	card_size = card_size + 10
	if card_size >= max_size then
		card_size = max_size
	end
	ur.info.cards_size = card_size
	ur:sync_role_data()
	ur:db_tagdirty(ur.DB_ROLE)
	ur:send(IDUM_BUYCARDSIZERESULT,{card_grid_cnt = card_size})
end

REQ[IDUM_REQBUYVIPGIFT] = function(ur,v)
	local level = 0
	local vip = ur.info.vip
	if not vip then
		return SERR_VIP_LEVEL_NOT_ENOUGH
	end
	level = v.index
	local tp = tpvip[level + 1]
	if not tp then
		return SERR_ERROR_LABEL
	end
	if level > vip.vip_level and level < 1 then
		return SERR_VIP_LEVEL_NOT_ENOUGH
	end
	if ((vip.buy_flag >> level) & 1) == 0 then
		vip.buy_flag = vip.buy_flag + 2^level
	else
		return SERR_VIP_GIFT_ALREADY_BUY
	end
	if tp.sale > 0 then
		if not ur:gold_take(tp.sale) then
			return SERR_GOLD_NOT_ENOUGH
		end
	else
		return SERR_ERROR_LABEL
	end
	for i = 1,#tp.gift_treasure do
		local item_type = tp.gift_treasure[i][1]
		local itemid = tp.gift_treasure[i][2]
		local itemcnt = tp.gift_treasure[i][3]
		if item_type == SHOP_PROP_T or item_type == SHOP_CARD_FRAMENT_T then
			itemop.gain(ur,itemid,itemcnt)
			itemop.refresh(ur)
			ur:db_tagdirty(ur.DB_ITEM)
		elseif item_type == SHOP_CARD_T then
			local cards = ur.cards
			if not card_container.enough(ur,itemcnt) then
				return SERR_CARD_BAG_SIZE_NOT_ENOUGH
			end
			cards:put(ur,itemid,itemcnt)
		---elseif item_type == SHOP_CARD_FRAMENT_T then
			--club.add_fragment(ur,itemid,itemcnt)	
			--ur:send(IDUM_NOTICEADDFRAGMENT, {fragmentid =itemid,fragment_cnt = itemcnt})
		elseif item_type == SHOP_COIN_T then
			ur:coin_got(itemcnt)
		elseif item_type == SHOP_GOLD_T then
			ur:gold_got(itemcnt)
		end
	end
	ur:sync_role_data()
	ur:db_tagdirty(ur.DB_ROLE)
	ur:send(IDUM_ACKBUYVIPGIFT,{result = 1})
end

return REQ