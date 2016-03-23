local shaco = require "shaco"
local tostring = tostring
local sfmt = string.format
local mystery = require "mystery"
local tbl = require "tbl"
local floor = math.floor
local tpmystery_shop = require "__tpmystery_shop"
local tppayprice = require "__tppayprice"
local itemop = require "itemop"
local club = require "club"
local card_container = require "card_container"
local tpvip = require "__tpvip"
local pairs = pairs
local REQ = {}



REQ[IDUM_REQBUYMYSTERYITEM] = function(ur, v)
	local mystery_info
	if v.shop_type == MYSTERY_REF_T then
		mystery_info = ur.info.mystery
	elseif v.shop_type == NORMAL_REF_T then
		mystery_info = ur.info.normal
	end
	if not mystery_info then
		return 
	end
	if v.shop_type == MYSTERY_REF_T then
		local cur_time = shaco.now()//1000
		if cur_time - mystery_info.start_time > (500 + ur:get_vip_value(VIP_MYSTERY_T)) then
			return SERR_MYSTERY_SHOP_TIME_OVER
		end
	end
	local flag = false
	local mystery_id = 0
	local mystery_item_id = 0
	local money_type = 0
	local take = 0
	local hole_cnt = 0
	local wash_cnt = 0
	local item_type = 0
	for i=1,#mystery_info.info do
		local info =  mystery_info.info[i]
		if info.itemid == v.itemid and info.pos == v.pos and info.falg == 0 and info.itemcnt == v.cnt then
			flag = true
			mystery_id = info.mystery_id 
			mystery_item_id = info.mystery_item_id
			money_type = info.money_type
			take = info.money
			hole_cnt = info.hole_cnt
			wash_cnt = info.wash_cnt
			item_type = info.item_type
			break
		end
	end
	if flag == false then
		return SERR_MYSTERY_SHOP_ITEM_NOT_EXSIT
	end
	if money_type == 0 then
		if ur:coin_take(take) == false then
			return SERR_COIN_NOT_ENOUGH
		end 
	elseif money_type == 1 then
		if ur:gold_take(take) == false then
			return SERR_GOLD_NOT_ENOUGH
		end
	end 	
	local pos = 0
	local itemid = 0
	local itemcnt = 0
	for i=1,#mystery_info.info do
		local info =  mystery_info.info[i]
		if info.itemid == v.itemid and info.itemcnt == v.cnt and info.pos == v.pos then
			pos = info.pos
			info.falg = 1
			itemid = info.itemid
			itemcnt = info.itemcnt
			info.itemcnt = 0
			break
		end
	end
	if item_type == SHOP_PROP_T or item_type == SHOP_CARD_FRAMENT_T then
		itemop.gain(ur, itemid, itemcnt,hole_cnt,wash_cnt)
		itemop.refresh(ur)
		ur:db_tagdirty(ur.DB_ITEM)
	elseif item_type == SHOP_CARD_T then
		local cards = ur.cards
		if not card_container.enough(ur,itemcnt) then
			return SERR_CARD_BAG_SIZE_NOT_ENOUGH
		end
		cards:put(ur,itemid,itemcnt)
		card_container.refresh(ur)
		ur:db_tagdirty(ur.DB_CARD)
	elseif item_type == SHOP_CARD_FRAMENT_T then
		--itemop.gain(ur, itemid, itemcnt,hole_cnt,wash_cnt)
		--itemop.refresh(ur)
		--ur:db_tagdirty(ur.DB_ITEM)
		--club.add_fragment(ur,itemid,itemcnt)	
		--ur:send(IDUM_NOTICEADDFRAGMENT, {fragmentid =itemid,fragment_cnt = itemcnt})
	elseif item_type == SHOP_COIN_T then
		ur:coin_got(itemcnt)
	elseif item_type == SHOP_GOLD_T then
		ur:gold_got(itemcnt)
	end
	ur:sync_role_data()
	ur:db_tagdirty(ur.DB_ROLE)
	ur:send(IDUM_ACKBUYMYSTERYRESULT,{itemid = v.itemid,cnt = v.cnt,pos = v.pos})
end

REQ[IDUM_REQREFRESHMYSTERY] = function(ur, v)
	local cnt = 0
	if v.shop_type == MYSTERY_REF_T then
		cnt = ur.info.mystery.refresh_cnt + 1
	elseif v.shop_type == NORMAL_REF_T then
		if ur.info.normal.refresh_cnt >= ur:get_vip_value(VIP_NORMAL_T) then
			return SERR_REFRESH_COUNT_MAX
		end
		cnt = ur.info.normal.refresh_cnt + 1
	end
	local take = 0 
	local money_tpye = 0
	for k, u in pairs(tppayprice) do
		if u.type == v.shop_type and cnt >= u.start and cnt <= u.stop then
			take = u.number
			money_tpye = u.money_tpye
		end
	end
	if money_tpye == 0 then
		if ur:gold_take(take) == false then
			return SERR_GOLD_NOT_ENOUGH
		end
		mystery.refresh_mystery_shop(ur,v.shop_type)
		ur:db_tagdirty(ur.DB_ROLE)
		ur:sync_role_data()
	end
end

return REQ
