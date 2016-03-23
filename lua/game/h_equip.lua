local shaco = require "shaco"
local tpitem = require "__tpitem"
local tpequip = require "__tpequip"
local tpforge = require "__tpforge"
local tpgodcast = require "__tpgodcast"
local tpequipalloy = require "__tpequipalloy"
local tpgamedata = require "__tpgamedata"
local tpcard = require "__tpcard"
local itemop = require "itemop"
local tostring = tostring
local tbl = require "tbl"
local card_container = require "card_container"
local task = require "task"
local sfmt = string.format
local tpfix = require "tpfix"
local tpfusion_award = require "__tpfusion_award"
local tpfusion_treasure = require "__tpfusion_treasure"
local tpgem = require "__tpgem"
local tpgemholes = require "__tpgemholes"
local tpwashprice = require "__tpwashprice"
local club = require "club"
local broad_cast = require "broad_cast"
local equip_attributes = require "equip_attribute"
local random = math.random

local REQ = {}

local function change_attribute(rate,equip,tp)
    equip.level = equip.level + rate
    equip.attack = equip.attack + tp.Atk*rate
    equip.defense = equip.defense + tp.Def*rate
    equip.magic = equip.magic + tp.Magic*rate
    equip.magicdef = equip.magicdef + tp.MagicDef*rate
    equip.hp = equip.hp + tp.HP*rate
    return equip
end

REQ[IDUM_EQUIPINTENSIFY] = function(ur, v)
	local flag = false
	local tp_equip
	local level = ur.base.level
	local bag = ur:getbag(v.bag_type)
	if v.pos >= 1000 then
		local pos = v.pos - 1000
		local card = card_container.get_target(ur,pos)
		bag = card.equip
		level = card.level
	end
    if not bag then
        return SERR_TYPE_ERROR
    end
    local item = itemop.get(bag,EQUIP_WEAPON)
    if not item then
        return SERR_ITEM_NOT_EXIST
    end
    local tp = tpitem[item.tpltid]
    if not tp then
    	return SERR_ERROR_LABEL
    end 
    if tp.equipPart ~= EQUIP_WEAPON then
    	return SERR_EQUIP_NOT_INTENSIFY
    end
	for k, u in ipairs(tpequip) do
		if u.EquipID == item.tpltid then
			tp_equip = u
			break
		end
	end
	if not tp_equip then
        return SERR_ITEM_NOT_EXIST
    end
	local take = tp_equip.Price + tp_equip.amplification * item.info.level
	if ur:coin_enough(take) == false then 
		return SERR_COIN_NOT_ENOUGH
	end
	if item.info.level >= level then
		print("item.info.level === "..item.info.level.."  --- level == "..level)
		return SERR_CUR_LEVEL_MAX
	end
    if item.info.level >= tp_equip.MaxLevel then
    	return SERR_WEAPON_INTENSIFY_MAX_LEVEL
    end
	
    if ur:coin_take(take) == false then
		return SERR_COIN_NOT_ENOUGH
	end 
	item.info = change_attribute(1,item.info,tp_equip)
	if v.pos >= 1000 then 
		ur.cards.__card.__attributes[v.pos - 1000].equip_attribute[EQUIP_WEAPON]:weapon_intensify(1,tp_equip)
	else
		ur.attribute.equip_attribute[EQUIP_WEAPON]:weapon_intensify(1,tp_equip)
		itemop.update(bag, EQUIP_WEAPON)
	end
	itemop.refresh(ur)
	ur:sync_role_data()
	ur:db_tagdirty(ur.DB_ROLE)
	if v.pos >= 1000 then 
		local pos = v.pos - 1000
		local card = card_container.get_target(ur,pos)	
		local equip = itemop.getall(card.equip)
		card.equip = equip
		ur:send(IDUM_UPDATE_CARD_WEAPON, {handle_type = INTENSIFY,info=card}) 	
		card.equip = ur.equip.new(BAG_MAX+card.pos,EQUIP_MAX,card.equip)
		ur:db_tagdirty(ur.DB_CARD)
		card_container.sync_partner_weapon_attribute(ur,pos)
	else
		--tbl.print(ur.attribute.equip_attribute[EQUIP_WEAPON],"ur.attribute.equip_attribute[EQUIP_WEAPON] -================  ")
		task.set_task_progress(ur,5,item.info.level,0)
		task.refresh_toclient(ur, 5)
		ur:change_attribute()
		ur:send(IDUM_SUCCESSRETURN,{success_type = INTENSIFY}) 
		ur:db_tagdirty(ur.DB_ITEM)
	end
	task.change_task_progress(ur,48,1,1)
	task.refresh_toclient(ur, 48)
end

local function check_material_enough(ur,bag,materialarray)
	local templist = {}
	for j = 1,#materialarray do
		--reward_gen()
		templist[j] = {itemid = 0, itemcnt = 0}
		templist[j].itemid = (materialarray[j][1])
    	templist[j].itemcnt = (materialarray[j][2])
		--shaco.trace(sfmt("user -----------------------------templist[j].itemid ==%d   templist[j].itemcnt ===%d ...",templist[j].itemid,templist[j].itemcnt))
    	if not itemop.enough(ur, templist[j].itemid, templist[j].itemcnt) then
			
    		return false
    	end
	end
	
	for i =1 ,#templist do
		itemop.take(ur, templist[i].itemid, templist[i].itemcnt)
	end
	
	return true
end

local function check_own_equip(ur,equipid)
	local items = ur.equip.items
	for i, item in ipairs(items) do
        if item.tpltid == equipid then
        	return item.info.level
        end
    end
    return 0
