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

local equip_attributes = {}

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

function equip_attributes.compute_hole_attribute(self,attributev,method)
	if not attributev then
		return
	end
	for i = 1,#attributev do
		local attribute = attributev[i]
		if attribute then
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

end

function equip_attributes:equip_add(ur,pos)
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

function equip_attributes:remove_equip(equip_info,itemid)
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

function equip_attributes:equip_reduce(ur,pos)
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

function equip_attributes:dazzle_fragment_add(ur,fragment)
	local tp = get_fragment_base(fragment.fragment_pos,fragment.fragment_type,fragment.fragment_level)
	if not tp then
		return
	end
	local tp_base = get_role_attribute(ur.base.race,ur.base.level)
	if not tp_base then
		return
	end
	self.hp = self.hp + (tp.hP * tp_base.hp)//10000
	self.atk = self.atk + (tp.atk * tp_base.atk)//10000
	self.def = self.def + (tp.def * tp_base.def)//10000
	self.mag = self.mag + (tp.magic * tp_base.magic)//10000
	self.mag_def = self.mag_def + (tp.magicDef * tp_base.magicDef)//10000
	self.atk_res = self.atk_res + (tp.atkResistance * tp_base.atkResistance)//10000
	self.mag_res = self.mag_res + (tp.magicResistance * tp_base.magicResistance)//10000
	self.atk_crit = self.atk_crit + (tp.atkCrit * tp_base.atkCrit)//10000
	self.mag_crit = self.mag_crit + (tp.magicCrit * tp_base.magicCrit)//10000
end

function equip_attributes:dazzle_add(ur,dazzle_type,dazzle_level)
	for k, v in pairs(tpdazzle) do
		if v.Type == dazzle_type and v.Level == dazzle_level then
			self.hp = self.hp + v.Parameter1
			self.hp = self.hp + self.hp * v.Percent1 / 100
			self.mp = self.mp + v.Parameter2
			self.mp = self.mp + self.mp * v.Percent2 / 100
			self.atk = self.atk + v.Parameter3
			self.atk = self.atk + self.atk * v.Percent3 / 100
			self.def = self.def + v.Parameter4
			self.def = self.def + self.def * v.Percent4 / 100
			self.mag = self.mag + v.Parameter5
			self.mag = self.mag + self.mag * v.Percent5 / 100
			self.mag_def = self.mag_def + v.Parameter6
			self.mag_def = self.mag_def + self.mag_def * v.Percent6 / 100
			self.atk_res = self.atk_res + v.Parameter7
			self.atk_res = self.atk_res + self.atk_res * v.Percent7 / 100
			self.mag_res = self.mag_res + v.Parameter8
			self.mag_res = self.mag_res + self.mag_res * v.Percent8 / 100
			self.atk_crit = self.atk_crit + v.Parameter9
			self.atk_crit = self.atk_crit + self.atk_crit * v.Percent9 / 100
			self.mag_crit = self.mag_crit + v.Parameter10
			self.mag_crit = self.mag_crit + self.mag_crit * v.Percent10 / 100
		end
	end
end

function equip_attributes:dazzle_attr(ur)	
	for i =1, #ur.info.dazzles do 
		for j =1,#ur.info.dazzles[i].fragment do
			self:dazzle_fragment_add(ur,ur.info.dazzles[i].fragment[j])
		end
	end
end 

function equip_attributes:add_attribute(ur)
	for i=1,EQUIP_MAX do
		self:equip_add(ur,i)
	end
	self:passive_skill_attr(ur)
	self:dazzle_attr(ur)
end

