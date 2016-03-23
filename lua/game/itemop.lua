local shaco = require "shaco"
local bag = require "bag"
local tpitem = require "__tpitem"
local math = math
local ipairs = ipairs
local tbl = require "tbl"
--local task = require "task"
local tpgodcast = require "__tpgodcast"
local tpwashopen = require "__tpwashopen"
local tpwash = require "__tpwash"
local tpwashobtain = require "__tpwashobtain"
local mail = require "mail"
local sfmt = string.format
local itemop = {}

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

local function hole_position_gen(i,state)
	return {
		state = state,
		gemid = 0,
		indx = i,
		attributes = {},
	}
end

local function  additional_attribute_gen()
	return {
		attribute_type = 0,
		attribute_value = 0,
		attribute_indx = 0,
	}
end

local function set_hole(hole_cnt,canPunch)
	local hole_list = {}
	if canPunch > 0 then
		for i = 1,4 do
			local state = 0
			if hole_cnt and i <= hole_cnt then
				state = 1
			end
			local hole = hole_position_gen(i,state)
			hole_list[#hole_list + 1] = hole
		end
	end
	return hole_list
end

local function attribute_gen(type,min,max)
	return {
		attribute_type = type,
		attribute_min = min,
		attribute_max = max,
	}
end

local function get_additional_list(tp)
	local attribute_list = {}
	local tp_wash
	for k,v in ipairs(tpwash) do
		if v.Level == tp.level and v.equipPart == tp.equipPart then
			tp_wash = v
		end
	end
	if not tp_wash then
		return attribute_list
	end
	if tp_wash.minAtk > 0 then
		local info = attribute_gen(1,tp_wash.minAtk,tp_wash.maxAtk)
		attribute_list[#attribute_list + 1] = info
	end
	if tp_wash.minDef > 0 then
		local info = attribute_gen(2,tp_wash.minDef,tp_wash.maxDef)
		attribute_list[#attribute_list + 1] = info
	end
	if tp_wash.minMagic > 0 then
		local info = attribute_gen(3,tp_wash.minMagic,tp_wash.maxMagic)
		attribute_list[#attribute_list + 1] = info
	end
	if tp_wash.minMagicDef > 0 then
		local info = attribute_gen(4,tp_wash.minMagicDef,tp_wash.maxMagicDef)
		attribute_list[#attribute_list + 1] = info
	end
	if tp_wash.minHP > 0 then
		local info = attribute_gen(5,tp_wash.minHP,tp_wash.maxHP)
		attribute_list[#attribute_list + 1] = info
	end
	if tp_wash.minAtkCrit > 0 then
		local info = attribute_gen(6,tp_wash.minAtkCrit,tp_wash.maxAtkCrit)
		attribute_list[#attribute_list + 1] = info
	end
	if tp_wash.minMagicCrit > 0 then
		local info = attribute_gen(7,tp_wash.minMagicCrit,tp_wash.maxMagicCrit)
		attribute_list[#attribute_list + 1] = info
	end
	if tp_wash.minAtkResistance > 0 then
		local info = attribute_gen(8,tp_wash.minAtkResistance,tp_wash.maxAtkResistance)
		attribute_list[#attribute_list + 1] = info
	end
	if tp_wash.minMagicResistance > 0 then
		local info = attribute_gen(9,tp_wash.minMagicResistance,tp_wash.maxMagicResistance)
		attribute_list[#attribute_list + 1] = info
	end
	if tp_wash.minBlockRate > 0 then
		local info = attribute_gen(10,tp_wash.minBlockRate,tp_wash.maxBlockRate)
		attribute_list[#attribute_list + 1] = info
	end
	if tp_wash.minDodgeRate > 0 then
		local info = attribute_gen(11,tp_wash.minDodgeRate,tp_wash.maxDodgeRate)
		attribute_list[#attribute_list + 1] = info
	end
	if tp_wash.minMPReplyRate > 0 then
		local info = attribute_gen(12,tp_wash.minMPReplyRate,tp_wash.maxMPReplyRate)
		attribute_list[#attribute_list + 1] = info
	end
	if tp_wash.minBlockData > 0 then
		local info = attribute_gen(13,tp_wash.minBlockData,tp_wash.maxBlockData)
		attribute_list[#attribute_list + 1] = info
	end
	if tp_wash.minHits > 0 then
		local info = attribute_gen(14,tp_wash.minHits,tp_wash.maxHits)
		attribute_list[#attribute_list + 1] = info
	end
	if tp_wash.minHPReply > 0 then
		local info = attribute_gen(15,tp_wash.minHPReply,tp_wash.maxHPReply)
		attribute_list[#attribute_list + 1] = info
	end
	return attribute_list
end

local function get_value(attribute)
	local total_weigh = 0
	local ratio = 0
	local value = 0
	for k,v in ipairs(tpwashobtain) do
		total_weigh = total_weigh + v.Proportion
	end
	local random_weigh = math.random(1,total_weigh)
	for k,v in ipairs(tpwashobtain) do
		local temp_weigh = 0
		temp_weigh = temp_weigh + v.Proportion
		if temp_weigh >= random_weigh then
			ratio = math.random(v.Start,v.End)
		end
	end
	return (attribute.attribute_min + (attribute.attribute_max - attribute.attribute_min)*ratio//10000)
end

local function set_addition_attr(tp,wash_cnt)
	local addition_list = {}
	local number = 0
	if wash_cnt then
		number = wash_cnt
	else
		return addition_list
	end
	
	for k,v in ipairs(tpwashopen) do
		if tp.level == v.Level and tp.equipPart == v.equipPart then
			if number > v.number then
				number = v.number
			end
			break
		end
	end
	if number > 0 then
		number = math.random(1,number)
	end
	local attribute_list = get_additional_list(tp)
	for i = 1,number do
		local indx = math.random(1,#attribute_list)
		local attribute = attribute_list[indx]
		local _type = attribute.attribute_type
		for j = 1,15 do
			if _type == j then
				local additional_attr = additional_attribute_gen()
				additional_attr.attribute_type = j
				additional_attr.attribute_value = get_value(attribute)
				additional_attr.attribute_indx = i
				addition_list[#addition_list + 1] = additional_attr
			end
		end
	end
	return addition_list
end

local function _equip_gen(tp,hole_cnt,wash_cnt)
    return {
	    itemid = tp.id,
	    level = 0,
        refinecnt = get_refine_cnt(tp.id),
		star = 0,
	    attack = math.random(tp.minAtk,tp.maxAtk),
	    defense = math.random(tp.minDef,tp.maxDef),
	    magic = math.random(tp.minMagic,tp.maxMagic),
	    magicdef = math.random(tp.minMagicDef,tp.maxMagicDef),
	    hp = math.random(tp.minHP,tp.maxHP),
	    atk_crit = math.random(tp.minAtkCrit,tp.maxAtkCrit),
	    mag_crit = math.random(tp.minMagicCrit,tp.maxMagicCrit),
	    atk_res = math.random(tp.minAtkResistance,tp.maxAtkResistance),
	    mag_res = math.random(tp.minMagicResistance,tp.maxMagicResistance),
	    block = math.random(tp.minBlockRate,tp.maxBlockRate),
	    dodge = math.random(tp.minDodgeRate,tp.maxDodgeRate),
	    mp_reply = math.random(tp.minMPReplyRate,tp.maxMPReplyRate),
	    block_value = math.random(tp.minBlockData,tp.maxBlockData),
	    hits = math.random(tp.minHits,tp.maxHits),
	    hp_reply = math.random(tp.minHPReply,tp.maxHPReply),
		mp = 0,
		hole = set_hole(hole_cnt,tp.canPunch),
		addition = set_addition_attr(tp,wash_cnt),
    }
end	

local function inititemfunc(item, tp,hole_cnt,wash_cnt)
    if tp.itemType == ITEM_EQUIP then
        item.info = _equip_gen(tp,hole_cnt,wash_cnt)
		--tbl.print(item.info.addition, "=============init item.info.addition")
    end
end

function itemop.init()
    bag.sethandler(inititemfunc)
end

local function _is_mat(tp)
	local itemType = tp.itemType
    return tp and (itemType == ITEM_MATERIAL or itemType == ITEM_PAPER or itemType == ITEM_DAZZLE or itemType == ITEM_SKILL)
end

local function compute_total_attribute(attribute)
	local total_value = 0
	if attribute then
		total_value = total_value + attribute.hp + attribute.atk + attribute.def + attribute.mag + attribute.mag_def + attribute.atk_res
					+ attribute.mag_res + attribute.atk_crit + attribute.mag_crit + attribute.hits + attribute.block + attribute.dodge
					+ attribute.hp_reply + attribute.mp_reply
	end
	return total_value
end

local function check_equip_attribute_value(ur,posv)
	local target = {}
	for i =1,#posv do
		local pos = posv[i]
		local item = ur.mat:get(pos)
		if item then
			local item_attribute = ur:compute_equip_attribute(item)
			local equip_attribute
			local tp = tpitem[item.tpltid]
			if tp and tp.equipPart == EQUIP_CLOTHES or tp.equipPart == EQUIP_HELMET or tp.equipPart == EQUIP_NECKLACE then
				local equip = ur.equip:get(tp.equipPart)
				local item_value = compute_total_attribute(item_attribute)
				if equip then
					
					equip_attribute = ur:compute_equip_attribute(equip)
					local equip_value = compute_total_attribute(equip_attribute)
					if item_value > equip_value then
						local data = {}
						data[1] = pos
						data[2] = item_value
						data[3] = item.tpltid
						target[#target + 1] = data
					end
				else
					local data = {}
					data[1] = pos
					data[2] = item_value
					data[3] = item.tpltid
					target[#target + 1] = data
					
				end
			end
			if tp and tp.equipPart == EQUIP_SHOES then
				local equip = ur.equip:get(tp.equipPart)
				if equip then
					if ur.base.race == eOccup_ZS or eOccup_QFJ then
						if item_attribute.atk_crit > equip_attribute.atk_crit then
							local data = {}
							data[1] = pos
							data[2] = item_attribute.atk_crit
							data[3] = item.tpltid
							target[#target + 1] = data
						end
					elseif ur.base.race == eOccup_QPS then
						if item_attribute.mag_crit > equip_attribute.mag_crit then
							local data = {}
							data[1] = pos
							data[2] = item_attribute.mag_crit
							data[3] = item.tpltid
							target[#target + 1] = data
						end
					end
				else
					local data = {}
					data[1] = pos
					if ur.base.race == eOccup_QPS then
						data[2] = item_attribute.mag_crit
					else
						data[2] = item_attribute.atk_crit
					end
					data[3] = item.tpltid
					target[#target + 1] = data
				end
			end
			if tp and tp.equipPart == EQUIP_BRACELET then
				local equip = ur.equip:get(tp.equipPart)
				if equip then
					if ur.base.race == eOccup_ZS or eOccup_QFJ then
						if (item_attribute.atk + item_attribute.hits) > (equip_attribute.atk + equip_attribute.hits) then
							local data = {}
							data[1] = pos
							data[2] = item_attribute.atk + item_attribute.hits
							data[3] = item.tpltid
							target[#target + 1] = data
						end
					elseif ur.base.race == eOccup_QPS then
						if (item_attribute.mag + item_attribute.hits) > (equip_attribute.mag + equip_attribute.hits) then
							local data = {}
							data[1] = pos
							data[2] = item_attribute.mag + item_attribute.hits
							data[3] = item.tpltid
							target[#target + 1] = data
						end
					end
				else
					local data = {}
					data[1] = pos
					if ur.base.race == eOccup_QPS then
						data[2] = item_attribute.mag + item_attribute.hits
					else
						data[2] = item_attribute.atk + item_attribute.hits
					end
					data[3] = item.tpltid
					target[#target + 1] = data
				end
			end
		end
	end
	local max_value = 0
	local tar_pos = 0
	local itemid = 0
	for i = 1,#target do
		local targetv = target[i]
		if max_value < targetv[2] then
			max_value = targetv[2]
			tar_pos = targetv[1]
			itemid = targetv[3]
		end
	end
	if tar_pos > 0 then
		ur:send(IDUM_NOTICEAKEYEXCHANGEEQUIP, {itemid=itemid, pos=tar_pos})
	end
end





-- 获取武器
function itemop.gain_weapon(bag, id,hole_cnt,wash_cnt)
    return bag:put_bypos(id, 1, EQUIP_WEAPON,hole_cnt,wash_cnt)
end

function itemop.gain(ur, id, num,hole_cnt,wash_cnt)
    local tp = tpitem[id]
	if not tp then
		return 0
	end
	local remain = 0
	local posv = {}
	local _hole_cnt = 0
	if hole_cnt and hole_cnt > 0 then
		_hole_cnt = math.random(0,hole_cnt)
	end
	if id == 70000005 then
        local count = ur.mat:count(id)
        count = 999-count
        if count < num then num = count end
        if count < 0 then return end
    end
	remain,posv = ur.mat:put(id, num,_hole_cnt,wash_cnt)
	ur:item_log(id,remain)
	if tp.itemType == ITEM_DAZZLE then
		local count = ur.mat:count(id)
		ur:set_task_progress(37,count,0)
	end
	if tp.itemType == ITEM_EQUIP then
		check_equip_attribute_value(ur,posv)
	end
	if num - remain > 0 then
		mail.add_new_mail(ur,id,num - remain,_hole_cnt,wash_cnt,1)
	end
	return remain
   --[[if _is_mat(tp) then
        if id == 70000005 then
            local count = ur.mat:count(id)
            count = 999-count
            if count < num then num = count end
            if count < 0 then return end
        end
		remain = ur.mat:put(id, num)
		ur:item_log(id,remain)
		if tp.itemType == ITEM_DAZZLE then
			local count = ur.mat:count(id)
			ur:set_task_progress(37,count,0)
			--task.set_task_progress(ur,37,ur.package:count(id),0)
			--task.refresh_toclient(ur, 37)
		end
        return remain
    else
		if tp.itemType == ITEM_EQUIP then
			local posv = {}
			remain,posv = ur.mat:put(id, num,_hole_cnt,wash_cnt)
			check_equip_attribute_value(ur,posv)
		else
			remain = ur.mat:put(id, num)
		end
		if num - remain > 0 then
			mail.add_new_mail(ur,id,num - remain,_hole_cnt,wash_cnt,1)
		end
		ur:item_log(id,remain)
        return remain
    end]]
end

function itemop.gain_equip(ur,id,num,hole_cnt,wash_cnt)
	local remain = ur.mat:put(id, num)
	ur:item_log(id,remain)
	hole = set_hole(hole_cnt)
end

function itemop.take(ur, id, num)
   -- local tp = tpitem[id]
   local bag = ur.mat
	local remain = 0
    --if _is_mat(tp) then
	remain = bag:remove(id, num)
	itemop.check_same_item(id,bag)
	ur:item_log(id,remain)
	return remain
  --  else
	--	remain = ur.package:remove(id, num)
	--	ur:item_log(id,remain)
     --   return remain
   -- end
end

-- dinums: { {id,num},{id,num}, ... }
function itemop.can_gain(ur, idnums)
    local idnums_pkg = {}
    for _, v in ipairs(idnums) do
    	local tp = tpitem[v[1]]
        if not _is_mat(tp) then
            idnums_pkg[#idnums_pkg+1] = v
        end
    end
    if #idnums_pkg > 0 then
        return ur.mat:space_enough(idnums_pkg)
    end
    return true
end

local function _refresh(ur, bag, innercb)
    local up_itemv = {}
    
	local function cb(item, flag)
        --if flag == 1 then --up
        if flag == 2 then --add
			if innercb then
				innercb(item)
			end
		end
        table.insert(up_itemv, item)
	end
    bag:refresh_up(cb)
    if #up_itemv > 0 then
        ur:send(IDUM_ITEMLIST, {bag_type=bag.__type, info=up_itemv})
    end
end

function itemop.refresh(ur, cb)
	_refresh(ur, ur.package, cb);
	_refresh(ur, ur.mat, cb);
	_refresh(ur, ur.equip, cb);
end

--function itemop.put(bag, id, num)
    --return bag:put(id, num)
--end

--function itemop.put_bypos(bag, id, num, pos)
    --return bag:put_bypos(id, num, pos)
--end

--function itemop.remove(bag, id, num)
    --return bag:remove(id, num)
--end

function itemop.remove_bypos(bag, pos, num)
	local remain = num
	local item = bag:get(pos)
	if item then
		local itemid = item.tpltid
		remain = bag:remove_bypos(pos, num)
		itemop.check_same_item(itemid,bag)
	end
    return remain
end

--function itemop.space(bag)
    --return bag:space()
--end

function itemop.exchange(bag1, pos1, bag2, pos2)
    local item1 = bag1:get(pos1)
    local item2 = bag2:get(pos2)
    
    if not item1 and not item2 then
        return 
    end
    if item1 then
        bag2:set(pos2, item1)
    else
        bag2:clr(pos2)
    end
    if item2 then
        bag1:set(pos1, item2)
    else
        bag1:clr(pos1)
    end
    return true
end

function itemop.move(bag1, pos1, bag2)
    local item1 = bag1:get(pos1)
    if not item1 then
        return 
    end
    local pos2  = bag2:find_slot()
    if not pos2 then
        return 
    end
    bag1:clr(pos1)
    bag2:set(pos2, item1)
    return true
end

function itemop.count(ur, id)
    local tp = tpitem[id]
	return ur.mat:count(id)
   -- if _is_mat(tp) then
      --  return ur.mat:count(id)
   -- else
    --    return ur.package:count(id)
  --  end
end

function itemop.enough(ur, id, num)
    local tp = tpitem[id]
    if _is_mat(tp) then
        return ur.mat:enough(id, num)
    else
        return ur.mat:enough(id, num)
    end
end

function itemop.get(bag, pos)
    return bag:get(pos)
end

function itemop.update(bag, pos)
    bag:update(pos)
end

function itemop.getall(bag)
    local l = {}
    for _, v in pairs(bag.__items) do
        if v.tpltid ~= 0 then
            l[#l+1] = v
        end
    end
    return l
end

function itemop.get_gem_list(bag)
	return bag:get_gem_list()
end

function itemop.get_equip_list(bag)
	return bag:get_equip_list()
end

local function get_target_addition(attribute_list,attribute_type)
	for i = 1,#attribute_list do
		local attribute = attribute_list[i]
		if attribute.attribute_type == attribute_type then
			return attribute
		end
	end
end

function itemop.wash_equip_attribute(ur,lock_indx,item,_tpwashprice)
	local tp = tpitem[item.tpltid]
	local attribute_list = get_additional_list(tp)
	for i = 1,#item.info.addition do
		local addition = item.info.addition[i]
		local flag = false
		for j = 1,#lock_indx do
			if addition.attribute_indx == lock_indx[j] then
				flag = true
				break
			end
		end
		if not flag then
			local state = 0
			local ratio = 0
			local randvalue = math.random(1,100)
			if randvalue >= 50 then
				state = 1
				ratio = math.random(1,_tpwashprice.Up)
			else
				state = 2
				ratio = math.random(1,_tpwashprice.Down)
			end
			local change_value = addition.attribute_value * ratio
			if change_value < 10000 then
				change_value = 10000
			end
			if state == 1 then --up
				addition.attribute_value = addition.attribute_value + change_value//10000
			else
				addition.attribute_value = addition.attribute_value - change_value//10000
			end
			local attribute = get_target_addition(attribute_list,addition.attribute_type)
			if attribute and addition.attribute_value < attribute.attribute_min then
				addition.attribute_value = attribute.attribute_min
			elseif attribute and addition.attribute_value > attribute.attribute_max then
				addition.attribute_value = attribute.attribute_max
			end
		end
	end
end

function itemop.material_wash_equip(ur,target_item,material_item,target_indx)
	local material_index = 0
	local flag = false
	local index = 0
	if not material_item.info.addition then 
		return material_index
	end
	for i = 1,#target_item.info.addition do
		index = index + 1
		local addition = target_item.info.addition[i]
		if addition.attribute_indx == target_indx then
			if material_item.info.addition then
				local indx = math.random(1,#material_item.info.addition)
				local material_addition = material_item.info.addition[indx]
				addition.attribute_type = material_addition.attribute_type
				addition.attribute_value = material_addition.attribute_value
				material_index = material_addition.attribute_indx
				flag = true 
				break
			end
		end
	end
	if not flag then
		if index < 4 then
			local indx = math.random(1,#material_item.info.addition)
			local material_addition = material_item.info.addition[indx]
			material_index = indx
			local additional_attr = additional_attribute_gen()
			additional_attr.attribute_type = material_addition.attribute_type
			additional_attr.attribute_value = material_addition.attribute_value
			additional_attr.attribute_indx = index + 1
			target_item.info.addition[#target_item.info.addition + 1] = additional_attr
		end
	end
	return material_index
end

function itemop.remove_gem(material_item,ur)
	for i = 1,#material_item.info.hole do
		local hole = material_item.info.hole[i]
		if hole.gemid > 0 then
			itemop.gain(ur, hole.gemid, 1)
		end
	end
end

function itemop.self_equip(ur,bag,itemid)
	local tp = tpitem[itemid]
	if tp.occup ~= 1 and (tp.occup >> ur.base.race) & 1 == 0 then
		return SERR_NOT_NEED_OCCUPATION
	end
	bag:put_bypos(itemid, 1, tp.equipPart)
end

function itemop.check_same_item(itemid,bag)
	local tp = tpitem[itemid]
	local it = 5
	--while true do
		local l = {}
		for _, v in pairs(bag.__items) do
			if v.tpltid == itemid and v.stack < tp.overLap then
				l[#l+1] = v
			end
		end
		if #l > 1 then
			local add_cnt = 0
			local one = l[1]
			for i = 2,#l do
				local item = l[i]
				local count = 0
				if (one.stack + add_cnt + item.stack) > tp.overLap then
					count = tp.overLap - one.stack - add_cnt
				else
					count = item.stack
				end
				add_cnt = add_cnt + count
				local remain = bag:remove_bypos(item.pos, count)
			end
			bag:put_bypos(itemid, add_cnt, one.pos)
		end
	--end
end

function itemop.get_other_gem_material(bag,item)
	local l = {}
	for _, v in pairs(bag.__items) do
		if v.tpltid == item.tpltid and v.pos ~= item.pos then
			l[#l+1] = v
		end
	end
	return l
end

return itemop
