local shaco = require "shaco"
local tbl = require "tbl"
local sfmt = string.format
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local tpcard = require "__tpcard"
local itemop = require "itemop"
local tpcardbreakthrough = require "__tpcardbreakthrough"
local formula = require "formula"
local card_attribute = {}
local tppassiveskill = require "__tppassiveskill"
local tpgem = require "__tpgem"
local tpgemholes = require "__tpgemholes"
local floor = math.floor
local max = math.max
local tpitem = require "__tpitem"
local equip_attributes = require "equip_attribute"

local function attribute_gen()
	return {
     	atk=0,
      	def=0,
    	mag=0,
      	mag_def=0,
     	hp=0,
     	mp=0,
      	atk_crit=0,
      	mag_crit=0,
      	atk_res=0,
      	mag_res=0,
      	block=0,
      	dodge=0,
      	mp_reply=0,
      	hits=0,
      	hp_reply=0,
	}
end

function card_attribute.new(cardid,__level,break_through_num,bag)
	--local self = attribute_gen()
	local _attribute = attribute_gen()
	local _equip_attribute = {}
	local tp = tpcard[cardid]
	if not tp then
		return
	end
	local temp_level = 0
	for k,u in pairs(tpcardbreakthrough) do
		if u.quality == tp.quality and u.breakthrough <= break_through_num  then
			temp_level = temp_level + u.level
		end
	end
	local level = __level + temp_level
	_attribute.hp = tp.hP + level * tp.hPRate
	_attribute.mp = 0
	_attribute.atk = tp.atk + level * tp.atkRate
	_attribute.def = tp.def + level * tp.defRate
	_attribute.mag = tp.magic + level * tp.magicRate
	_attribute.mag_def = tp.magicDef + level * tp.magicDefRate
	_attribute.atk_res = tp.atkResistance + level * tp.atkResistanceRate
	_attribute.mag_res = tp.magicResistance + level * tp.magicResistanceRate
	_attribute.atk_crit = tp.atkCrit + level * tp.atkCritRate
	_attribute.mag_crit = tp.magicCrit + level * tp.magicCritRate
	_attribute.hits = tp.hits + level * tp.hitsRate
	_attribute.block = tp.blockRate + level * tp.blockRateRate
	_attribute.dodge = tp.dodgeRate + level * tp.dodgeRateRate
	_attribute.hp_reply = 0
	_attribute.mp_reply = 0
	for i = 1,EQUIP_MAX do
		local item = itemop.get(bag,i)
		if item then
			_equip_attribute[i] = equip_attributes.new(item.info,item.tpltid)
		end
	end
	local self = {
		attribute = _attribute,
		equip_attribute = _equip_attribute
	}
    setmetatable(self, card_attribute)
    card_attribute.__index = card_attribute
	return self
end

local function get_gift_info(skill_idx,skill_type,level)
	local tp
	local gift_tp = tppassiveskill[skill_idx]
	if gift_tp then
		for j = 1,#gift_tp do
			local u = gift_tp[j]
			if u.skill_idx == skill_idx and u.type == skill_type and u.level == level then
				tp = u
				break
			end
		end
	end
	return tp
end

function card_attribute:passive_skill_attr(card)
	local skill = card.skills
	for i =1,#skill do
		for j =1,#skill[i].gift do
			local gift_info = skill[i].gift[j] 
			if gift_info.level > 0 then
				local tp = get_gift_info(gift_info.skill_idx,gift_info.__type,gift_info.level)
				if not tp then
					return
				end
				self.attribute.hp = self.attribute.hp + tp.hp 
				self.attribute.atk = self.attribute.atk + tp.atk
				self.attribute.def = self.attribute.def + tp.def
				self.attribute.mag = self.attribute.mag + tp.magic
				self.attribute.mag_def = self.attribute.mag_def + tp.magicDef
				self.attribute.atk_res = self.attribute.atk_res + tp.atkResistance
				self.attribute.mag_res = self.attribute.mag_res + tp.magicResistance
				self.attribute.atk_crit = self.attribute.atk_crit + tp.atkCrit
				self.attribute.mag_crit = self.attribute.mag_crit + tp.magicCrit
				self.attribute.hits = self.attribute.hits + tp.hits
				self.attribute.block = self.attribute.block + tp.blockRate
				self.attribute.dodge = self.attribute.dodge
				self.attribute.hp_reply = self.attribute.hp_reply + tp.HPReply
				self.attribute.mp_reply = self.attribute.mp_reply
			end
		end
	end