function equip_attributes:remove_dazzle_fragment(ur,tp)
	local tp_base = get_role_attribute(ur.base.race,ur.base.level)
	if not tp_base then
		return
	end
	self.hp = self.hp - (tp.hP * tp_base.hp)//10000
	self.atk = self.atk - (tp.atk * tp_base.atk)//10000
	self.def = self.def - (tp.def * tp_base.def)//10000
	self.mag = self.mag - (tp.magic * tp_base.magic)//10000
	self.mag_def = self.mag_def - (tp.magicDef * tp_base.magicDef)//10000
	self.atk_res = self.atk_res - (tp.atkResistance * tp_base.atkResistance)//10000
	self.mag_res = self.mag_res - (tp.magicResistance * tp_base.magicResistance)//10000
	self.atk_crit = self.atk_crit - (tp.atkCrit * tp_base.atkCrit)//10000
	self.mag_crit = self.mag_crit - (tp.magicCrit * tp_base.magicCrit)//10000
end

function equip_attributes:add_dazzle_fragment(ur,tp)
	local tp_base = get_role_attribute(ur.base.race,ur.base.level)
	if not tp_base then
		return
	end
	self.hp = self.hp + (tp.hP * tp_base.hp)//10000
	self.atk = self.atk + (tp.atk * tp_base.atk)//10000
	self.def = self.def + (tp.def * tp_base.def)//10000
	self.mag = self.mag + (tp.magic * tp_base.magic)//10000
	self.mag_def = self.mag_def + (tp.magicDef * tp_base.magicDef)//10000
	self.atk_res = self.atk_res + (tp.atkResistance * tp_base.atkResistance)//10000
	self.mag_res = self.mag_res + (tp.magicResistance * tp_base.magicResistance)//10000
	self.atk_crit = self.atk_crit + (tp.atkCrit * tp_base.atkCrit)//10000
	self.mag_crit = self.mag_crit + (tp.magicCrit * tp_base.magicCrit)//10000
end

function equip_attributes:compute_attribute(race,level)
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



function equip_attributes:compute_verify()
	local verify_value = self:get_HP()/ math.max(self:get_Atk() + self:get_Mag() - self:get_Def() - self:get_MagDef(),1)
	return verify_value
end

function equip_attributes:get_battle_value(tpltid)
	local battle_value = 0
	local tp = tpcreaterole[tpltid]
	if not tp then
		return battle_value
	end
	if tp.ATK > 0 and tp.Magic > 0 then
		battle_value = floor(formula.get_CombatDouble(self, nil, nil, nil))
	elseif tp.Magic == 0 and tp.ATK > 0 then
		battle_value = floor(formula.get_CombatAtk(self, nil, nil, nil))
	elseif tp.Magic > 0 and tp.ATK == 0 then
		battle_value = floor(formula.get_CombatMagic(self, nil, nil, nil))
	end
	return battle_value
end

function equip_attributes:remove_weapon(bag,pos) 
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

local function compute_value(target_value,value)
	target_value = target_value + value
	if target_value < 0 then
		target_value = 0
	end
	return target_value
end

function equip_attributes.compute_gem_attribute(self,ratio,tpgemholes,pos,method)
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
			self.hp = compute_value(self.hp,value)
		elseif indx == 2 then
			self.mp = compute_value(self.mp,value)
		elseif indx == 3 then
			self.mp_reply = compute_value(self.mp_reply,value)
		elseif indx == 4 then
			self.atk = compute_value(self.atk,value)
		elseif indx == 5 then
			self.def = compute_value(self.def,value)
		elseif indx == 6 then
			self.mag = compute_value(self.mag,value)
		elseif indx == 7 then
			self.mag_def = compute_value(self.mag_def,value)
		elseif indx == 8 then
			self.hp_reply = compute_value(self.hp_reply,value)
		elseif indx == 9 then
			self.atk_res = compute_value(self.atk_res,value)
		elseif indx == 10 then
			self.mag_res = compute_value(self.mag_res,value)
		elseif indx == 11 then
			self.dodge = compute_value(self.dodge,value)
		elseif indx == 12 then
			self.atk_crit = compute_value(self.atk_crit,value)
		elseif indx == 13 then
			self.mag_crit = compute_value(self.mag_crit,value)
		elseif indx == 14 then
			self.block = compute_value(self.block,value)
		elseif indx == 15 then
			--格挡值
		elseif indx == 16 then
			self.hits = compute_value(self.hits,value)
		elseif indx == 17 then
			self.atk = compute_value(self.atk,value)
			self.mag = compute_value(self.mag,value)
		elseif indx == 18 then	
			self.atk_crit = compute_value(self.atk_crit,value)
			self.mag_crit = compute_value(self.mag_crit,value)
		end
	end
