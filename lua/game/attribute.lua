local shaco = require "shaco"
local tbl = require "tbl"
local sfmt = string.format
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local tprole = require "__tprole"
local tpcard = require "__tpcard"
local tpdazzle_fragment = require "__tpdazzle_fragment"
local tpdazzle = require "__tpdazzle"
local itemop = require "itemop"
local formula = require "formula"
local bag = require "bag"
local tpequip = require "__tpequip"
local tppassiveskill = require "__tppassiveskill"
local floor = math.floor
local tpcreaterole = require "__tpcreaterole"
local tpgem = require "__tpgem"
local tpgemholes = require "__tpgemholes"
local tpitem = require "__tpitem"
local equip_attributes = require "equip_attribute"

local attributes = {}

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
		block_value = 0,
	}
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

function attributes:passive_skill_attr(ur)
	local skill = ur.info.skills
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

function attributes:change_passive_attr(tp,add,reduce)
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

function attributes:change_passive_skill_attr(skill_idx,skill_type,level)
	local front_level = level - 1
	if front_level > 0 then
		local tp = get_gift_info(skill_idx,skill_type,front_level)
		self:change_passive_attr(tp,0,1)
	end
	local tp = get_gift_info(skill_idx,skill_type,level)
	self:change_passive_attr(tp,1,0)
end
	
function attributes:compute_hole_attribute(attributev,method)
	if not attributev then
		return
	end
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

function attributes:equip_add(ur,pos)
	local bag = ur:getbag(BAG_EQUIP)
    if not bag then
        return 
    end
	local item = itemop.get(bag, pos)
	if not item then
		return
	end
	local tp = tpitem[item.tpltid]
	if not tp then
		return 
	end
	local equip_info = item.info
	if not equip_info then
		return
	end
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
	if equip_info.hole then
		for i = 1,#equip_info.hole do
			local hole = equip_info.hole[i]
			local gem_tp = tpgem[hole.gemid]
			if gem_tp then
				gem_tp = gem_tp[1]
				local tp_gemholes = tpgemholes[tp.canPunch]
				if tp_gemholes and hole.indx then
					self:compute_gem_attribute(gem_tp.Attributes,tp_gemholes,hole.indx,1)
				end
			end
		end
	end
end	

function attributes:remove_equip(ur,equip_info,itemid)
	local tp = tpitem[itemid]
	if not tp then
		return 
	end
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
	self:compute_hole_attribute(equip_info.addition,-1)
	if equip_info.hole then
		for i = 1,#equip_info.hole do
			local hole = equip_info.hole[i]
			local gem_tp = tpgem[hole.gemid]
			if gem_tp then
				gem_tp = gem_tp[1]
				local tp_gemholes = tpgemholes[tp.canPunch]
				if tp_gemholes and hole.indx then					
					self:compute_gem_attribute(gem_tp.Attributes,tp_gemholes,hole.indx,-1)
				end
			end
		end
	end
end

function attributes:equip_reduce(ur,pos)
	local bag = ur:getbag(BAG_EQUIP)
    if not bag then
        return 
    end
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

local function get_fragment_base(pos,type,level)
	for k,v in pairs(tpdazzle_fragment) do
		if v.type == type and v.Level == level and v.position == pos then
			return v
		end
	end
end

local function get_role_attribute(race,level)
	for k, v in pairs(tprole) do
		if v.occup == race and v.level == level then
			return v
		end
	end
end

function attributes:dazzle_fragment_add(ur,fragment)
	local tp = get_fragment_base(fragment.fragment_pos,fragment.fragment_type,fragment.fragment_level)
	if not tp then
		return
	end
	local tp_base = get_role_attribute(ur.base.race,ur.base.level)
	if not tp_base then
		return
	end
	self.attribute.hp = self.attribute.hp + (tp.hP * tp_base.hp)//10000
	self.attribute.atk = self.attribute.atk + (tp.atk * tp_base.atk)//10000
	self.attribute.def = self.attribute.def + (tp.def * tp_base.def)//10000
	self.attribute.mag = self.attribute.mag + (tp.magic * tp_base.magic)//10000
	self.attribute.mag_def = self.attribute.mag_def + (tp.magicDef * tp_base.magicDef)//10000
	self.attribute.atk_res = self.attribute.atk_res + (tp.atkResistance * tp_base.atkResistance)//10000
	self.attribute.mag_res = self.attribute.mag_res + (tp.magicResistance * tp_base.magicResistance)//10000
	self.attribute.atk_crit = self.attribute.atk_crit + (tp.atkCrit * tp_base.atkCrit)//10000
	self.attribute.mag_crit = self.attribute.mag_crit + (tp.magicCrit * tp_base.magicCrit)//10000