end

function card_attribute:change_passive_attr(tp,add,reduce)
	local different = add - reduce
	self.attribute.hp = self.attribute.hp + tp.hp * different
	self.attribute.atk = self.attribute.atk + tp.atk * different
	self.attribute.def = self.attribute.def + tp.def * different
	self.attribute.mag = self.attribute.mag + tp.magic * different
	self.attribute.mag_def = self.attribute.mag_def + tp.magicDef * different
	self.attribute.atk_res = self.attribute.atk_res + tp.atkResistance * different
	self.attribute.mag_res = self.attribute.mag_res + tp.magicResistance * different
	self.attribute.atk_crit = self.attribute.atk_crit + tp.atkCrit * different
	self.attribute.mag_crit = self.attribute.mag_crit + tp.magicCrit * different
	self.attribute.hits = self.attribute.hits + tp.hits * different
	self.attribute.block = self.attribute.block + tp.blockRate * different
	self.attribute.dodge = self.attribute.dodge
	self.attribute.hp_reply = self.attribute.hp_reply + tp.HPReply * different
	self.attribute.mp_reply = self.attribute.mp_reply
end

function card_attribute:change_passive_skill_attr(skill_idx,skill_type,level)
	local front_level = level - 1
	if front_level > 0 then
		local tp = get_gift_info(skill_idx,skill_type,front_level)
		self:change_passive_attr(tp,0,1)
	end
	local tp = get_gift_info(skill_idx,skill_type,level)
	self:change_passive_attr(tp,1,0)
end

function card_attribute:add_attribute(card)
	--for i=1,EQUIP_MAX do
		--self:equip_add(card.equip,i)
	--end
	self:passive_skill_attr(card)
end

function card_attribute:compute_hole_attribute(attributev,method)
	for i = 1,#attributev do
		local attribute = attributev[i]
		local _type = attribute.attribute_type
		local value = attribute.attribute_value * method
		if _type == ATK_T then
			self.atk = self.atk + value
		elseif _type == DEF_T then
			self.def = self.def + value
		elseif _type == MAGIC_T then
			self.mag = self.mag + value
		elseif _type == MAGIC_DEF_T then
			self.mag_def = self.mag_def + value
		elseif _type == HP_T then
			self.hp = self.hp + value
		elseif _type == ATK_CRTT_T then
			self.atk_crit = self.atk_crit + value
		elseif _type == MAGIC_CRTT_T then
			self.mag_crit = self.mag_crit + value
		elseif _type == ATK_RES_T then
			self.atk_res = self.atk_res + value
		elseif _type == MAGIC_RES_T then
			self.mag_res = self.mag_res + value
		elseif _type == BLOCK_RATE_T then
			self.block = self.block + value
		elseif _type == DODGE_RATE_T then
			self.dodge = self.dodge + value
		elseif _type == MP_REPLY_T then
			self.mp_reply = self.mp_reply + value
		elseif _type == BLOCK_DATA_T then
			
		elseif _type == HITS_T then
			self.hits = self.hits + value
		elseif _type == HP_REPLY_T then
			self.hp_reply = self.hp_reply + value
		end
	end
end