end

function equip_attributes.new(equip_info,tpltid)
	local self = attribute_gen()
	local tp = tpitem[tpltid]
	if not tp then
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
	if equip_info.addition then
		equip_attributes.compute_hole_attribute(self,equip_info.addition,1)
	end
	if equip_info.hole then
		for i = 1,#equip_info.hole do
			local hole = equip_info.hole[i]
			local gem_tp = tpgem[hole.gemid]
			if gem_tp then
				gem_tp = gem_tp[1]
				local tp_gemholes = tpgemholes[tp.canPunch]
				if tp_gemholes and hole.indx then
					equip_attributes.compute_gem_attribute(self,gem_tp.Attributes,tp_gemholes,hole.indx,1)
				end
			end
		end
	end
    setmetatable(self, equip_attributes)
    equip_attributes.__index = equip_attributes
	return self
end

function equip_attributes:get_Atk()
	return self.atk
end

function equip_attributes:get_Mag()
	return self.mag
end

function equip_attributes:get_Def()
	return self.def
end

function equip_attributes:get_MagDef()
	return self.mag_def
end

function equip_attributes:get_HP()
	return self.hp
end

function equip_attributes:get_MP()
	return self.mp
end

function equip_attributes:get_AtkCrit()
	return self.atk_crit
end

function equip_attributes:get_MagCrit()
	return self.mag_crit
end

function equip_attributes:get_AtkRes()
	return self.atk_res
end

function equip_attributes:get_MagRes()
	return self.mag_res
end

function equip_attributes:get_Block()
	return self.block
end

function equip_attributes:get_Dodge()
	return self.dodge
end

function equip_attributes:get_MPReply()
	return self.mp_reply
end

function equip_attributes:get_Hits()
	return self.hits
end

function equip_attributes:get_HPReply()
	return self.hp_reply
end

function equip_attributes:get_equip_battle_value(_type)
	local battle_value = 0
	if _type == 1 then
		battle_value = floor(formula.get_CombatDouble(self, nil, nil, nil))
	elseif _type == 2 then
		battle_value = floor(formula.get_CombatMagic(self, nil, nil, nil))
	elseif _type == 3 then
		battle_value = floor(formula.get_CombatAtk(self, nil, nil, nil))
	end
	return battle_value
end

function equip_attributes:weapon_intensify(rate,tp)
	self.atk = self.atk + tp.Atk*rate
    self.def = self.def + tp.Def*rate
    self.mag = self.mag + tp.Magic*rate
    self.mag_def = self.mag_def + tp.MagicDef*rate
    self.hp = self.hp + tp.HP*rate
end

function equip_attributes:weapon_godcast(starproperties)
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
function equip_attributes.compute_equip_attribute(item)
	local attribute = attribute_gen()
	local equip_info = item.info
	local tp = tpitem[item.tpltid]
	if not tp then
		return attribute
	end
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
	attribute.hp_reply = attribute.hp_reply + equip_info.hp_reply
	attribute.mp_reply = attribute.mp_reply + equip_info.mp_reply
	if equip_info.addition then
		equip_attributes.compute_hole_attribute(attribute,equip_info.addition,1)
	end
	if equip_info.hole then
		for i = 1,#equip_info.hole do
			local hole = equip_info.hole[i]
			local gem_tp = tpgem[hole.gemid]
			if gem_tp then
				gem_tp = gem_tp[1]
				local tp_gemholes = tpgemholes[tp.canPunch]
				if tp_gemholes and hole.indx then
					equip_attributes.compute_gem_attribute(attribute,gem_tp.Attributes,tp_gemholes,hole.indx,1)
				end
			end
		end
	end
	return attribute
end

return equip_attributes