end

function attributes:dazzle_add(ur,dazzle_type,dazzle_level)
	for k, v in pairs(tpdazzle) do
		if v.Type == dazzle_type and v.Level == dazzle_level then
			self.attribute.hp = self.attribute.hp + v.Parameter1
			self.attribute.hp = self.attribute.hp + self.attribute.hp * v.Percent1 / 100
			self.attribute.mp = self.attribute.mp + v.Parameter2
			self.attribute.mp = self.attribute.mp + self.attribute.mp * v.Percent2 / 100
			self.attribute.atk = self.attribute.atk + v.Parameter3
			self.attribute.atk = self.attribute.atk + self.attribute.atk * v.Percent3 / 100
			self.attribute.def = self.attribute.def + v.Parameter4
			self.attribute.def = self.attribute.def + self.attribute.def * v.Percent4 / 100
			self.attribute.mag = self.attribute.mag + v.Parameter5
			self.attribute.mag = self.attribute.mag + self.attribute.mag * v.Percent5 / 100
			self.mag_def = self.attribute.mag_def + v.Parameter6
			self.attribute.mag_def = self.attribute.mag_def + self.attribute.mag_def * v.Percent6 / 100
			self.attribute.atk_res = self.attribute.atk_res + v.Parameter7
			self.attribute.atk_res = self.attribute.atk_res + self.attribute.atk_res * v.Percent7 / 100
			self.attribute.mag_res = self.attribute.mag_res + v.Parameter8
			self.attribute.mag_res = self.attribute.mag_res + self.mag_res * v.Percent8 / 100
			self.attribute.atk_crit = self.attribute.atk_crit + v.Parameter9
			self.attribute.atk_crit = self.attribute.atk_crit + self.attribute.atk_crit * v.Percent9 / 100
			self.attribute.mag_crit = self.attribute.mag_crit + v.Parameter10
			self.attribute.mag_crit = self.attribute.mag_crit + self.attribute.mag_crit * v.Percent10 / 100
		end
	end
end

function attributes:dazzle_attr(ur)	
	for i =1, #ur.info.dazzles do 
		for j =1,#ur.info.dazzles[i].fragment do
			self:dazzle_fragment_add(ur,ur.info.dazzles[i].fragment[j])
		end
	end
end 

function attributes:add_attribute(ur)
	--for i=1,EQUIP_MAX do
	--	self:equip_add(ur,i)
	--end
	self:passive_skill_attr(ur)
	self:dazzle_attr(ur)
end

function attributes:remove_dazzle_fragment(ur,tp)
	local tp_base = get_role_attribute(ur.base.race,ur.base.level)
	if not tp_base then
		return
	end
	self.attribute.hp = self.attribute.hp - (tp.hP * tp_base.hp)//10000
	self.attribute.atk = self.attribute.atk - (tp.atk * tp_base.atk)//10000
	self.attribute.def = self.attribute.def - (tp.def * tp_base.def)//10000
	self.attribute.mag = self.attribute.mag - (tp.magic * tp_base.magic)//10000
	self.attribute.mag_def = self.attribute.mag_def - (tp.magicDef * tp_base.magicDef)//10000
	self.attribute.atk_res = self.attribute.atk_res - (tp.atkResistance * tp_base.atkResistance)//10000
	self.attribute.mag_res = self.attribute.mag_res - (tp.magicResistance * tp_base.magicResistance)//10000
	self.attribute.atk_crit = self.attribute.atk_crit - (tp.atkCrit * tp_base.atkCrit)//10000
	self.attribute.mag_crit = self.attribute.mag_crit - (tp.magicCrit * tp_base.magicCrit)//10000
end

