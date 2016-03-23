local shaco = require "shaco"
local itemop = require "itemop"
local card_container = require "card_container"
local sfmt = string.format
local tbl = require "tbl"
local tpskill = require "__tpskill"
local tpcard = require "__tpcard"
local tppassiveskill = require "__tppassiveskill"
local tpcardbreakthrough = require "__tpcardbreakthrough"
local task = require "task"
local broad_cast = require "broad_cast"
local tpitem = require "__tpitem"
local equip_attributes = require "equip_attribute"
local REQ = {}

local function sync_partner_info(ur,pos)
	local partners = ur.cards.__partner
	local partner_flag = false
	for i =1,2 do
		if partners[i].pos == pos then
			partner_flag = true
		end
	end
	if partner_flag then
		ur:change_role_battle_value()
		card_container.sync_partner_attribute(ur)
	end
end

local function check_occup_enough(cardid,itemid,level)
	local equip_part = 0
	local tp_card = tpcard[cardid]
	if not tp_card then
		return 0,equip_part
	end
	local tp_item = tpitem[itemid]
	if not tp_item then
		return 0,equip_part
	end
	if level < tp_item.level then
		return 1,equip_part
	end
	if tp_item.occup ~= 1 and (tp_item.occup >> tp_card.occupation) & 1 == 0 then
		return 2,equip_part
	end
	return 3,tp_item.equipPart
end

REQ[IDUM_EQUIPCARD] = function(ur, v)
	local bag = ur:getbag(v.bag_type)
    if not bag then
        return
    end
     local item = itemop.get(bag,v.pos)
    if not item then
        return SERR_ITEM_NOT_EXIST
    end
	local card = card_container.get_target(ur,v.card_pos)
	if not card then
		return SERR_CARD_NOT_EXIST
	end
	local flag,equip_part = check_occup_enough(card.cardid,item.tpltid,card.level)
	if flag == 2 then
		return SERR_NOT_NEED_OCCUPATION
	elseif flag == 1 then
		return SERR_LEVEL_NOT
	elseif flag == 0 then
		return
	end
	if card_container.equip(ur,v.card_pos,v.pos) then
		itemop.refresh(ur)
       	local equip = itemop.getall(card.equip)
		card.equip = equip
       	ur:send(IDUM_UPDATECARDEQUIP, {info=card}) 	
       	card.equip = ur.equip.new(BAG_MAX+card.pos,EQUIP_MAX,card.equip)
       	ur:db_tagdirty(ur.DB_CARD)
       	ur:db_tagdirty(ur.DB_ITEM)
		local attribute = ur.cards.__card.__attributes[v.card_pos]
		attribute.equip_attribute[equip_part] = nil
		attribute.equip_attribute[equip_part] = equip_attributes.new(item.info,item.tpltid)
		--local card_attributes = ur.cards.__card.__attributes[v.card_pos]
		--card_attributes:equip_add(card.equip,equip_part)
		sync_partner_info(ur,v.card_pos)
	end
end

REQ[IDUM_UNEQUIPCARD] = function(ur, v)
    local card = card_container.get_target(ur,v.card_pos)
	if not card then
		return SERR_CARD_NOT_EXIST
	end
	
	local bag1 = card.equip
	local card_attributes = ur.cards.__card.__attributes[v.card_pos]
	--card_attributes:equip_reduce(bag1,v.pos)
    local bag2 = ur:getbag(BAG_MAT)
    if itemop.move(bag1,v.pos,bag2) then
        itemop.refresh(ur)
    	local equip = itemop.getall(card.equip)
		card.equip = equip
       	ur:send(IDUM_UPDATECARDEQUIP, {info=card}) 	
       	card.equip = ur.equip.new(BAG_MAX+card.pos,EQUIP_MAX,card.equip)
    	ur:db_tagdirty(ur.DB_CARD)
        ur:db_tagdirty(ur.DB_ITEM)
		card_attributes.equip_attribute[v.pos] = nil
		
		--tbl.print(card_attributes.equip_attribute,"-----------------------------------------card_attributes.equip_attribute ============================= ")
		sync_partner_info(ur,v.card_pos)
    end
end

REQ[IDUM_CARDUP] = function(ur, v)
	local target,indx = card_container.get_target(ur,v.tarpos)
	if not target then
		return SERR_CARD_NOT_EXIST
	end
	local partners = ur.cards.__partner
	for i =1,#v.material do
		for j =1,2 do
			if partners[j].pos == v.material[i].pos  then
				return SERR_MATERIAL_IS_PARTNER
			end
		end
		if v.material[i].pos == v.tarpos then
			return SERR_MATERIAL_HAVE_SELF
		end
	end
	local addexp = card_container.card_up_level(ur,v)
	local flag = card_container.set_exp(ur,target,addexp,indx)
	task.set_task_progress(ur,26,1,0)
	task.refresh_toclient(ur, 26)
	ur:db_tagdirty(ur.DB_CARD)
	card_container.refresh(ur)
	task.set_task_progress(ur,27,target.level,0)
	task.refresh_toclient(ur, 27)
	sync_partner_info(ur,v.tarpos)
	ur:send(IDUM_CARDUP_RESULT, {info = target})
	local partner_flag = false
