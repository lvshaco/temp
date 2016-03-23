-------------------interface---------------------
--function new(task, task_type, parameter1, parameter2)
--function task_accept(task,id)
------------------------------------------------------------
local shaco = require "shaco"
local warn = shaco.warn
local ipairs = ipairs
local pairs = pairs
local sfmt = string.format
local mfloor = math.floor
local mrandom = math.random
local attribute = require "attribute"
local tbl = require "tbl"
local tpitem = require "__tpitem"
local itemop = require "itemop"
local tpcardlevel = require "__tpcardlevel"
local tpgamedata = require "__tpgamedata"
local tpcard = require "__tpcard"
local tpvip = require "__tpvip"
local card_attribute = require "card_attribute"
local card_skill = require "card_skill"
local partner = require "partner"
local bag = require "bag"
local task = require "task"
local mail = require "mail"
local equip_attributes = require "equip_attribute"

local function card_gen()
    return {
        cardid=0,
        level=0,
        pos=0,
        break_through_num=0,
        card_exp=0,
        equip={},
        skills={},
    }
end



local function card_init(ur,cardv, tp, cardid, pos)
    cardv.cardid = cardid 
    cardv.pos = pos
    cardv.level = tp.level
    cardv.break_through_num = 0
    cardv.card_exp = 0
    cardv.equip = ur.equip.new(BAG_MAX+pos,EQUIP_MAX,cardv.equip)
    cardv.skills = card_skill.create_skill(cardid)
end

local UP_LOAD = 0
local UP_UP  = 1
local UP_ADD = 2

local function tag_up(self, i, flag)
    self.__flags[i] = flag
end

local function init_card(cards)
	local card = {}
	card.cards = cards
end

local card_container = {}

function card_container.new(size, cardv,ur)
    if size <= 0 then
        size = 1
    end
    
    local cards = {}
    local attribute = {}
    local flags = {}
    local partners ={}
	local own_cards = {}
   	 for k, v in ipairs(cardv.list) do
        if v.cardid == 0 then
            warn("card cardid zero")
        elseif v.pos < 0 or v.pos > size then
            warn("card pos invalid")
        else
            local temp_card = cards[v.pos+1] 
            if temp_card then
                warn("item pos repeat")
            else
                cards[v.pos] = v
                cards[v.pos].equip = ur.equip.new(BAG_MAX+v.pos,EQUIP_MAX,cards[v.pos].equip)
				--if v.cardid == 54002 then
					--tbl.print(cards[v.pos].equip, "=============init cards[v.pos].equip", shaco.trace)
				--end
                flags[v.pos] = UP_LOAD
                attribute[v.pos] = card_attribute.new(v.cardid,v.level,v.break_through_num,cards[v.pos].equip)
				attribute[v.pos]:add_attribute(cards[v.pos])
            end
        end
    end
    partners = partner.new(2,cardv.partners)
    for i=1, size do
        if not cards[i] then
            cards[i] = card_gen()
        end
    end
	--tbl.print(cardv,"cardv ====== ")
	if not cardv.own_cards or #cardv.own_cards == 0 then
		cardv.own_cards = {}
	end
	own_cards = cardv.own_cards
    local self = {
        __partner = partners,
        __card = {
        	 __cards = cards,
        	 __attributes = attribute
        	 },--init_card(cards[i]),
        __flags = flags,
		__own_cards = own_cards,
		__old_partner = {},
		sync_partner_flag = false,
    }
    setmetatable(self, card_container)
    card_container.__index = card_container
	for i = 1,#self.__partner do
		local pos = self.__partner[i].pos
		if pos then
			--print("pos ====="..pos)
			--tbl.print(self.__card.__attributes[pos],"------------- __attributes ======== ")
		end
	end
    return self
end

--剩余位置
function card_container.get_residual_position(ur) 
	local max_cnt = ur.info.cards_size
	 local n = 0
    local cards = ur.cards.__card.__cards
   
    for i =1, #cards do
    	local card = cards[i] 
    	if card.cardid ~= 0 then
    		n = n + 1
    	end
    end
	return max_cnt - n
end

function card_container.enough(ur,count)
    local max_cnt = ur.info.cards_size
    local n = 0
    local cards = ur.cards.__card.__cards
   
    for i =1, #cards do
    	local card = cards[i] 
    	if card.cardid ~= 0 then
    		n = n + 1
    	end
    end
    if n + count > max_cnt then
    	return false
    end
    return true
end

