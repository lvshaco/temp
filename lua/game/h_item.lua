local shaco = require "shaco"
local itemop = require "itemop"
local tpitem = require "__tpitem"
local tbl = require "tbl"
local tpgamedata = require "__tpgamedata"
local tpgift_treasure = require "__tpgift_treasure"
local card_container = require "card_container"
local club = require "club"
local sfmt = string.format
local gift_reward = require "gift_reward"
local tpgem = require "__tpgem"
local broad_cast = require "broad_cast"
local task = require "task"
local equip_attributes = require "equip_attribute"
local REQ = {}

local function check_equip_task(ur,bag)
	local blue = 0
	local violet = 0 
	local orange = 0
	local max_cnt = EQUIP_MAX
	for i =2,max_cnt do
		local item = bag:get(i)
		if item then
			local tp = tpitem[item.tpltid]
			if tp.quality >= CARD_BLUE then
				blue = blue + 1
			end
			if tp.quality >= CARD_VIOLET then
				violet = violet + 1
			end
			if tp.quality >= CARD_ORANGE then
				orange = orange + 1
			end
		end
	end
	if blue == max_cnt -1 then
		task.set_task_progress(ur,10,1,0)
		task.refresh_toclient(ur, 10)
	end
	if violet == (max_cnt - 1) then
		task.set_task_progress(ur,11,1,0)
		task.refresh_toclient(ur, 11)
	end
	if orange == (max_cnt - 1) then
		task.set_task_progress(ur,12,1,0)
		task.refresh_toclient(ur, 12)
	end
end

REQ[IDUM_EQUIP] = function(ur, v)
    local bag1 = ur:getbag(v.bag_type)
    if not bag1 then
        return
    end
    local item = itemop.get(bag1,v.pos)
	if not item then
		return SERR_ITEM_NOT_EXIST
	end
    local tp = tpitem[item.tpltid]
    if not tp then
        return
    end
	if tp.occup ~= 1 and (tp.occup >> ur.base.race) & 1 == 0 then
		return SERR_NOT_NEED_OCCUPATION
	end
    if tp.equipPart < EQUIP_WEAPON or tp.equipPart > EQUIP_BRACELET then
    	return
    end
	
    local bag2 = ur:getbag(BAG_EQUIP)
    if v.bag_type == BAG_MAT then
		local equip_item = itemop.get(bag2, tp.equipPart)
   		if itemop.exchange(bag2,tp.equipPart,bag1,v.pos) then
			if equip_item then
				ur.attribute.equip_attribute[tp.equipPart] = nil ---:remove_equip(equip_item.info,equip_item.tpltid)
			end
			ur.attribute.equip_attribute[tp.equipPart] = equip_attributes.new(item.info,item.tpltid)
			ur:change_attribute()
        	itemop.refresh(ur)
       	 	ur:db_tagdirty(ur.DB_ITEM)
			check_equip_task(ur,bag2)
    	end
    end
end

REQ[IDUM_UNEQUIP] = function(ur, v)
	local bag1 = ur:getbag(v.bag_type)
    if not bag1 then
        return
    end
    local bag2 = ur:getbag(BAG_MAT)
	local item = itemop.get(bag1,v.pos)
    local tp = tpitem[item.tpltid]
    if not tp then
        return
    end
    if itemop.move(bag1,v.pos,bag2) then
		--ur.info.attribute:equip_reduce(ur,tp.equipPart)
		ur.attribute.equip_attribute[v.pos] = nil
		--ur.attribute:compute_attribute(ur.base.race,ur.base.level)
		--ur.attribute:add_attribute(ur)
		ur:change_attribute()
    	itemop.refresh(ur)
        ur:db_tagdirty(ur.DB_ITEM)
    end
end