function card_attribute:equip_add(bag,pos)
	local item = itemop.get(bag, pos)
	if not item then
		return
	end
	local tp = tpitem[item.tpltid]
	if not tp then
		return 
	end
	local equip_info = item.info
	self.hp = self.hp + equip_info.hp 
	self.atk = self.atk + equip_info.attack
	self.def = self.def + equip_info.defense
	self.mag = self.mag + equip_info.magic
	self.mag_def = self.mag_def + equip_info.magicdef
	self.atk_res = self.atk_res + equip_info.atk_res
	self.mag_res = self.mag_res + equip_info.mag_res
	self.atk_crit = self.atk_crit + equip_info.atk_crit
	self.mag_crit = self.mag_crit + equip_info.mag_crit
	self.hits = self.hits + equip_info.hits
	self.block = self.block + equip_info.block
	self.dodge = self.dodge + equip_info.dodge
	self.hp_reply = self.hp_reply + equip_info.hp_reply
	self.mp_reply = self.mp_reply + equip_info.mp_reply
	self:compute_hole_attribute(item.info.addition,1)
	for i = 1,#equip_info.hole do
		local hole = equip_info.hole[i]
		local gem_tp = tpgem[hole.gemid]
		if gem_tp then
			gem_tp = gem_tp[1]
			local tp_gemholes = tpgemholes[tp.canPunch]
			if tp_gemholes then
				self:compute_gem_attribute(gem_tp.Attributes,tp_gemholes,hole.indx,1)
			end
		end
	end
end	

function card_attribute:equip_reduce(bag,pos)
	local item = itemop.get(bag, pos)
	if not item then
		return
	end
	local tp = tpitem[item.tpltid]
	if not tp then
		return 
	end
	local equip_info = item.info
	self.hp = self.hp - equip_info.hp 
	self.atk = self.atk - equip_info.attack
	self.def = self.def - equip_info.defense
	self.mag = self.mag - equip_info.magic
	self.mag_def = self.mag_def - equip_info.magicdef
	self.atk_res = self.atk_res - equip_info.atk_res
	self.mag_res = self.mag_res - equip_info.mag_res
	self.atk_crit = self.atk_crit - equip_info.atk_crit
	self.mag_crit = self.mag_crit - equip_info.mag_crit
	self.hits = self.hits - equip_info.hits
	self.block = self.block - equip_info.block
	self.dodge = self.dodge - equip_info.dodge
	self.hp_reply = self.hp_reply - equip_info.hp_reply
	self.mp_reply = self.mp_reply - equip_info.mp_reply
	self:compute_hole_attribute(item.info.addition,-1)
	for i = 1,#equip_info.hole do
		local hole = equip_info.hole[i]
		local gem_tp = tpgem[hole.gemid]
		if gem_tp then
			gem_tp = gem_tp[1]
			local tp_gemholes = tpgemholes[tp.canPunch]
			if tp_gemholes then
				self:compute_gem_attribute(gem_tp.Attributes,tp_gemholes,hole.indx,-1)
			end
		end
	end
end	

function card_attribute:break_through_compute(cardid,break_through_num)
	local tp = tpcard[cardid]
	if not tp then
		return
	end
	local level = 0
	for k,u in pairs(tpcardbreakthrough) do
		if u.quality == tp.quality and u.breakthrough == break_through_num  then
			level = u.level
		end
	end
    self.attribute.hp = self.attribute.hp + level * tp.hPRate
	self.attribute.mp = 0
	self.attribute.atk = self.attribute.atk + level * tp.atkRate
	self.attribute.def = self.attribute.def + level * tp.defRate
	self.attribute.mag = self.attribute.mag + level * tp.magicRate
	self.attribute.mag_def = self.attribute.mag_def + level * tp.magicDefRate
	self.attribute.atk_res = self.attribute.atk_res + level * tp.atkResistanceRate
	self.attribute.mag_res = self.attribute.mag_res + level * tp.magicResistanceRate
	self.attribute.atk_crit = self.attribute.atk_crit + level * tp.atkCritRate
	self.attribute.mag_crit = self.attribute.mag_crit + level * tp.magicCritRate
	self.attribute.hits = self.attribute.hits + level * tp.hitsRate
	self.attribute.block = self.attribute.block + level * tp.blockRateRate
	self.attribute.dodge = self.attribute.dodge + level * tp.dodgeRateRate
	self.attribute.hp_reply = self.attribute.hp_reply 
	self.attribute.mp_reply = 0
end