end

local function change_weapon_level(ur,bag,pos,add_lvl)
	--shaco.trace(sfmt("user --------add_lvl == %d ------------------  d create role ...",add_lvl))
	local weapon_item = itemop.get(bag,EQUIP_WEAPON)
    if not weapon_item then
		
        return 
    end
	
	local tp_equip 
	for k, u in ipairs(tpequip) do
		if u.EquipID == weapon_item.tpltid then
			tp_equip = u
			break
		end
	end
	if not tp_equip then
        return 
    end
	
	weapon_item.info = change_attribute(add_lvl,weapon_item.info,tp_equip)
	if pos >= 1000 then 
		ur.cards.__card.__attributes[pos - 1000].equip_attribute[EQUIP_WEAPON]:weapon_intensify(add_lvl,tp_equip)
	else
		ur.attribute.equip_attribute[EQUIP_WEAPON]:weapon_intensify(add_lvl,tp_equip)
		--ur:weapon_intensify(add_lvl,tp_equip)
		itemop.update(bag, EQUIP_WEAPON)
	end
end

local function set_weapon_hole(bag,holes)
	if not holes then
		return
	end
	local item = itemop.get(bag, EQUIP_WEAPON)
	if not item then
		return
	end
	item.info.hole = holes
end

REQ[IDUM_EQUIPFORGE] = function(ur, v) 
	local needRole = ur.base.tpltid
	local bag = ur:getbag(v.bag_type)
	
	if v.targetid >= 1000 then
		local pos = v.targetid - 1000
		local card = card_container.get_target(ur,pos)
		bag = card.equip
		needRole = card.cardid
	end
    if not bag then
        return SERR_TYPE_ERROR
    end
    local bag_mat = ur:getbag(BAG_MAT)
    if not bag_mat then
    	return SERR_TYPE_ERROR
    end
	local tp_forge = tpfix.get_forge()
	local tp
	local indx = ((v.drawingid << 2) + needRole)	
	tp = tp_forge[indx]
	local rate = 0
	if tp.needOccupation then
		if v.targetid >= 1000 then
			local pos = v.targetid - 1000
			local card = card_container.get_target(ur,pos)
			local tp_card = tpcard[card.cardid]
			if tp.needOccupation ~= tp_card.occupation then
				return SERR_NOT_NEED_OCCUPATION
			end
			if tp.needRole ~= card.cardid then
				return SERR_NOT_NEED_SEX
			end 
		else
			if tp.needOccupation ~= ur.base.race then
				return SERR_NOT_NEED_OCCUPATION
			end
		end
	end
	local baseequip = tp.needEquip
	local level = 0
	local item = {}
	local holes
	if baseequip ~= 0 then
		item = itemop.get(bag, EQUIP_WEAPON)
		if not item then
			return SERR_NOT_OWN_BASE_WEAPON
		end
		level = item.info.level
		holes = item.info.hole
	end
	if ur:coin_enough(tp.Price) == false then 
		return SERR_COIN_NOT_ENOUGH
	end
	--shaco.trace(sfmt("user ------------------------------- create role ..."))
	local materialarray = tp.itemNeed
	if check_material_enough(ur,bag_mat,materialarray) == false then
		
		return SERR_MATERIAL_NOT_ENOUGH
	end
	ur:coin_take(tp.Price)
	if v.targetid < 1000 then
		ur.attribute.equip_attribute[EQUIP_WEAPON] = nil
		--ur.info.attribute:remove_weapon(bag,EQUIP_WEAPON)
	else
		ur.cards.__card.__attributes[v.targetid - 1000].equip_attribute[EQUIP_WEAPON] = nil ---:remove_weapon(bag,EQUIP_WEAPON)
	end
	
	itemop.remove_bypos(bag,EQUIP_WEAPON,1)
	itemop.gain_weapon(bag, tp.outputEquip)
	--if not holes then
		--print("---------------- baseequip === "..baseequip.."----duan zhao shi baoshi kong error----")
	--end
	set_weapon_hole(bag,holes)
	rate = level - tp.levelMinus
	if rate <= 0 then
		rate = 1
	end
	local _item = itemop.get(bag, EQUIP_WEAPON)
	if v.targetid < 1000 then
		ur.attribute.equip_attribute[EQUIP_WEAPON] = equip_attributes.new(_item.info,_item.tpltid)
	else
		ur.cards.__card.__attributes[v.targetid - 1000].equip_attribute[EQUIP_WEAPON] = equip_attributes.new(_item.info,_item.tpltid)  
	end
	--tbl.print(ur.attribute.equip_attribute[EQUIP_WEAPON],"ur.attribute.equip_attribute[EQUIP_WEAPON] ======111111111111111========  ")
	change_weapon_level(ur,bag,v.targetid,rate)
	--tbl.print(ur.attribute.equip_attribute[EQUIP_WEAPON],"ur.attribute.equip_attribute[EQUIP_WEAPON] ==============  ")
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ROLE)
	ur:db_tagdirty(ur.DB_ITEM)
	task.set_task_progress(ur,23,1,0)
	task.refresh_toclient(ur, 23)
	local tp_item = tpitem[tp.outputEquip]
	task.set_task_progress(ur,24,tp_item.quality,0)
	task.refresh_toclient(ur, 24)
	ur:sync_role_data()
	--if tp
	if v.targetid >= 1000 then 
		local pos = v.targetid - 1000
		local card = card_container.get_target(ur,pos)	
		local equip = itemop.getall(card.equip)
		card.equip = equip
		ur:send(IDUM_UPDATE_CARD_WEAPON, {handle_type = FORGE,info=card}) 	
		card.equip = ur.equip.new(BAG_MAX+card.pos,EQUIP_MAX,card.equip)
		card_container.sync_partner_weapon_attribute(ur,pos)
		ur:db_tagdirty(ur.DB_CARD)
	else
		ur:change_attribute()
		ur:send(IDUM_SUCCESSRETURN,{success_type = FORGE}) 
	end
	if tp_item.quality >= 5 then
		local ids = {original_id = tp.needEquip,outputEquip = tp.outputEquip}
		broad_cast.set_borad_cast(ur,ids,NOTICE_FORGE_T)
	end
	--broad_cast.check_weapon_forge(ur,item.tpltid,tp.outputEquip)