end

REQ[IDUM_CARDPARTNER] = function(ur, v)
	local partners = ur.cards.__partner
	local cards = ur.cards
	local posv = v.partnerv
	for i = 1,#posv do 
		local card = cards:get(posv[i].pos)
		if not card then
			return SERR_CARD_NOT_EXIST
		end
	end
	for i =1,2 do
		partners[i].pos = 0
		partners[i].pos_idx = 0
	end
	card_container.sync_partner_attribute(ur)
	for i = 1,#posv do
		partners[i].pos = posv[i].pos
		partners[i].pos_idx = posv[i].pos_idx
		card_container.set_old_partner(ur.cards,posv[i].pos)
	end
	task.set_task_progress(ur,7,#posv,0)
	task.refresh_toclient(ur, 7)
	ur:db_tagdirty(ur.DB_CARD)
	ur:change_role_battle_value()
	ur:send(IDUM_CONFIRMPARTNER, {partnerv = posv})
end

local function get_unlock_level(cardid,skill_type,skill_level)
	local unlock_level = 0
	local tp = tpcard[cardid]
	if not tp then
		return unlock_level
	end
	for i =1,4 do
		local skill = tp["skill"..i]
		if skill[2] == skill_type and skill[3] == skill_level then
			unlock_level = skill[1]
		end
	end
	return unlock_level
end

local function skill_up_info_gen()
	return{
		skill_type = 0,
		skill_level = 0,
		card_pos = 0,
	}
end

local function up_level_skill(skill_class,v,level,skills,skill_level)
	local skill_type = 0
	local tp = tpskill
	if skill_class == 1 then
		tp = tpskill
	elseif skill_class == 2 then
		tp = tppassiveskill
	end
	local level_info = skill_up_info_gen()
	for k, u in pairs(tp) do
		local temp_type = 0
		if skill_class == 1 then
			temp_type = u.skill_type
		elseif skill_class == 2 then
			temp_type = u.passiveSkill_type
		end
		if temp_type == v.up_level_info.skill_type and u.level == (skill_level + 1) then
			if u.levellimit > level then
				--skill_type =2
				--break
			end
			for i =1,#skills do
				local skill = skills[i]
				if not skill then
					skill_type = 1
					return skill_type,level_info
				elseif skill.skill_type == v.up_level_info.skill_type and skill.skill_level == skill_level  then
					skill.skill_level = skill_level + 1
					
					level_info.skill_level = skill.skill_level
					level_info.skill_type = skill.skill_type
					level_info.card_pos = v.up_level_info.card_pos
					skill_type =3
					return skill_type,level_info
				end
			end
		end		
	end
	return skill_type,level_info
end

REQ[IDUM_CARDSKILLUP] = function(ur, v)
	local open_bit = ur.info.open_bit
	if (open_bit >> FUNC_CARD_UP) & 1 == 0 then
		return SERR_FUNCTION_NOT_OPEN
	end
	local cards = ur.cards.__card
	local target = card_container.get_target(ur,v.card_pos)
	if not target then
		return SERR_CARD_NOT_EXIST
	end
	local tp = nil
	if v.skillid > 0 then
		tp = tpskill[v.skillid]
	else
		local __gift = {}
		local gift_tp = tppassiveskill[v.skill_idx]
		if gift_tp then
			for j = 1,#gift_tp do
				local u = gift_tp[j]
				if u.skill_idx == v.skill_idx and u.type == v.gift_type and u.level == v.level then
					tp = u
					break
				end
			end
		end
	end
	if not tp then
		return SERR_ERROR_LABEL
	end
	local level = target.level
	if level < tp.levellimit then
		return SERR_SKILL_UNLOCK
	end
	if ur:coin_enough(tp.gold) == false then
		return SERR_COIN_NOT_ENOUGH
	end
	local item1_flag = false
	local item2_flag = false 
	if tp.item_num > 0 then
		if itemop.enough(ur, tp.item, tp.item_num) == true then
			item1_flag = true
		else
			item1_flag = false
		end
	else
		item1_flag = true
	end
	if tp.item2_num > 0 then
		if itemop.enough(ur, tp.item2, tp.item2_num) == true then
			item2_flag = true
		else
			item2_flag = false
		end
	else
		item2_flag = true
	end
	if item1_flag == true and item2_flag == true then
		itemop.take(ur, tp.item, tp.item_num)
		itemop.take(ur, tp.item2, tp.item2_num)
	else
		return SERR_MATERIAL_NOT_ENOUGH
	end
	ur:coin_got(tp.gold)
	local skillv = {}
	local skill = target.skills
	if v.skillid > 0 then
		for i = 1,#skill do
			local __tp = tpskill[skill[i].skill_id]
			if __tp.skill_idx == tp.skill_idx then
				skill[i].skill_id = v.skillid
				break
			end
		end
	else
		local flag = false
		for i = 1,#skill do
			if flag == true then
				break
			end
			local tanlent = skill[i].gift
			for j =1,#skill[i].gift do
				local gift_info = skill[i].gift[j]	
				if gift_info.skill_idx == v.skill_idx and gift_info.__type == v.gift_type and gift_info.level == v.level -1 then
					gift_info.level = gift_info.level + 1
					local card_attributes = cards.__attributes[v.card_pos]
					if card_attributes then
						card_attributes:change_passive_skill_attr(gift_info.skill_idx,gift_info.__type,gift_info.level)
					end
					ur:change_attribute()
					sync_partner_info(ur,v.card_pos)
					flag = true
					break
				end
			end
		end
	end
	task.set_task_progress(ur,18,1,0)
	task.refresh_toclient(ur, 18)
	task.change_task_progress(ur,49,1,1)
	task.refresh_toclient(ur, 49)
	itemop.refresh(ur)
	ur:send(IDUM_CARDUPDATESKILL, {success = 1})
	ur:db_tagdirty(ur.DB_CARD)
	ur:db_tagdirty(ur.DB_ITEM)
end

REQ[IDUM_REQBREAKTHROUGH] = function(ur, v)
	local open_bit = ur.info.open_bit
	if (open_bit >> FUNC_CARD_BREAK) & 1 == 0 then
		return SERR_FUNCTION_NOT_OPEN
	end
	local target = card_container.get_target(ur,v.tarpos)
	if not target then
		return SERR_CARD_NOT_EXIST
	end
	local cardid = target.cardid
	local target_tp = tpcard[cardid]
	local tp
	for k,u in pairs(tpcardbreakthrough) do
		if u.quality == target_tp.quality and u.breakthrough == target.break_through_num + 1 then
			tp = u
			break
		end
	end
	if not tp then
		return SERR_ERROR_LABEL
	end
	if tp.breakthrough == target.break_through_num then
		return SERR_BREAK_THROUGH_MAX
	end
	if #v.material_posv ~= tp.number then
		return SERR_NUMBER_NOT_ENOUGH
	end
	for i =1,#v.material_posv do
		local material = card_container.get_target(ur,v.material_posv[i])
		if not material then
			return SERR_CARD_NOT_EXIST
		end
		local card_info = tpcard[material.cardid]
		if not card_info then
			return SERR_ERROR_LABEL
		end	
		if tp.type == 0 then
			if card_info.quality ~= tp.quality then
				return SERR_MATERIAL_QUALITY
			end
			if material.level ~= (card_info.maxLevel + material.break_through_num * card_info.breakthroughEffect) then
				return SERR_MATERIAL_LEVEL_NOT_ENOUGH
			end
		elseif tp.type == 1 then
			if card_info.quality ~= tp.quality or material.break_through_num ~= 1 then
				return SERR_MATERIAL_QUALITY
			end
		elseif tp.type == 2 then
			if card_info.quality ~= tp.quality then
				return SERR_MATERIAL_QUALITY
			end
			if material.break_through_num > 0 then
				return SERR_MATERIAL_BREAK
			end
		elseif tp.type == 3 then
			if card_info.quality ~= tp.quality or material.break_through_num ~= 2 then
				return SERR_MATERIAL_QUALITY
			end
		elseif tp.type == 4 then
			if card_info.quality ~= tp.quality or material.break_through_num ~= 3 then
				return SERR_MATERIAL_QUALITY
			end
		elseif tp.type == 5 then
			if card_info.quality ~= tp.quality or material.break_through_num ~= 4 then
				return SERR_MATERIAL_QUALITY
			end
		end
	end
	for i = 1,#v.material_posv do
		ur.cards:remove(v.material_posv[i])
	end
	target.break_through_num = target.break_through_num + 1
	ur.cards.__card.__attributes[v.tarpos]:break_through_compute(cardid,target.break_through_num)
	task.set_task_progress(ur,21,1,0)
	task.refresh_toclient(ur, 21)
	task.set_task_progress(ur,22,target.break_through_num,0)
	task.refresh_toclient(ur, 22)
	local maxLevel = target_tp.maxLevel + target_tp.breakthroughEffect * (target.break_through_num - 1) 
	if target.level >= maxLevel then
		card_container.set_beyond_exp(ur,target)
	end
	ur:db_tagdirty(ur.DB_CARD)
	card_container.refresh(ur)
	broad_cast.set_borad_cast(ur,target,NOTICE_CARD_BREAK_T)
	--broad_cast.check_card_break_through(ur,target)
	sync_partner_info(ur,v.tarpos)
	ur:send(IDUM_ACKBREAKTHROUGH, {info = target})
end

return REQ