REQ[IDUM_ITEMSALE] = function(ur, v)
	--local itemids = {}
    local updated = false
    local got_money = 0
    local bag = ur:getbag(v.bag_type)
    for _, one in ipairs(v.posnumv) do
        local pos, count = one.int1, one.int2
        local item = itemop.get(bag, pos)
        if item then
            local tp = tpitem[item.tpltid]
            if tp then
                if count == 0 then
                    count = item.stack
                end
                local count = itemop.remove_bypos(bag, pos, count)
                if count > 0 then
                    got_money = got_money + tp.sellPrice*count
                    updated = true
                end
				--itemids[#itemids + 1] = item.tpltid
				--itemop.check_same_item(ur,item.tpltid,bag)
            end
        end
    end
    if updated then
        ur:coin_got(got_money)
        itemop.refresh(ur)
		ur:sync_role_data()
	--	itemop.check_item_stack(bag,itemids)
        ur:db_tagdirty(ur.DB_ROLE)
        ur:db_tagdirty(ur.DB_ITEM)
    end
end

REQ[IDUM_REQUSEITEM] = function(ur, v)
	local bag = ur:getbag(v.bag_type)
	 if not bag then
        return
    end
	local item = itemop.get(bag,v.pos)
	if not item then
		return
	end
	--tbl.print(v,"--------- v.item_cnt ======= ")
    if item.stack < v.item_cnt and v.item_cnt <= 0 then
        return SERR_ITEM_NOT_ENOUGH
    end
	local tp = tpitem[item.tpltid]
    if not tp then
        return
    end
	if tp.itemType == ITEM_CANUSE then
		if tp.affectType1 == AFFECT_HP then
			
		elseif tp.affectType1 == AFFECT_MP then
		
		elseif tp.affectType1 == AFFECT_PHYSICAL then
			
			local physical = ur.info.physical
			--print(" physical -===== "..physical.."  tp.affectValue1 == "..tp.affectValue1.." v.item_cnt === "..v.item_cnt)
			if physical < tpgamedata.PhysicalMax then
				physical = physical + tp.affectValue1 * v.item_cnt
				ur.info.physical = physical
				--print(" physical -===== "..physical.."  ur.info.physical == "..ur.info.physical)
			else
				return SERR_PHYSICAL_MAX
			end
		elseif tp.affectType1 == AFFECT_COIN then
			local coin = ur.info.coin
			coin = coin + tp.affectValue1 * v.item_cnt
			ur.info.coin = coin
		elseif tp.affectType1 == AFFECT_GOLD then
			local gold = ur.info.gold
			gold = gold + tp.affectValue1 * v.item_cnt
			ur.info.gold = gold
		elseif tp.affectType1 == AFFECT_BIND_GOLD then
		
		elseif tp.affectType1 == AFFECT_EXP then
			local exp = ur.info.exp
			exp = exp + tp.affectValue1 * v.item_cnt
			ur.info.exp = exp
		end
		itemop.remove_bypos(bag, v.pos, v.item_cnt)
		ur:db_tagdirty(ur.DB_ROLE)
		ur:sync_role_data()
	elseif tp.itemType == ITEM_BAG then
      --  for i = 1,v.item_cnt do
		    if #tp.items > 0 then
			    if gift_reward.get_gift_reward(ur,tp.items,v.item_cnt,1) == 1 then-- tp.items[1][1], tp.items[1][2]) == 1 then
				    return SERR_PACKAGE_SPACE_NOT_ENOUGH
			    end
        --    end
		end
		itemop.remove_bypos(bag, v.pos, v.item_cnt)
	end
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
end

REQ[IDUM_REQGEMCOMPOSE] = function(ur,v)
	local bag = ur:getbag(BAG_MAT)
	 if not bag then
        return
    end
	local item = itemop.get(bag,v.pos)
	if not item then
		return
	end
	local tp = tpgem[item.tpltid][1]
    if not tp then
        return
    end
	local gem_level = 0
	local itemid = 0
	for k,u in pairs(tpgem) do
		if u[1].Level == (tp.Level + 1) then
			itemid = u[1].ID
			gem_level = u[1].Level
		end
	end
	if itemid ==0 then
		return SERR_GEMLEVELMAX
	end
	if v.compose_type == 1 then
		if item.stack < 3 then
			local flag = false
			local material_list = itemop.get_other_gem_material(bag,item)
			for i = 1,#material_list do
				local gem_item = material_list[i]
				if gem_item.stack + item.stack >= 3 then
					flag = true
					local count = 3 - item.stack
					itemop.remove_bypos(bag, v.pos, item.stack)
					itemop.remove_bypos(bag, gem_item.pos,count)
					break
				end
			end
			if not flag then
				return SERR_GEMNUMNOTENOUGH
			end
		else
			itemop.remove_bypos(bag, v.pos, 3)
		end
		itemop.gain(ur, itemid, 1)
	elseif v.compose_type == 2 then
		local integer,decimals = math.modf(item.stack/3)
		if integer > 0 then
			itemop.remove_bypos(bag, v.pos, 3 * integer)
			itemop.gain(ur, itemid, integer)
		end
	end
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
	broad_cast.set_borad_cast(ur,gem_level,NOTICE_GEM_COMPOSE_T)
	--broad_cast.check_gem_compose(ur,gem_level)
end

local function compose_gem(ur,bag)
	local gem_list = itemop.get_gem_list(bag)
	local item_list = {}
	local index = 1
	local min_level = 0
	local min_item
	for _,u in pairs(gem_list) do
	    local item = u
		
		local tp = tpgem[item.tpltid][1]
		if tp and tp.Level < 20 then
            if min_level == 0 and item.stack >= 3 then
                min_level = tp.Level
                min_item = item
            end
		    if tp.Level < min_level and item.stack >= 3 then
				min_level = tp.Level
				min_item = item
			end
		end
    end
    if min_level > 0 then
	    local itemid = 0
	    for k,u in pairs(tpgem) do
		    if u[1].Level == (min_level + 1) then
			    itemid = u[1].ID
		    end
	    end
	    local integer,decimals = math.modf(min_item.stack/3)
	    if integer > 0 then 
		    itemop.remove_bypos(bag, min_item.pos, 3 * integer)
		    itemop.gain(ur, itemid, integer)
        end
    end
    return min_level
end

REQ[IDUM_REQONEKEYCOMPOSEALLGEM] = function(ur,v)
	local bag = ur:getbag(BAG_MAT)
    while(compose_gem(ur,bag) > 0) do
		--print("--------------------------")
    end
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
	--return ONE_KEY_COMPOSE_GEM
end

REQ[IDUM_REQONEKEYUNINSTALLGEM] = function(ur, v)
	local bag = ur:getbag(BAG_MAT)
	local equip_list = itemop.get_equip_list(bag)
	for _,u in pairs(equip_list) do
		local item = u
		if v.pos ~= item.pos and item.info.hole then
			for i = 1,#item.info.hole do
				local hole = item.info.hole[i]
				if hole.gemid > 0 then
					itemop.gain(ur,hole.gemid,1)
					hole.gemid = 0
					itemop.update(bag, item.pos)
				end	
			end
			
		end
	end
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
end

return REQ