function card_attribute:level_up_compute(cardid,level)
	local tp = tpcard[cardid]
	if not tp then
		return
	end
	self.attribute.hp = self.attribute.hp + level * tp.hPRate
	self.mp = 0
	self.attribute.atk = self.attribute.atk + level * tp.atkRate
	self.attribute.def = self.attribute.def + level * tp.defRate
	self.attribute.mag = self.attribute.mag + level * tp.magicRate
	self.attribute.mag_def = self.attribute.mag_def + level * tp.magicDefRate
	self.attribute.atk_res = self.attribute.atk_res + level * tp.atkResistanceRate
	self.attribute.mag_res = self.attribute.mag_res + level * tp.magicResistanceRate
	self.attribute.atk_crit = self.attribute.atk_crit + level * tp.atkCritRate
	self.attribute.mag_crit = self.attribute.mag_crit + level * tp.magicCritRate
	self.attribute.hits = self.attribute.hits + level * tp.hitsRate
	self.attribute.block = self.attribute.block + level * tp.blockRateRate
	self.attribute.dodge = self.attribute.dodge + level * tp.dodgeRateRate
	self.attribute.hp_reply = self.attribute.hp_reply 
	self.mp_reply = 0
end

function card_attribute:compute_break_through(pos,cardid)
	local tp = tpcardbreakthrough[cardid]
	if not tp then
		return
	end

end

function card_attribute:get_Atk()
	return self.attribute.atk
end

function card_attribute:get_Mag()
	return self.attribute.mag
end

function card_attribute:get_Def()
	return self.attribute.def
end

function card_attribute:get_MagDef()
	return self.attribute.mag_def
end

function card_attribute:get_HP()
	return self.attribute.hp
end

function card_attribute:get_MP()
	return self.attribute.mp
end

function card_attribute:get_AtkCrit()
	return self.attribute.atk_crit
end

function card_attribute:get_MagCrit()
	return self.attribute.mag_crit
end

function card_attribute:get_AtkRes()
	return self.attribute.atk_res
end

function card_attribute:get_MagRes()
	return self.attribute.mag_res
end

function card_attribute:get_Block()
	return self.attribute.block
end

function card_attribute:get_Dodge()
	return self.attribute.dodge
end

function card_attribute:get_MPReply()
	return self.attribute.mp_reply
end

function card_attribute:get_Hits()
	return self.attribute.hits
end

function card_attribute:get_HPReply()
	return self.attribute.hp_reply
end

function card_attribute:compute_battle(cardid)
	local battle_value = 0
	local base_battle_value = 0
	local equip_battle_value = 0
	local tp = tpcard[cardid]
	if not tp then
		return battle_value
	end
	local _type = 0
	if tp.atk > 0 and tp.magic > 0 then
		base_battle_value = floor(formula.get_CombatDouble(self, nil, nil, nil))
		_type = 1
	elseif tp.atk == 0 and tp.magic > 0 then
		base_battle_value = floor(formula.get_CombatMagic(self, nil, nil, nil))
		_type = 2
	elseif tp.atk > 0 and tp.magic == 0 then
		base_battle_value = floor(formula.get_CombatAtk(self, nil, nil, nil))
		_type = 3
	end
	for i = 1,6 do
		if self.equip_attribute[i] then
			equip_battle_value = equip_battle_value + self.equip_attribute[i]:get_equip_battle_value(_type)
		end
	end
	battle_value = battle_value + base_battle_value + equip_battle_value
	return battle_value
end

function card_attribute:compute_verify()
	local verify_value = self.attribute.hp/ max(self.attribute.atk + self.attribute.mag - self.attribute.def - self.attribute.mag_def,1)
	return verify_value
end

function card_attribute:remove_weapon(bag,pos) 
	local item = itemop.get(bag, pos)
	if not item then
		return
	end
	local equip_info = item.info
	self.hp = self.hp - equip_info.hp 
	self.atk = self.atk - equip_info.attack
	self.def = self.def - equip_info.defense
	self.mag = self.mag - equip_info.magic
	self.mag_def = self.mag_def - equip_info.magicdef
	self.atk_res = self.atk_res - equip_info.atk_res
	self.mag_res = self.mag_res - equip_info.mag_res
	self.atk_crit = self.atk_crit - equip_info.atk_crit
	self.mag_crit = self.mag_crit - equip_info.mag_crit
	self.hits = self.hits - equip_info.hits
	self.block = self.block - equip_info.block
	self.dodge = self.dodge - equip_info.dodge
	self.hp_reply = self.hp_reply - equip_info.hp_reply
	self.mp_reply = self.mp_reply - equip_info.mp_reply