function attributes:add_dazzle_fragment(ur,tp)
	local tp_base = get_role_attribute(ur.base.race,ur.base.level)
	if not tp_base then
		return
	end
	self.attribute.hp = self.attribute.hp + (tp.hP * tp_base.hp)//10000
	self.attribute.atk = self.attribute.atk + (tp.atk * tp_base.atk)//10000
	self.attribute.def = self.attribute.def + (tp.def * tp_base.def)//10000
	self.attribute.mag = self.attribute.mag + (tp.magic * tp_base.magic)//10000
	self.attribute.mag_def = self.attribute.mag_def + (tp.magicDef * tp_base.magicDef)//10000
	self.attribute.atk_res = self.attribute.atk_res + (tp.atkResistance * tp_base.atkResistance)//10000
	self.attribute.mag_res = self.attribute.mag_res + (tp.magicResistance * tp_base.magicResistance)//10000
	self.attribute.atk_crit = self.attribute.atk_crit + (tp.atkCrit * tp_base.atkCrit)//10000
	self.attribute.mag_crit = self.attribute.mag_crit + (tp.magicCrit * tp_base.magicCrit)//10000
end

function attributes:compute_attribute(race,level)
	for k, v in pairs(tprole) do
		if v.occup == race and v.level == level then
			self.attribute.hp = v.hp or 0 
			self.attribute.mp = v.mp or 0
			self.attribute.atk = v.atk or 0
			self.attribute.def = v.def or 0
			self.attribute.mag = v.magic or 0
			self.attribute.mag_def = v.magicDef or 0
			self.attribute.atk_res = v.atkResistance or 0
			self.attribute.mag_res = v.magicResistance or 0
			self.attribute.atk_crit = v.atkCrit or 0
			self.attribute.mag_crit = v.magicCrit or 0
			self.attribute.hits = v.hits or 0
			self.attribute.block = v.blockRate or 0
			self.attribute.dodge = v.dodgeRate or 0
			self.attribute.hp_reply = v.HPReply or 0
			self.attribute.mp_reply = v.MPReplyRate or 0
			self.attribute.block_value = v.blockData or 0
		end
	end
end

function attributes.new(ur) --race,level)
	local race = ur.base.race
	local level = ur.base.level
	local _equip_attribute = {}
	local _attribute = attribute_gen()
	for k, v in pairs(tprole) do
		if v.occup == race and v.level == level then
			_attribute.hp = v.hp or 0
			_attribute.mp = v.mp or 0
			_attribute.atk = v.atk or 0
			_attribute.def = v.def or 0
			_attribute.mag = v.magic or 0
			_attribute.mag_def = v.magicDef or 0
			_attribute.atk_res = v.atkResistance or 0
			_attribute.mag_res = v.magicResistance or 0
			_attribute.atk_crit = v.atkCrit or 0
			_attribute.mag_crit = v.magicCrit or 0
			_attribute.hits = v.hits or 0
			_attribute.block = v.blockRate or 0
			_attribute.dodge = v.dodgeRate or 0
			_attribute.hp_reply = v.HPReply or 0 
			_attribute.mp_reply = v.MPReplyRate or 0
			_attribute.block_value = v.blockData or 0
		end
	end
	local bag = ur:getbag(BAG_EQUIP)
    if bag then
		for i = 1,EQUIP_MAX do
			local item = itemop.get(bag, i)
			if item then
				_equip_attribute[i] = equip_attributes.new(item.info,item.tpltid)
			end
		end
	end
	local self = {
		attribute = _attribute,
		equip_attribute = _equip_attribute
	}
    setmetatable(self, attributes)
    attributes.__index = attributes
	return self
end

function attributes:get_Atk()
	return self.attribute.atk
end

function attributes:get_Mag()
	return self.attribute.mag
end

function attributes:get_Def()
	return self.attribute.def
end

function attributes:get_MagDef()
	return self.attribute.mag_def
end

function attributes:get_HP()
	return self.attribute.hp
end

function attributes:get_MP()
	return self.attribute.mp
end

function attributes:get_AtkCrit()
	return self.attribute.atk_crit
end

function attributes:get_MagCrit()
	return self.attribute.mag_crit
end

function attributes:get_AtkRes()
	return self.attribute.atk_res
end

function attributes:get_MagRes()
	return self.attribute.mag_res
end

function attributes:get_Block()
	return self.attribute.block
end

function attributes:get_Dodge()
	return self.attribute.dodge
end

function attributes:get_MPReply()
	return self.attribute.mp_reply
end

function attributes:get_Hits()
	return self.attribute.hits
end

function attributes:get_HPReply()
	return self.attribute.hp_reply
end

function attributes:compute_verify()
	local verify_value = self:get_HP()/ math.max(self:get_Atk() + self:get_Mag() - self:get_Def() - self:get_MagDef(),1)
	return verify_value
end