end

local function change_some_attribute(starproperties,info)
 	for i = 1, #starproperties do
 		if starproperties[i][1] == 1 then
 			info.hp = info.hp + starproperties[i][2]
 		elseif starproperties[i][1] == 2 then
			info.mp = info.mp + starproperties[i][2]
 		elseif starproperties[i][1] == 3 then
			info.mp_reply = info.mp_reply + starproperties[i][2]
 		elseif starproperties[i][1] == 4 then
 			info.attack = info.attack + starproperties[i][2]
 		elseif starproperties[i][1] == 5 then
 			info.defense = info.defense + starproperties[i][2]
 		elseif starproperties[i][1] == 6 then
 			info.magic = info.magic + starproperties[i][2]
 		elseif starproperties[i][1] == 7 then
 			info.magicdef = info.magicdef + starproperties[i][2]
 		elseif starproperties[i][1] == 8 then
			info.hp_reply = info.hp_reply + starproperties[i][2]
 		elseif starproperties[i][1] == 9 then
			info.atk_res = info.atk_res + starproperties[i][2]
 		elseif starproperties[i][1] == 10 then
			info.mag_res = info.mag_res + starproperties[i][2]
		elseif starproperties[i][1] == 11 then
			info.dodge = info.dodge + starproperties[i][2]
		elseif starproperties[i][1] == 12 then
			info.atk_crit = info.atk_crit + starproperties[i][2]
		elseif starproperties[i][1] == 13 then
			info.mag_crit = info.mag_crit + starproperties[i][2]
		elseif starproperties[i][1] == 14 then
			info.block = info.block + starproperties[i][2]
		elseif starproperties[i][1] == 15 then
			info.block_value = info.block_value + starproperties[i][2]
		elseif starproperties[i][1] == 16 then
			info.hits = info.hits + starproperties[i][2]
 		end
 	end
 	return info
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

REQ[IDUM_EQUIPGODCAST] = function(ur, v)
	local open_bit = ur.info.open_bit
	if (open_bit >> FUNC_FORGE) & 1 == 0 then
		return SERR_FUNCTION_NOT_OPEN
	end
	local bag = ur:getbag(v.bag_type)
	if v.pos >= 1000 then
		local pos = v.pos - 1000
		local card = card_container.get_target(ur,pos)
		bag = card.equip
	end
	
    if not bag then
        return SERR_TYPE_ERROR
    end
    local bag_mat = ur:getbag(BAG_MAT)
    if not bag_mat then
    	return SERR_TYPE_ERROR
    end
	local item = itemop.get(bag, EQUIP_WEAPON)
	if not item then
		return SERR_NOT_OWN_BASE_WEAPON
	end
	local star = item.info.star + 1
	local tp
	for k, u in pairs(tpgodcast) do
		if u.equipID == item.tpltid then
			tp = u
			break
		end
	end
	if not tp then
		return SERR_ERROR_LABEL
	end
	local take = 0
	take = tp.Price[star]
	--print("star ==== ",star)
	--tbl.print(tp.Price, "=============init tp.Price", shaco.trace)
	--print("take ====== "..take)
	if ur:coin_enough(take) == false then 
		return SERR_COIN_NOT_ENOUGH
	end
	if item.info.refinecnt <= 0 then
		return SERR_GODCAST_MAX_COUNT
	end
	local targetstar = tp["star"..tostring(star)]
	if check_material_enough(ur,bag_mat,tp["star"..tostring(star)]) == false then
		return SERR_MATERIAL_NOT_ENOUGH
	end		
	item.info = change_some_attribute(tp["star"..tostring(star).."properties"],item.info)
	item.info.star = star
	item.info.refinecnt = item.info.refinecnt - 1
	local max_refine_cnt = get_refine_cnt(item.tpltid)
	task.set_task_progress(ur,53,(max_refine_cnt - item.info.refinecnt),0)
	task.refresh_toclient(ur, 53)
	if v.pos >= 1000 then 
		ur.cards.__card.__attributes[v.pos - 1000].equip_attribute[EQUIP_WEAPON]:weapon_godcast(tp["star"..tostring(star).."properties"])
	else
		ur.attribute.equip_attribute[EQUIP_WEAPON]:weapon_godcast(tp["star"..tostring(star).."properties"])
		itemop.update(bag, EQUIP_WEAPON)
	end
	if ur:coin_take(take) == false then
		return SERR_COIN_NOT_ENOUGH
	end 
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
	ur:sync_role_data()
	if v.pos >= 1000 then 
		local pos = v.pos - 1000
		local card = card_container.get_target(ur,pos)	
		local equip = itemop.getall(card.equip)
		card.equip = equip
		ur:send(IDUM_UPDATE_CARD_WEAPON, {handle_type = GODCAST,info=card}) 	
		card.equip = ur.equip.new(BAG_MAX+card.pos,EQUIP_MAX,card.equip)
		card_container.sync_partner_weapon_attribute(ur,pos)
		ur:db_tagdirty(ur.DB_CARD)
	else
		ur:change_attribute()
		ur:send(IDUM_SUCCESSRETURN,{success_type = GODCAST})  
	end
	local common = {itemid =item.tpltid, refinecnt = max_refine_cnt - item.info.refinecnt}
	broad_cast.set_borad_cast(ur,common,NOTICE_GOD_CAST_T)
	--broad_cast.check_weapon_godcast(ur,item.tpltid,(max_refine_cnt - item.info.refinecnt))