end

function card_attribute:weapon_intensify(rate,tp)
	self.atk = self.atk + tp.Atk*rate
    self.def = self.def + tp.Def*rate
    self.mag = self.mag + tp.Magic*rate
    self.mag_def = self.mag_def + tp.MagicDef*rate
    self.hp = self.hp + tp.HP*rate
end

function card_attribute:weapon_godcast(starproperties)
 	for i = 1, #starproperties do
		if starproperties[i][1] == 1 then
			self.hp = self.hp + starproperties[i][2]
		elseif starproperties[i][1] == 2 then
			self.mp = self.mp + starproperties[i][2]
		elseif starproperties[i][1] == 3 then
			self.mp_reply = self.mp_reply + starproperties[i][2]
		elseif starproperties[i][1] == 4 then
			self.atk = self.atk + starproperties[i][2]
		elseif starproperties[i][1] == 5 then
			self.def = self.def + starproperties[i][2]
		elseif starproperties[i][1] == 6 then
			self.mag = self.mag + starproperties[i][2]
		elseif starproperties[i][1] == 7 then
			self.mag_def = self.mag_def + starproperties[i][2]
		elseif starproperties[i][1] == 8 then
			self.hp_reply = self.hp_reply + starproperties[i][2]
		elseif starproperties[i][1] == 9 then
			self.atk_res = self.atk_res + starproperties[i][2]
		elseif starproperties[i][1] == 10 then
			self.mag_res = self.mag_res + starproperties[i][2]
		elseif starproperties[i][1] == 11 then
			self.dodge = self.dodge + starproperties[i][2]
		elseif starproperties[i][1] == 12 then
			self.atk_crit = self.atk_crit + starproperties[i][2]
		elseif starproperties[i][1] == 13 then
			self.mag_crit = self.mag_crit + starproperties[i][2]
		elseif starproperties[i][1] == 14 then
			self.block = self.block + starproperties[i][2]
		elseif starproperties[i][1] == 16 then
			self.hits = self.hits + starproperties[i][2]
		end
 	end
end

local function partner_compute_hole_attribute(attribute,attributev,method)
	for i = 1,#attributev do
		local _attribute = attributev[i]
		local _type = _attribute.attribute_type
		local value = _attribute.attribute_value * method
		if _type == ATK_T then
			attribute.atk = attribute.atk + value
		elseif _type == DEF_T then
			attribute.def = attribute.def + value
		elseif _type == MAGIC_T then
			attribute.mag = attribute.mag + value
		elseif _type == MAGIC_DEF_T then
			attribute.mag_def = attribute.mag_def + value
		elseif _type == HP_T then
			attribute.hp = attribute.hp + value
		elseif _type == ATK_CRTT_T then
			attribute.atk_crit = attribute.atk_crit + value
		elseif _type == MAGIC_CRTT_T then
			attribute.mag_crit = attribute.mag_crit + value
		elseif _type == ATK_RES_T then
			attribute.atk_res = attribute.atk_res + value
		elseif _type == MAGIC_RES_T then
			attribute.mag_res = attribute.mag_res + value
		elseif _type == BLOCK_RATE_T then
			attribute.block = attribute.block + value
		elseif _type == DODGE_RATE_T then
			attribute.dodge = attribute.dodge + value
		elseif _type == MP_REPLY_T then
			attribute.mp_reply = attribute.mp_reply + value
		elseif _type == BLOCK_DATA_T then
			
		elseif _type == HITS_T then
			attribute.hits = attribute.hits + value
		elseif _type == HP_REPLY_T then
			attribute.hp_reply = attribute.hp_reply + value
		end
	end
end


local function compute_value(target_value,value)
	target_value = target_value + value
	if target_value < 0 then
		target_value = 0
	end
	return target_value