function attributes.compute_base_battle_value()
	local self = attribute_gen()
	for k, v in pairs(tprole) do
		if v.occup == race and v.level == level then
			self.hp = v.hp or 0
			self.mp = v.mp or 0
			self.atk = v.atk or 0
			self.def = v.def or 0
			self.mag = v.magic or 0
			self.mag_def = v.magicDef or 0
			self.atk_res = v.atkResistance or 0
			self.mag_res = v.magicResistance or 0
			self.atk_crit = v.atkCrit or 0
			self.mag_crit = v.magicCrit or 0
			self.hits = v.hits or 0
			self.block = v.blockRate or 0
			self.dodge = v.dodgeRate or 0
			self.hp_reply = v.HPReply or 0 
			self.mp_reply = v.MPReplyRate or 0
			self.block_value = v.blockData or 0
		end
	end
end

function attributes:get_battle_value(tpltid)
	local battle_value = 0
	local base_battle_value = 0
	local equip_battle_value = 0
	local tp = tpcreaterole[tpltid]
	if not tp then
		return base_battle_value
	end
	local _type = 0
	if tp.ATK > 0 and tp.Magic > 0 then
		base_battle_value = floor(formula.get_CombatDouble(self, nil, nil, nil))
		_type = 1
	elseif tp.Magic == 0 and tp.ATK > 0 then
		base_battle_value = floor(formula.get_CombatAtk(self, nil, nil, nil))
		_type = 2
	elseif tp.Magic > 0 and tp.ATK == 0 then
		base_battle_value = floor(formula.get_CombatMagic(self, nil, nil, nil))
		_type = 3
	end
	for i = 1,6 do
		if self.equip_attribute[i] then
			equip_battle_value = equip_battle_value + self.equip_attribute[i]:get_equip_battle_value(_type)
			--print("i ----- ==== "..i.."  self.equip_attribute[i]:get_equip_battle_value(_type) === "..self.equip_attribute[i]:get_equip_battle_value(_type))
		end
	end
	battle_value = battle_value + base_battle_value + equip_battle_value
	return battle_value
end

function attributes:remove_weapon(bag,pos) 
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

function attributes:weapon_intensify(rate,tp)
	self.attribute.atk = self.attribute.atk + tp.Atk*rate
    self.attribute.def = self.attribute.def + tp.Def*rate
    self.attribute.mag = self.attribute.mag + tp.Magic*rate
    self.attribute.mag_def = self.attribute.mag_def + tp.MagicDef*rate
    self.attribute.hp = self.attribute.hp + tp.HP*rate
end

function attributes:weapon_godcast(starproperties)
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

local function compute_value(target_value,value)
	target_value = target_value + value
	if target_value < 0 then
		target_value = 0
	end
	return target_value
end

local function _attribute_gen(attribute)
	return {
     	atk=attribute.atk,
      	def=attribute.def,
    	mag=attribute.mag,
      	mag_def=attribute.mag_def,
     	hp=attribute.hp,
     	mp=attribute.mp,
      	atk_crit=attribute.atk_crit,
      	mag_crit=attribute.mag_crit,
      	atk_res=attribute.atk_res,
      	mag_res=attribute.mag_res,
      	block=attribute.block,
      	dodge=attribute.dodge,
      	mp_reply=attribute.mp_reply,
      	hits=attribute.hits,
      	hp_reply=attribute.hp_reply,
		block_value = 0,
	}
end

function attributes:compute_user_total_attribute()
	local attribute = _attribute_gen(self.attribute)
	for k,v in pairs(self.equip_attribute) do
		attribute.hp = attribute.hp + v.hp 
		attribute.atk = attribute.atk + v.atk
		attribute.def = attribute.def + v.def
		attribute.mag = attribute.mag + v.mag
		attribute.mag_def = attribute.mag_def + v.mag_def
		attribute.atk_res = attribute.atk_res + v.atk_res
		attribute.mag_res = attribute.mag_res + v.mag_res
		attribute.atk_crit = attribute.atk_crit + v.atk_crit
		attribute.mag_crit = attribute.mag_crit + v.mag_crit
		attribute.hits = attribute.hits + v.hits
		attribute.block = attribute.block + v.block
		attribute.dodge = attribute.dodge + v.dodge
		attribute.hp_reply = attribute.hp_reply + v.hp_reply
		attribute.mp_reply = attribute.mp_reply + v.mp_reply
	end
	return attribute
end

return attributes