end

local function better_quality(quality)
	local itemlist = {}
	for k, v in pairs(tpitem) do
		if v.quality == quality then
			itemlist[#itemlist + 1] = k
		end
	end
	if #itemlist == 0 then
		return
	end
	local index = math.random(#itemlist)
	return itemlist[index]
end

local function check_item_quality(items)
	local quality = 0
	for i =1,#items do
		local tp = tpitem[items[i].tpltid]
		if i == 1 then
			quality = tp.quality
		end
		if quality ~= tp.quality then
			return false,quality
		end
	end
	return true,quality
end

REQ[IDUM_EQUIPCOMPOSE] = function(ur, v)
	local open_bit = ur.info.open_bit
	if (open_bit >> FUNC_COMPOSE) & 1 == 0 then
		return SERR_FUNCTION_NOT_OPEN
	end
	local bag = ur:getbag(BAG_MAT)
    if not bag then
        return SERR_TYPE_ERROR
    end
	local items = {}
	local total_fusion = 0
	for i =1,#v.posv do
		local item = itemop.get(bag, v.posv[i])
		if not item then
			return SERR_ITEM_NOT_EXIST
		end
		local tp = tpitem[item.tpltid]
		if not tp then
			return SERR_ERROR_LABEL
		end
		total_fusion = total_fusion + tp.fusion
		items[#items+1] = item
	end
	if #items ~= 5 then
		return SERR_MATERIAL_NOT_ENOUGH
	end
	local item_list = {}
	local gempos_num = 0
	local wash_num = 0
	for i = 1,#tpfusion_award do
		local tp = tpfusion_award[i]
		if not tp then
			return SERR_ERROR_LABEL
		end
		if tp.fusion[1][1] <= total_fusion and tp.fusion[1][2] >= total_fusion then
			gempos_num = tp.GemMax
			wash_num = tp.WashMax
			for j = 1,#tp.award do
				local tp_treasure = tpfusion_treasure[tp.award[j]]
				for m = 1,#tp_treasure do
					item_list[#item_list + 1] = tp_treasure[m]
				end
			end
		end
	end
	local total_weigh = 0
	for i = 1,#item_list do
		local tp = item_list[i]
		total_weigh = total_weigh + tp.weighing
	end
	local randvalue = random(1,total_weigh)
	local temp_weight = 0
	local result
	for i = 1,#item_list do
		local tp = item_list[i]
		temp_weight = temp_weight + tp.weighing
		if temp_weight >= randvalue then
			result = tp
			break
		end
	end
	
	for i =1, #items do
		itemop.remove_bypos(bag, items[i].pos, 1)
	end
	if not result then
		return SERR_ERROR_LABEL
	end
	--tbl.print(result,"result ============= ")
	local pos = 0
	local itemid = result.item_id
	local itemcnt = result.count
	if result.type == 1 or result.type == 3 then --道具
		itemop.gain(ur, itemid, itemcnt,gempos_num,wash_num)
		local function innercb(item)
			pos = item.pos
		end
		itemop.refresh(ur,innercb)
	elseif result.type == 2 then
		local cards = ur.cards
		if not card_container.enough(ur,itemcnt) then
			return SERR_CARD_GRID_MAX
		end
		cards:put(ur,itemid,itemcnt)
		itemop.refresh(ur)
		card_container.refresh(ur)
		ur:db_tagdirty(ur.DB_CARD)
	--elseif result.type == 3 then
		--club.add_fragment(ur,itemid,itemcnt)	
		--ur:send(IDUM_NOTICEADDFRAGMENT, {fragmentid =itemid,fragment_cnt = itemcnt})
		--itemop.refresh(ur)
	elseif result.type == 4 then
		ur:coin_got(itemcnt)
		itemop.refresh(ur)
		ur:db_tagdirty(ur.DB_ROLE)
		ur:sync_role_data()
	elseif result.type == 5 then
		ur:gold_got(itemcnt)
		itemop.refresh(ur)
		ur:db_tagdirty(ur.DB_ROLE)
		ur:sync_role_data()
	end
	task.set_task_progress(ur,44,1,0)
	task.refresh_toclient(ur, 44)
	ur:db_tagdirty(ur.DB_ITEM)
	--print("pos ====== "..pos)
	ur:send(IDUM_EQUIPCOMPOSERESULT, {itemid = result.item_id,item_pos = pos,item_cnt = result.count,item_type = result.type})
	local tp = tpitem[result.item_id]
	if tp and tp.quality >= 5 then
		broad_cast.set_borad_cast(ur,result.item_id,NOTICE_EQUIP_COMPOSE_T)
	end
end

local function check_equip_hole(indx,hole)
	for i = 1,#hole do
		if hole[i].indx == indx then
			if hole[i].gemid >0 or hole[i].state ~= 1 then
				return true
			end
		end
	end
	return false
end

local function set_hole_gem(indx,hole,gemid)
	for i = 1,#hole do
		if indx ~= 0 then
			if hole[i].indx == indx then
				if hole[i].gemid == 0 and hole[i].state == 1 then
					hole[i].gemid = gemid
				end
			end
		else
			if hole[i].gemid == 0 and hole[i].state == 1 then
				hole[i].gemid = gemid
				return hole[i].indx
			end
		end
	end
end

local function get_gem_position_num(hole)
	local num = 0
	for i = 1,#hole do
		local info = hole[i] 
		if info.state == 1 and  info.gemid == 0 then
			num = num + 1
		end
	end
	return num
end

local function check_is_exisit(item_list,itemid)
	for i = 1,#item_list do
		local item = item_list[i]
		if item.tpltid == itemid then
			return true
		end
	end
	return false
end

local function get_enough_gem(bag,count)
	local gem_list = itemop.get_gem_list(bag)
	local item_list = {}
	local index = 1
	for j = 1,count do
		local max_level = 1
		
		local max_item
		for i = 1,#gem_list do
			local item = gem_list[i]
			if not check_is_exisit(item_list,item.tpltid) then
				local tp = tpgem[item.tpltid][1]
				if tp then
					if tp.Level >= max_level then
						--print("max_level == "..max_level)
						max_level = tp.Level
						max_item = item
					end
				end
			end
		end
		if max_item then
			j = j + max_item.stack
			for i = 1,max_item.stack do
				local function gem_gen()
					return {
						tpltid = 0,
						pos = 0,
						index = 0,
					}
				end
				if index < 5 then
					local info = gem_gen()
					info.tpltid = max_item.tpltid
					info.pos = max_item.pos
					info.index = index
					index = index + 1
					item_list[#item_list + 1] = info
				end
			end
		end
	end
	return item_list
end

REQ[IDUM_REQINLAYGEM] = function(ur, v)
	local bag_package = ur:getbag(BAG_MAT)
	local bag = ur:getbag(v.bag_type)
	if v.pos >= 1000 then
		local pos = v.pos - 1000
		local card = card_container.get_target(ur,pos)
		bag = card.equip
	end
    if not bag then
        return SERR_TYPE_ERROR
    end
    local item = itemop.get(bag,v.equip_pos)
    if not item then
        return SERR_ITEM_NOT_EXIST
    end
	local tp = tpitem[item.tpltid]
    if not tp then
    	return SERR_ERROR_LABEL
    end 
	if tp.itemType ~= ITEM_EQUIP then
		return 
	end
	local tp_gemholes = tpgemholes[tp.canPunch]
	if not tp_gemholes then
		return SERR_ERROR_LABEL
	end
	if v.inlay_type == 1 then
		local gem_item = itemop.get(bag_package,v.item_pos)
		if not gem_item then
			return SERR_ITEM_NOT_EXIST
		end
	
		local gem_tp = tpgem[gem_item.tpltid][1]
		if not gem_tp then
			return SERR_ERROR_LABEL
		end
		if check_equip_hole(v.hole_pos,item.info.hole) then
			return SERR_GEMISEXISIT
		end
		set_hole_gem(v.hole_pos,item.info.hole,gem_item.tpltid)
		itemop.remove_bypos(bag_package,v.item_pos, 1)
		if v.bag_type == BAG_EQUIP then
			
			if v.pos >= 1000 then 
				--local card = card_container.get_target(ur,v.pos - 1000)
				--ur.cards.__card.__attributes[v.pos - 1000]:compute_gem_attribute(gem_tp.Attributes,tp_gemholes,v.hole_pos,1)
				equip_attributes.compute_gem_attribute(ur.cards.__card.__attributes[v.pos - 1000].equip_attribute[v.equip_pos],gem_tp.Attributes,tp_gemholes,v.hole_pos,1)
			else
				equip_attributes.compute_gem_attribute(ur.attribute.equip_attribute[v.equip_pos],gem_tp.Attributes,tp_gemholes,v.hole_pos,1)
				itemop.update(bag, tp.equipPart)
			end
		else
			itemop.update(bag, item.pos)
		end
	elseif v.inlay_type == 2 then
		local count = get_gem_position_num(item.info.hole)
		--print("count ==== "..count)
		local gem_list = get_enough_gem(bag_package,count)
		--tbl.print(gem_list,"gem_list =================  ")
		for i = 1,#gem_list do
			local gem_item = gem_list[i]
			local gem_tp = tpgem[gem_item.tpltid][1]
			if not gem_tp then
				return SERR_ERROR_LABEL
			end
			local hole_pos = set_hole_gem(0,item.info.hole,gem_item.tpltid)
			itemop.remove_bypos(bag_package,gem_item.pos, 1)
			if v.bag_type == BAG_EQUIP then
				if v.pos >= 1000 then 
				--	ur.cards.__card.__attributes[v.pos - 1000]:compute_gem_attribute(gem_tp.Attributes,tp_gemholes,hole_pos,1)
					equip_attributes.compute_gem_attribute(ur.cards.__card.__attributes[v.pos - 1000].equip_attribute[v.equip_pos],gem_tp.Attributes,tp_gemholes,hole_pos,1)
				else
					--tbl.print(tp_gemholes,tp_gemholes)
					--tbl.print(tp_gemholes," tp_gemholes==== gem_tp.Attributes ===== "..gem_tp.Attributes.."  hole_pos === "..hole_pos.."  i == "..i.."  gem_item.tpltid === "..gem_item.tpltid)
					--ur.info.attribute:compute_gem_attribute(gem_tp.Attributes,tp_gemholes,hole_pos,1)
					equip_attributes.compute_gem_attribute(ur.attribute.equip_attribute[v.equip_pos],gem_tp.Attributes,tp_gemholes,hole_pos,1)
					itemop.update(bag, tp.equipPart)
				end
			else
				itemop.update(bag, item.pos)
			end
		end
	end
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
	if v.bag_type == BAG_EQUIP then
		if v.pos >= 1000 then 
			local pos = v.pos - 1000
			local card = card_container.get_target(ur,pos)	
			local equip = itemop.getall(card.equip)
			card.equip = equip
			ur:send(IDUM_ACKCARDINLAYGEM, {handle_type = INLAYGEM,info=card}) 	
			card.equip = ur.equip.new(BAG_MAX+card.pos,EQUIP_MAX,card.equip)
			ur:db_tagdirty(ur.DB_CARD)
			card_container.sync_partner_weapon_attribute(ur,pos)
		else
			ur:change_attribute()
			ur:send(IDUM_ACKINLAYGEM,{handle_type = INLAYGEM}) 		
		end
	else
		ur:send(IDUM_ACKINLAYGEM,{handle_type = INLAYGEM}) 
	end
end

local function uninstall_hole_gem(indx,hole)
	local function hole_info_gen()
		return {
			gemid = 0,
			pos = 2,
		}
	end
	local item_list = {}
	for i = 1,#hole do
		if indx ~= 0 then
			if hole[i].indx == indx then
				if hole[i].gemid ~= 0 and hole[i].state == 1 then
					local gem_info = hole_info_gen()
					gem_info.gemid = hole[i].gemid
					gem_info.pos = indx
					item_list[#item_list + 1] = gem_info
					hole[i].gemid = 0
				end
			end
		else
			if hole[i].gemid ~= 0 and hole[i].state == 1 then
				local gem_info = hole_info_gen()
				gem_info.gemid = hole[i].gemid
				gem_info.pos = hole[i].indx
				item_list[#item_list + 1] = gem_info
				hole[i].gemid = 0
			end
		end
	end
	return item_list
end

REQ[IDUM_REQUNINSTALLGEM] = function(ur, v)
	local bag_package = ur:getbag(BAG_MAT)
	local bag = ur:getbag(v.bag_type)
	if v.pos >= 1000 then
		local pos = v.pos - 1000
		local card = card_container.get_target(ur,pos)
		bag = card.equip
	end
	if not bag then
		return SERR_TYPE_ERROR
	end
	local item = itemop.get(bag,v.equip_pos)
	if not item then
		return SERR_ITEM_NOT_EXIST
	end
	local tp = tpitem[item.tpltid]
	if not tp then
		return SERR_ERROR_LABEL
	end 
	if tp.itemType ~= ITEM_EQUIP then
		return 
	end
	local tp_gemholes = tpgemholes[tp.canPunch]
	if not tp_gemholes then
		return SERR_ERROR_LABEL
	end
	local item_list = {}
	if v.uninstall_type == 1 then
		item_list = uninstall_hole_gem(v.hole_pos,item.info.hole)
	else
		item_list = uninstall_hole_gem(0,item.info.hole)
	end
	for i = 1,#item_list do
		itemop.gain(ur, item_list[i].gemid , 1)
		if v.bag_type == BAG_EQUIP then
			local gem_tp = tpgem[item_list[i].gemid][1]
			if not gem_tp then
				return SERR_ERROR_LABEL
			end
			if v.pos >= 1000 then 
				--ur.cards.__card.__attributes[v.pos - 1000]:compute_gem_attribute(gem_tp.Attributes,tp_gemholes,item_list[i].pos,-1)
				equip_attributes.compute_gem_attribute(ur.cards.__card.__attributes[v.pos - 1000].equip_attribute[v.equip_pos],gem_tp.Attributes,tp_gemholes,item_list[i].pos,-1)
			else
				equip_attributes.compute_gem_attribute(ur.attribute.equip_attribute[v.equip_pos],gem_tp.Attributes,tp_gemholes,item_list[i].pos,-1)
				--ur.info.attribute:compute_gem_attribute(gem_tp.Attributes,tp_gemholes,item_list[i].pos,-1)
				itemop.update(bag, tp.equipPart)
			end
		else
			itemop.update(bag, item.pos)
		end
	end
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
	if v.bag_type == BAG_EQUIP then
		if v.pos >= 1000 then 
			local pos = v.pos - 1000
			local card = card_container.get_target(ur,pos)	
			local equip = itemop.getall(card.equip)
			card.equip = equip
			ur:send(IDUM_ACKCARDINLAYGEM, {handle_type = UNINSTALLGEM,info=card}) 	
			card.equip = ur.equip.new(BAG_MAX+card.pos,EQUIP_MAX,card.equip)
			ur:db_tagdirty(ur.DB_CARD)
			card_container.sync_partner_weapon_attribute(ur,pos)
		else
			ur:change_attribute()
			ur:send(IDUM_ACKINLAYGEM,{handle_type = UNINSTALLGEM}) 
		end
	else
		ur:send(IDUM_ACKINLAYGEM,{handle_type = UNINSTALLGEM}) 
	end
	
end

REQ[IDUM_REQUSEOPENGEMPOS] = function(ur,v)
	local bag_package = ur:getbag(BAG_MAT)
	local bag = ur:getbag(v.bag_type)
	if v.pos >= 1000 then
		local pos = v.pos - 1000
		local card = card_container.get_target(ur,pos)
		bag = card.equip
	end
	if not bag then
		return SERR_TYPE_ERROR
	end
	local item = itemop.get(bag,v.equip_pos)
	if not item then
		return SERR_ITEM_NOT_EXIST
	end
	local tp = tpitem[item.tpltid]
	if not tp then
		return SERR_ERROR_LABEL
	end 
	if tp.itemType ~= ITEM_EQUIP then
		return 
	end
	if tp.canPunch == 0 then
		return SERR_NOT_OPEN_GEMPOS
	end
	local open_item = itemop.get(bag_package,v.item_pos)
	if not open_item then
		return SERR_ITEM_NOT_EXIST
	end
	local open_tp = tpitem[open_item.tpltid]
	if not open_tp then
		return SERR_ERROR_LABEL
	end
	if v.hole_pos ~= open_tp.location then
		return SERR_OPEN_GEMPOS_NOT_ENOUG
	end
	if tp.equipPart == EQUIP_WEAPON then
		if open_tp.punchtype ~= 0 then
			return SERR_OPEN_GEMPOS_NOT_ENOUG
		end
	else
		if open_tp.punchtype == 0 then
			return SERR_OPEN_GEMPOS_NOT_ENOUG
		end
	end
	--tbl.print(item,"item ==== ")
	local hole = item.info.hole
	for i = 1,#hole do
		if hole[i].indx == v.hole_pos then
			if hole[i].state == 1 then
				return SERR_OPEN_GEM_POS_ALREADY
			else
				hole[i].state = 1
				break
			end
		end
	end
	itemop.remove_bypos(bag_package,v.item_pos, 1)
	if v.bag_type == BAG_EQUIP then
		if v.pos >= 1000 then 
			local pos = v.pos - 1000
			local card = card_container.get_target(ur,pos)	
			local equip = itemop.getall(card.equip)
			card.equip = equip
			ur:send(IDUM_ACKCARDINLAYGEM, {handle_type = OPENGEMPOS,info=card}) 	
			card.equip = ur.equip.new(BAG_MAX+card.pos,EQUIP_MAX,card.equip)
			ur:db_tagdirty(ur.DB_CARD)
		else
			itemop.update(bag, tp.equipPart)
		end
	else
		itemop.update(bag, v.equip_pos)
	end
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
	ur:send(IDUM_ACKUSEOPENGEMPOS, {result = 1}) 	
end

local function additional_attribute_gen()
	return {
		attribute_type = 0,
		attribute_value = 0,
		attribute_indx = 0,
	}
end
local function set_former_addition(ur,target)
	ur.addition = {}
	for i = 1,#target.info.addition do
		local addition = target.info.addition[i]
		local addition_info = additional_attribute_gen()
		addition_info.attribute_type = addition.attribute_type
		addition_info.attribute_value = addition.attribute_value
		addition_info.attribute_indx = addition.attribute_indx
		ur.addition[#ur.addition + 1] = addition_info
	end
end

REQ[IDUM_REQWASHATTRIBUTE] = function(ur, v)
	local bag = ur:getbag(v.bag_type)
	if v.pos >= 1000 then
		local pos = v.pos - 1000
		local card = card_container.get_target(ur,pos)
		bag = card.equip
	end
	if not bag then
		return SERR_TYPE_ERROR
	end
	if v.wash_type == 1 then
		if ur:get_vip_value(VIP_GOLD_WASH_T) == 0 then
			return SERR_VIP_LEVEL_NOT_ENOUGH
		end
	end
	local num = #v.lock_indx
	local gold_take = 0
	if num >=1 then
		gold_take = 50 * 2^(num - 1)
		if not ur:gold_enough(gold_take) then
			return SERR_GOLD_NOT_ENOUGH
		end
	end
	local tp = tpwashprice[v.wash_type]
	if not tp then
		return SERR_ERROR_LABEL
	end
	local item = itemop.get(bag,v.target_pos)
	if not item then
		return SERR_ITEM_NOT_EXIST
	end
	local tp_item = tpitem[item.tpltid]
	local value = 0
	if tp.Level == 1 then
		value = tp.Value * tp_item.level
	else
		value = tp.Value
	end
	if tp.Price == 1 then
		if not ur:gold_take(gold_take + value) then
			return SERR_GOLD_NOT_ENOUGH
		end
	else 
		if not ur:coin_take(value) then
			return SERR_COIN_NOT_ENOUGH
		end
		ur:gold_take(gold_take)
	end
	--ur.addition = item.info.addition
	set_former_addition(ur,item)
	--tbl.print(tp,"_tpwashprice === ")
	itemop.wash_equip_attribute(ur,v.lock_indx,item,tp)
	--tbl.print(item,"addition ==== ")
	if v.bag_type == BAG_EQUIP then
		if v.pos >= 1000 then 
			local pos = v.pos - 1000
			local card = card_container.get_target(ur,pos)	
			local equip = itemop.getall(card.equip)
			card.equip = equip
			ur:send(IDUM_ACKCARDINLAYGEM, {handle_type = EQUIP_WASH,info=card}) 	
			card.equip = ur.equip.new(BAG_MAX+card.pos,EQUIP_MAX,card.equip)
			equip_attributes.compute_hole_attribute(ur.cards.__card.__attributes[v.pos - 1000].equip_attribute[v.target_pos],ur.addition,-1)
			equip_attributes.compute_hole_attribute(ur.cards.__card.__attributes[v.pos - 1000].equip_attribute[v.target_pos],item.info.addition,1)
			card_container.sync_partner_weapon_attribute(ur,pos)
			ur:db_tagdirty(ur.DB_CARD)
		else
			itemop.update(bag,v.target_pos)
			equip_attributes.compute_hole_attribute(ur.attribute.equip_attribute[v.target_pos],ur.addition,-1)
			equip_attributes.compute_hole_attribute(ur.attribute.equip_attribute[v.target_pos],item.info.addition,1)
			ur:change_attribute()
		end
	else
		itemop.update(bag,v.target_pos)
	end
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
	ur:db_tagdirty(ur.DB_ROLE)
	ur:sync_role_data()
	task.change_task_progress(ur,60,1,1)
	task.refresh_toclient(ur, 60)
	ur:send(IDUM_ACKEQUIPOPERATE, {operate_type = WASH_MONEY_T})
end

REQ[IDUM_REQMATERIALWASHATTRIBUTE] = function(ur, v)
	local bag_package = ur:getbag(BAG_MAT)
	local bag = ur:getbag(v.bag_type)
	if v.pos >= 1000 then
		local pos = v.pos - 1000
		local card = card_container.get_target(ur,pos)
		bag = card.equip
	end
	if not bag then
		return SERR_TYPE_ERROR
	end
	local target_item = itemop.get(bag,v.target_pos)
	if not target_item then
		return SERR_ITEM_NOT_EXIST
	end
	local tp_item = tpitem[target_item.tpltid]
	if not tp_item then
		return
	end
	if tp_item.level < tpgamedata.Required_Level then
		return SERR_WASH_LEVEL_NOT_ENOUGH
	end
	local material_item = itemop.get(bag_package,v.material_pos)
	if not material_item then
		return SERR_ITEM_NOT_EXIST
	end
	itemop.remove_gem(material_item,ur)
	set_former_addition(ur,target_item)
	local material_index = itemop.material_wash_equip(ur,target_item,material_item,v.target_indx)
	itemop.remove_bypos(bag_package,v.material_pos, 1)
	if v.bag_type == BAG_EQUIP then
		if v.pos >= 1000 then 
			local pos = v.pos - 1000
			local card = card_container.get_target(ur,pos)	
			local equip = itemop.getall(card.equip)
			card.equip = equip
			ur:send(IDUM_ACKCARDINLAYGEM, {handle_type = EQUIP_WASH,info=card}) 	
			card.equip = ur.equip.new(BAG_MAX+card.pos,EQUIP_MAX,card.equip)
			equip_attributes.compute_hole_attribute(ur.cards.__card.__attributes[v.pos - 1000].equip_attribute[v.target_pos],ur.addition,-1)
			equip_attributes.compute_hole_attribute(ur.cards.__card.__attributes[v.pos - 1000].equip_attribute[v.target_pos],item.info.addition,1)
			card_container.sync_partner_weapon_attribute(ur,pos)
			ur:db_tagdirty(ur.DB_CARD)
		else
			equip_attributes.compute_hole_attribute(ur.attribute.equip_attribute[v.target_pos],ur.addition,-1)
			equip_attributes.compute_hole_attribute(ur.attribute.equip_attribute[v.target_pos],target_item.info.addition,1)
			ur:change_attribute()
			itemop.update(bag,v.target_pos)
		end
	else
		itemop.update(bag,v.target_pos)
	end
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
	ur:db_tagdirty(ur.DB_ROLE)
	ur:sync_role_data()
	task.change_task_progress(ur,60,1,1)
	task.refresh_toclient(ur, 60)
	--tbl.print(target_item,"-----------------------------------------------------------------info.addition ============ "..v.target_pos)
	ur:send(IDUM_ACKEQUIPOPERATE, {operate_type = WASH_MATERIAL_T,material_indx = material_index})
	--tbl.print(ur.equip,"--------------- ur.equip ===== ")
end

REQ[IDUM_REQREPLYATTRIBUTE] = function(ur, v) --IDUM_REQREPLYATTRIBUTE
	local bag_package = ur:getbag(BAG_MAT)
	local bag = ur:getbag(v.bag_type)
	if v.pos >= 1000 then
		local pos = v.pos - 1000
		local card = card_container.get_target(ur,pos)
		bag = card.equip
	end
	if not bag then
		return SERR_TYPE_ERROR
	end
	local target_item = itemop.get(bag,v.target_pos)
	if not target_item then
		return SERR_ITEM_NOT_EXIST
	end
	if not ur:gold_take(20) then
		return SERR_GOLD_NOT_ENOUGH
	end
	
	target_item.info.addition = ur.addition
	if v.bag_type == BAG_EQUIP then
		if v.pos >= 1000 then 
			local pos = v.pos - 1000
			local card = card_container.get_target(ur,pos)	
			local equip = itemop.getall(card.equip)
			card.equip = equip
			ur:send(IDUM_ACKCARDINLAYGEM, {handle_type = EQUIP_WASH,info=card}) 	
			card.equip = ur.equip.new(BAG_MAX+card.pos,EQUIP_MAX,card.equip)
			ur:db_tagdirty(ur.DB_CARD)
		else
			itemop.update(bag,v.target_pos)
		end
	else
		itemop.update(bag,v.target_pos)
	end
	itemop.refresh(ur)
	
	ur:db_tagdirty(ur.DB_ITEM)
	ur:db_tagdirty(ur.DB_ROLE)
	ur:sync_role_data()
	ur:send(IDUM_ACKEQUIPOPERATE, {operate_type = WASH_REPLY_T})
end

return REQ