end

local function partner_compute_gem_attribute(attribute,ratio,tpgemholes,pos,method)
	for i =1,2 do
		local indx = 0
		local value = 0
		if pos then
			indx= tpgemholes[1]["Hole"..pos.."Type"..i]
			value = tpgemholes[1]["Hole"..pos.."Value"..i] * ratio // 10000
			value = value * method
		end
		--if method > 0 then
			--print("indx ==== "..indx.."------- value  === "..value.."  i ==== "..i.."-----==== tpgemholes[1][Hole..pos.Value.i] ==== "..tpgemholes[1]["Hole"..pos.."Value"..i].."----==== ratio ===== "..ratio)
	--	end
		if indx == 1 then
			attribute.hp = compute_value(attribute.hp,value)
		elseif indx == 2 then
			attribute.mp = compute_value(attribute.mp,value)
		elseif indx == 3 then
			attribute.mp_reply = compute_value(attribute.mp_reply,value)
		elseif indx == 4 then
			attribute.atk = compute_value(attribute.atk,value)
		elseif indx == 5 then
			attribute.def = compute_value(attribute.def,value)
		elseif indx == 6 then
			attribute.mag = compute_value(attribute.mag,value)
		elseif indx == 7 then
			attribute.mag_def = compute_value(attribute.mag_def,value)
		elseif indx == 8 then
			attribute.hp_reply = compute_value(attribute.hp_reply,value)
		elseif indx == 9 then
			attribute.atk_res = compute_value(attribute.atk_res,value)
		elseif indx == 10 then
			attribute.mag_res = compute_value(attribute.mag_res,value)
		elseif indx == 11 then
			attribute.dodge = compute_value(attribute.dodge,value)
		elseif indx == 12 then
			attribute.atk_crit = compute_value(attribute.atk_crit,value)
		elseif indx == 13 then
			attribute.mag_crit = compute_value(attribute.mag_crit,value)
		elseif indx == 14 then
			attribute.block = compute_value(attribute.block,value)
		elseif indx == 15 then
			--格挡值
		elseif indx == 16 then
			attribute.hits = compute_value(attribute.hits,value)
		elseif indx == 17 then
			attribute.atk = compute_value(attribute.atk,value)
			attribute.mag = compute_value(attribute.mag,value)
		elseif indx == 18 then	
			attribute.atk_crit = compute_value(attribute.atk_crit,value)
			attribute.mag_crit = compute_value(attribute.mag_crit,value)
		end
	end
end

local function partner_compute_gem_attribute(attributev,method)
	for i = 1,#attributev do
		local attribute = attributev[i]
		local _type = attribute.attribute_type
		local value = attribute.attribute_value * method
		if _type == ATK_T then
			self.atk = self.atk + value
		elseif _type == DEF_T then
			self.def = self.def + value
		elseif _type == MAGIC_T then
			self.mag = self.mag + value
		elseif _type == MAGIC_DEF_T then
			self.mag_def = self.mag_def + value
		elseif _type == HP_T then
			self.hp = self.hp + value
		elseif _type == ATK_CRTT_T then
			self.atk_crit = self.atk_crit + value
		elseif _type == MAGIC_CRTT_T then
			self.mag_crit = self.mag_crit + value
		elseif _type == ATK_RES_T then
			self.atk_res = self.atk_res + value
		elseif _type == MAGIC_RES_T then
			self.mag_res = self.mag_res + value
		elseif _type == BLOCK_RATE_T then
			self.block = self.block + value
		elseif _type == DODGE_RATE_T then
			self.dodge = self.dodge + value
		elseif _type == MP_REPLY_T then
			self.mp_reply = self.mp_reply + value
		elseif _type == BLOCK_DATA_T then
			
		elseif _type == HITS_T then
			self.hits = self.hits + value
		elseif _type == HP_REPLY_T then
			self.hp_reply = self.hp_reply + value
		end
	end
end