function card_container:put(ur,id,count)
	local cards_size = ur.info.cards_size
    if id <= 0  then
        return 0
    end
    local tp = tpcard[id]
    if not tp then
        return 0
    end
	local indx = 0
    local cards = self.__card.__cards
	for j =1,count do
		for i=1, #cards do
			local cardv = cards[i]
			if cardv.cardid == 0 then
				tag_up(self, i, UP_ADD)
				card_init(ur,cards[i], tp, id, i)
				self.__card.__attributes[i] = card_attribute.new(id,1,0,cards[i].equip)
				indx = j
				break
			end
		end
	end
	for i = 1,(count - indx) do
		local num = #cards + 1
		if num > cards_size then
			mail.add_new_mail(ur,id,1,0,0,CARD_TYPE)
		else
			cards[num] = card_gen()
			tag_up(self, num, UP_ADD)
			card_init(ur,cards[num], tp, id, num)
			self.__card.__attributes[num] = card_attribute.new(id,1,0,cards[num].equip)
		end
	end
	local own_cards = self.__own_cards
	local own_flag = false
	for i = 1,#own_cards do
		if own_cards[i].cardid == id then
			own_flag = true
			break
		end
	end
	if not own_flag then
		local function own_card_gen ()
			return {
				cardid = 0,
			}
		end
		local own_card_info = own_card_gen()
		own_card_info.cardid = id
		own_cards[#own_cards + 1] = own_card_info
	end
	--[[task.set_task_progress(ur,4,#own_cards,0)
	task.refresh_toclient(ur, 4)
	local violet_cards = {}
	local orange_cards = {}
	for i =1, #own_cards do
		local card_table =  tpcard[own_cards[i].cardid]
		if not card_table then
			shaco.trace(sfmt("card table is error cardid wrong cardid === %d", own_cards[i].cardid))
			return 0
		end
		if card_table.quality == CARD_VIOLET then
			violet_cards[#violet_cards + 1] = own_cards[i].cardid 
		end
		if card_table.quality == CARD_ORANGE then
			orange_cards[#orange_cards + 1] = own_cards[i].cardid 
		end
	end
	task.set_task_progress(ur,8,#violet_cards,0)
	task.refresh_toclient(ur, 8)
	task.set_task_progress(ur,9,#orange_cards,0)
	task.refresh_toclient(ur, 9)]]
    return 1
end

function card_container.check_collect_task(ur,id)
	local own_cards = ur.cards.__own_cards
	local own_flag = false
	for i = 1,#own_cards do
		if own_cards[i].cardid == id then
			own_flag = true
			break
		end
	end
	if not own_flag then
		local tp =  tpcard[id]
		if not tp then
			return
		end
		task.change_task_progress(ur,4,1,1)
		task.refresh_toclient(ur, 4)
		if tp.quality == CARD_VIOLET then
			task.change_task_progress(ur,8,1,1)
			task.refresh_toclient(ur, 8)
		end
		if tp.quality == CARD_ORANGE then
			task.change_task_progress(ur,9,1,1)
			task.refresh_toclient(ur,9)
		end
	end
end

 local function refresh_up(ur,cb, ...)
    local flags = ur.cards.__flags
    local cards = ur.cards.__card.__cards
    for i, flag in pairs(flags) do
        if flag then
            local cardv = cards[i]
            if cardv then
                cb(cardv, flag, ...)
            end
            flags[i] = nil
        end
    end
end

function card_container.refresh(ur)
    --shaco.trace("cardlist refresh")
    local up_cardv = {}
    local function cb(cardv, flag)
        if flag == 1 then --up
        elseif flag == 2 then --add
        end
        table.insert(up_cardv, cardv)
    end
    refresh_up(ur,cb)
    if #up_cardv > 0 then
    	local cards = {}
    	cards = card_container.get_card_container(up_cardv)
        ur:send(IDUM_CARDLIST, {info=up_cardv})
        for i=1, #cards do
			
 			cards[i].equip = ur.equip.new(BAG_MAX+cards[i].pos,EQUIP_MAX,cards[i].equip)
			
 		end
		
		ur.refesh_ladder = 2
    end
end

function card_container.get_target(ur,pos)
	local cards = ur.cards.__card.__cards
	for i=1, #cards do
		local card = cards[i]
		if card.pos == pos then
			return card,i
		end
	end
	return nil
end

function card_container.equip(ur,target_pos,item_pos)
	local card = card_container.get_target(ur,target_pos)
	if not card then
		return false
	end
	
	local item = itemop.get(ur.mat,item_pos)
	if not item  then
		return false
	end
	local tp = tpitem[item.tpltid]
	if not tp then
		return
	end
	return itemop.exchange(card.equip,tp.equipPart,ur.mat,item_pos)
end

function card_container.getall(card)
    local l = {}
    for _, v in pairs(card.equip.__items) do
        if v.tpltid ~= 0 then
            l[#l+1] = v
        end
    end
    return l
end

function card_container.get_card_container(cards)
	local cardv = {}
	for i =1,#cards do
		if cards[i].cardid ~= 0 then
			local equip = {}
			equip = itemop.getall(cards[i].equip)
			cardv[#cardv + 1] = cards[i]
			cardv[#cardv].equip = equip
			 
		end
	end
	return cardv
end

 function card_container.set_equip(ur)
 	local cards = ur.cards.__card.__cards
 	for i=1, #cards do
 		cards[i].equip = bag.new(BAG_MAX+cards[i].pos,EQUIP_MAX,cards[i].equip)
 	end
 end

function card_container:clearcard()
	local cards = self.__card.__cards 
	for i = 1,#cards do 
		local card = cards[i]
		if card.cardid ~= 0 then
			card = card_gen()
			card.pos = i
			cards[i] = card
			tag_up(self, i, UP_UP)
		end
	end
	local partners = self.__partner
	for i =1,2 do
		partners[i].pos = 0
		partners[i].pos_idx = 0
	end
end

function card_container:remove(pos)
	local cards = self.__card.__cards 
	for i = 1,#cards do 
		local card = cards[i]
		if card.cardid ~= 0  and card.pos == pos then
			card = card_gen()
			card.pos = pos
			cards[i] = card
			tag_up(self, i, UP_UP)
		end
	end
	for i = 1,#self.__old_partner do
		if self.__old_partner[i] == pos then
			self.__old_partner[i] = 0
		end
	end
end

function card_container.check_have_equip(card) --weapon except
	local items = card.equip.__items
	if not items then
		return false
	end
	 for _, v in pairs(items) do
        if v.tpltid ~= 0 and v.pos ~= 1 then
            return true
        end
    end
    return false
end

function card_container.card_up_level(ur,v)
	local add_exp = 0
	local materialv = v.material
	for i = 1,#materialv do
		if materialv[i].cardid ~= 0 then
			local card = card_container.get_target(ur,materialv[i].pos)
			if not card then
				return add_exp
			end
			if card_container.check_have_equip(card) == true then
				return add_exp
			end
		end
	end
	for i = 1,#materialv do
		if materialv[i].cardid ~= 0 then
			local card = card_container.get_target(ur,materialv[i].pos)
			ur.cards:remove(materialv[i].pos)
			local tp = tpcard[materialv[i].cardid]
			if tp then
				add_exp = add_exp + tp.eatExp + tp.eatLevelExp * card.level
			else
			end
		end
	end
	return add_exp
end

local function get_max_exp(level,quality)
	local max_exp = 0
	local tp = tpcardlevel[level + 1]
	if quality == 1 then
		max_exp = tp.White
	elseif quality == 2 then
		max_exp = tp.Green
	elseif quality == 3 then
		max_exp = tp.Blue
	elseif quality == 4 then
		max_exp = tp.Purple
	elseif quality == 5 then
		max_exp = tp.Orange
	end
	return max_exp
end

local function get_exp_level(role_level,level,quality,addexp,exp,maxLevel,flag)
	local reduce_flag = flag
	local max_exp = get_max_exp(level,quality)
	if level > role_level and reduce_flag == 0 then
		addexp = addexp // 10
		reduce_flag = 1
	end
	local temp_exp = exp + addexp - max_exp
	if temp_exp < 0 then
		exp = addexp + exp
	else
		if level >= maxLevel then
			exp = addexp + exp
		else
			level = level + 1
			level,exp = get_exp_level(role_level,level,quality,temp_exp,0,maxLevel,reduce_flag)
		end
	end
	return level,exp
end

function card_container.set_exp(ur,card,addexp,indx)
	local flag = false
	local role_level = ur.base.level
	local old_level = card.level
	local tp = tpcard[card.cardid]
	if not tp then
		return false
	end
	local maxLevel = tp.maxLevel + tp.breakthroughEffect * card.break_through_num
	local level,exp = get_exp_level(role_level,card.level,tp.quality,addexp,card.card_exp,maxLevel,0)
	if level > card.level then
		flag = true
		--compute_role_attribute(ur,card.pos)
	end
	card.level = level
	card.card_exp = exp
	tag_up(ur.cards, indx, UP_UP)
	ur.cards.__card.__attributes[card.pos]:level_up_compute(card.cardid,level- old_level)
	return flag
end

local function compute_beyond_exp(role_level,level,quality,exp,maxLevel)
	local max_exp = get_max_exp(level,quality)
	local temp_exp = exp - max_exp
	if temp_exp > 0 then
		level = level + 1
		level,exp = compute_beyond_exp(role_level,level,quality,temp_exp,maxLevel)
	end
	return level,exp
end

function card_container.set_beyond_exp(ur,card) 
	local role_level = ur.base.level
	local tp = tpcard[card.cardid]
	if not tp then
		return false
	end
	local maxLevel = tp.maxLevel + tp.breakthroughEffect * card.break_through_num
	local level,exp = compute_beyond_exp(role_level,card.level,tp.quality,card.card_exp,maxLevel)
	card.level = level
	card.card_exp = exp
end

function card_container:get(pos)
	local card = {}
	local cards = self.__card.__cards 
	for i = 1,#cards do 
		card = cards[i]
		if card and card.pos == pos then
			break
		end
	end
	return card
end

local function _is_weapon(tp)
    return tp and tp.equipPart == EQUIP_WEAPON
end 

local function remove_item(ur,pos)
	local card = card_container.get_target(ur,pos)
end

function card_container.set_level(ur,pos,level)
	local card = card_container.get_target(ur,pos)
	local old_level = card.level
	card.level = level
	ur.cards.__card.__attributes[pos]:level_up_compute(card.cardid,level- old_level)
	ur:db_tagdirty(ur.DB_CARD)
	ur:send(IDUM_GMSETLEVEL, {info = card})
end

function card_container.set_card_level(ur,cardid,level)
	local cards = ur.cards.__card.__cards
	for i=1, #cards do
		local card = cards[i]
		if card.cardid == cardid then
			card.level = level
		end
	end
	ur:db_tagdirty(ur.DB_CARD)
end

function card_container.get_max_partner_battle(ur)
	local function partner_info()
		return {
			pos = 0,
			battle_value = 0,
		}
	end
	local partner_list = {}
	local partners = ur.cards.__partner
	for i = 1,#partners do
		local info = partner_info()
		if partners[i].pos > 0 then
			local card = card_container.get_target(ur, partners[i].pos)
			if not card then
				shaco.trace(sfmt("partner info error pos ==  %d !!! ", partners[i].pos))
			end
			info.battle_value = ur.cards.__card.__attributes[partners[i].pos]:compute_battle(card.cardid)
			info.pos = partners[i].pos
		end
		partner_list[#partner_list + 1] = info
	end
	if partner_list[1].battle_value >= partner_list[2].battle_value then
		return  partner_list[1].pos, partner_list[1].battle_value
	else
		return  partner_list[2].pos, partner_list[2].battle_value
	end	
end

local function partner_attribute_gen()
	return {
		pos = 0,
		attribute = {},
	}
end

local function check_is_own(pos,old_partner)
	for i =1,#old_partner do
		if old_partner[i] == pos then
			return true
		end
	end
	return false
end

local function attribute_gen(attribute)
	return {
     	atk=attribute.atk,
      	def=attribute.def,
    	mag=attribute.mag,
      	mag_def=attribute.mag_def,
     	hp=attribute.hp,
     	mp=0,
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

function card_container.total_card_attribute(attributev)
	local attribute = attribute_gen(attributev.attribute)
	for k,v in pairs(attributev.equip_attribute) do
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

function card_container.sync_partner_attribute(ur)
	local attribute_list = {}
	local partners = ur.cards.__partner
	for i = 1,#partners do
		if partners[i].pos > 0 then
			if not check_is_own(partners[i].pos,ur.cards.__old_partner) then
				local partner_attribute = partner_attribute_gen()
				partner_attribute.pos = partners[i].pos
				partner_attribute.attribute = card_container.total_card_attribute(ur.cards.__card.__attributes[partners[i].pos])
				attribute_list[#attribute_list + 1] = partner_attribute
			end
		end
	end
	--tbl.print(attribute_list,"------------------------   attribute_list===============  ")
	ur:send(IDUM_SYNPARTNERATTRIBUTE,{attributes = attribute_list})
end

function card_container.set_old_partner(cards,pos)
	local function old_partner_gen()
		return {
			pos = 0,
		}
	end
	local flag = false
	for i = 1,#cards.__old_partner do
		if cards.__old_partner[i] == pos then
			flag = true
		end
	end
	if not flag then
		cards.__old_partner[#cards.__old_partner + 1] = pos
	end
end

function card_container.get_partner_battle(ur)
	local partners = ur.cards.__partner
	local total_value = 0
	for i = 1,#partners do
		if partners[i].pos > 0 then
			local card = card_container.get_target(ur, partners[i].pos)
			if not card then
				shaco.trace(sfmt("partner info error pos ==  %d !!! ", partners[i].pos))
			end
			local partner_attribute = ur.cards.__card.__attributes[partners[i].pos]
			if partner_attribute then
				local battle_value = partner_attribute:compute_battle(card.cardid)
				total_value = total_value + battle_value
			else
				shaco.trace(sfmt("-partners[i].pos ==== %d--------...", partners[i].pos))
			end
		end
	end
	return total_value
end

function card_container.sync_partner_weapon_attribute(ur,pos)
	local attribute_list = {}
	local partners = ur.cards.__partner
	local flag = false
	for i = 1,#partners do
		if partners[i].pos > 0 and pos == partners[i].pos then
			--local partner_attribute = partner_attribute_gen()
		--	partner_attribute.pos = partners[i].pos
		--	partner_attribute.attribute = ur.cards.__card.__attributes[partners[i].pos]
		--	attribute_list[#attribute_list + 1] = partner_attribute
			flag = true
		end
	end
	if flag then
		ur:change_role_battle_value()
	--else
	--	local _attribute = partner_attribute_gen()
	--	_attribute.pos = pos
	--	_attribute.attribute = ur.cards.__card.__attributes[pos]
		--attribute_list[#attribute_list + 1] = _attribute
	end
	--ur:send(IDUM_SYNPARTNERATTRIBUTE,{attributes = attribute_list})
end

local function is_own_weapon(card)
	local bag = card.equip 
	if not bag then
		return false
	end
	local item = itemop.get(bag, EQUIP_WEAPON)
	if item then
		return true
	else
		return false
	end
end

local function is_partner(partners,pos)
	for i = 1,#partners do
		if partners[i].pos > 0 and partners[i].pos == pos then
			return true
		end
	end
	return false
end

local function check_card_is_partner(ur,cardid)
	local partner_flag = false
	local weapon_flag = false
	local partners = ur.cards.__partner
	local cards = ur.cards.__card.__cards
	local card_info
	for i=1, #cards do
		local card = cards[i]
		if card.cardid == cardid then
			if is_partner(partners,card.pos) then
				partner_flag = true
				if is_own_weapon(card) then
					weapon_flag = true
				end
				card_info = card
			end
		end
	end
	return partner_flag,weapon_flag,card_info
end

local function get_ideal_card(ur,cardid)
	local target_cards = {}
	local cards = ur.cards.__card.__cards
	for i=1, #cards do
		local card = cards[i]
		if card.cardid == cardid and not is_own_weapon(card) then
			target_cards[#target_cards + 1] = card
		end
	end
	--tbl.print(target_cards,"------- target_cards ===== ")
	local battle_value = 0
	local level = 0
	local target_card
	for i = 1,#target_cards do
		local value = 0
		local target = target_cards[i]
		if level < target.level then
			level = target.level
			target_card = target
		end
	end
	return target_card
end

function card_container.add_equip(ur,cardid,weaponid,hole_cnt)
	--print("cardid == "..cardid.." --- weaponid == "..weaponid)
	local partner_flag,weapon_flag,target = check_card_is_partner(ur,cardid)
	if partner_flag and weapon_flag then
		return
	end
	--print("----------------******^^^^^^^^^^^^^^")
	if not partner_flag then
		target = get_ideal_card(ur,cardid)
	end
    if not target then
        return
    end
	local bag = target.equip
	if not bag then
		return 
	end 
	local pos = target.pos
	--tbl.print(target,"--------------------   111111   ")
	itemop.gain_weapon(bag, weaponid,hole_cnt)
	card_container.sync_partner_weapon_attribute(ur,pos)
	ur:db_tagdirty(ur.DB_CARD)
end

function card_container.add_card_bag_container(ur,front_level,cur_level)
	local card_size = ur.info.cards_size
	local max_size = tpgamedata.CardBackpackMax
	if card_size >= max_size then
		return 
	end
	for i = front_level,cur_level do
		local tp = tpvip[i + 1]
		if not tp then
			return 
		end
		local cnt = tp.card_bag
		card_size = card_size + cnt
		if card_size >= max_size then
			card_size = max_size
		end
	end
	ur.info.cards_size = card_size
	ur:db_tagdirty(ur.DB_ROLE)
	ur:send(IDUM_BUYCARDSIZERESULT,{card_grid_cnt = card_size})
end

return card_container