local function partner_equip_add(attribute,equip)
	for i = 1,#equip do
		local equip_info = equip[i].info
		local tp = tpitem[equip_info.itemid]
		if tp then
			--tbl.print(equip_info,"equip_info =============== ")
			attribute.hp = attribute.hp + equip_info.hp 
			attribute.atk = attribute.atk + equip_info.attack
			attribute.def = attribute.def + equip_info.defense
			attribute.mag = attribute.mag + equip_info.magic
			attribute.mag_def = attribute.mag_def + equip_info.magicdef
			attribute.atk_res = attribute.atk_res + equip_info.atk_res
			attribute.mag_res = attribute.mag_res + equip_info.mag_res
			attribute.atk_crit = attribute.atk_crit + equip_info.atk_crit
			attribute.mag_crit = attribute.mag_crit + equip_info.mag_crit
			attribute.hits = attribute.hits + equip_info.hits
			attribute.block = attribute.block + equip_info.block
			attribute.dodge = attribute.dodge + equip_info.dodge
			partner_compute_hole_attribute(attribute,equip_info.addition,1)
			for j = 1,#equip_info.hole do
				local hole = equip_info.hole[j]
				local gem_tp = tpgem[hole.gemid]
				if gem_tp then
					gem_tp = gem_tp[1]
					local tp_gemholes = tpgemholes[tp.canPunch]
					if tp_gemholes then
						partner_compute_gem_attribute(attribute,gem_tp.Attributes,tp_gemholes,hole.indx,1)
					end
				end
			end
		end
	end
	return attribute
end	


local function partner_passive_skill_attr(attribute,card)
	local skill = card.skills
	for i =1,#skill do
		for j =1,#skill[i].gift do
			local gift_info = skill[i].gift[j] 
			if gift_info.level > 0 then
				local tp = get_gift_info(gift_info.skill_idx,gift_info.__type,gift_info.level)
				if not tp then
					return
				end
				attribute.hp = attribute.hp + tp.hp 
				attribute.atk = attribute.atk + tp.atk
				attribute.def = attribute.def + tp.def
				attribute.mag = attribute.mag + tp.magic
				attribute.mag_def = attribute.mag_def + tp.magicDef
				attribute.atk_res = attribute.atk_res + tp.atkResistance
				attribute.mag_res = attribute.mag_res + tp.magicResistance
				attribute.atk_crit = attribute.atk_crit + tp.atkCrit
				attribute.mag_crit = attribute.mag_crit + tp.magicCrit
				attribute.hits = attribute.hits + tp.hits
				attribute.block = attribute.block + tp.blockRate
				attribute.dodge = attribute.dodge
				attribute.hp_reply = attribute.hp_reply + tp.HPReply
				attribute.mp_reply = attribute.mp_reply
			end
		end
	end
end

function card_attribute.compute_partner_attribute(card)
	local attribute = attribute_gen()
	local tp = tpcard[card.cardid]
	if not tp then
		return
	end
	local temp_level = 0
	for k,u in pairs(tpcardbreakthrough) do
		if u.quality == tp.quality and u.breakthrough <= card.break_through_num  then
			temp_level = temp_level + u.level
		end
	end
	local level = card.level + temp_level
	attribute.hp = tp.hP + level * tp.hPRate
	attribute.mp = 0
	attribute.atk = tp.atk + level * tp.atkRate
	attribute.def = tp.def + level * tp.defRate
	attribute.mag = tp.magic + level * tp.magicRate
	attribute.mag_def = tp.magicDef + level * tp.magicDefRate
	attribute.atk_res = tp.atkResistance + level * tp.atkResistanceRate
	attribute.mag_res = tp.magicResistance + level * tp.magicResistanceRate
	attribute.atk_crit = tp.atkCrit + level * tp.atkCritRate
	attribute.mag_crit = tp.magicCrit + level * tp.magicCritRate
	attribute.hits = tp.hits + level * tp.hitsRate
	attribute.block = tp.blockRate + level * tp.blockRateRate
	attribute.dodge = tp.dodgeRate + level * tp.dodgeRateRate
	attribute.hp_reply = 0
	attribute.mp_reply = 0
	partner_equip_add(attribute,card.equip)
	partner_passive_skill_attr(attribute,card)
	return attribute
end

return card_attribute
