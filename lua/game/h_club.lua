--local shaco = require "shaco"
local shaco = require "shaco"
local pb = require "protobuf"
local tbl = require "tbl"
local sfmt = string.format
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local itemop = require "itemop"
local club = require "club"
local scene = require "scene"
local tpclub = require "__tpclub"
local tpclub_treasure = require "__tpclub_treasure"
local tpsplinter_shop = require "__tpsplinter_shop"
local tppayprice = require "__tppayprice"
local card_container = require "card_container"
local tpclub_card = require "__tpclub_card"
local task = require "task"
local tpgamedata = require "__tpgamedata"
local broad_cast = require "broad_cast"
local tpcard = require "__tpcard"
local tpitem = require "__tpitem"
local mail = require "mail"

local REQ = {}

local function dazzle_fragment_gen()
	return {
		fragmentid = 0,
	}
end

REQ[IDUM_REQ_REFRESH_CLUB] = function(ur, v)
	local open_bit = ur.info.open_bit
	if (open_bit >> FUNC_CLUB) & 1 == 0 then
		return SERR_FUNCTION_NOT_OPEN
	end
	local free_cnt = ur:get_vip_value(VIP_CLUB_REFRESH_T)
	local cnt = ur.club.club_refresh_cnt + 1
	local take = 0
	local money_tpye = 0
	if not club.check_club_state(ur) then
		return SERR_CLUB_NOT_OVER
	end
	if cnt > free_cnt then
		for k, u in pairs(tppayprice) do
			if u.type == 3 and (cnt - free_cnt)  >= u.start and (cnt - free_cnt) <= u.stop then
				take = u.number
				money_tpye = u.money_tpye
				break
			end
		end
	end
	if money_tpye == 0 then
		if ur:gold_take(take) == false then
			return SERR_GOLD_NOT_ENOUGH
		end
	end
	local club = club.refresh_club(ur,cnt)
	ur.club = club
	ur:sync_role_data()
	ur:db_tagdirty(ur.DB_ROLE)
	ur:db_tagdirty(ur.DB_CLUB)
	ur:send(IDUM_ACKRESHRESHCLUB, {info = club})
end

local function card_battle_value(cardid)
	local tp = tpclub_card[cardid]
	local battle_value = 0
	battle_value = tp.atk/10 + tp.magic/10 + tp.def/10 + tp.magicDef/10 + tp.hP/100 + tp.atkCrit/10 + tp.magicCrit/10 + tp.atkResistance/10 + tp.magicResistance/10 + tp.blockRate/10 + tp.dodgeRate/10  + tp.hits/10
				   + tp.level*(tp.hPRate/100 + tp.atkRate/10 + tp.defRate/10 + tp.magicRate/10 + tp.magicDefRate/10 + tp.atkResistanceRate/10 + tp.magicResistanceRate/10 + tp.dodgeRateRate/10 
				   + tp.atkCritRate/10 + tp.magicCritRate/10 + tp.blockRateRate/10 + tp.hitsRate/10)
	local verify_value = tp.hP/ math.max(tp.atk + tp.level*tp.atkRate + tp.magic + tp.level*tp.magicRate - (tp.def + tp.level*tp.defRate + tp.magicDef + tp.level*tp.magicDefRate),1)
	return battle_value,verify_value
end

local function get_max_value(value1,value2,value3)
	if value1 -  value2 < 0 and value1 - value3 < 0 then
		return true
	end
	return false
end

local function verify_battle(ur,clubid)
	local tp = tpclub[clubid]
	if not tp then
		return 
	end
	local oppent_value = 0
	local frist_battle,frist_oppent = card_battle_value(tp.frist_card)
	local second_battle,second_oppent = card_battle_value(tp.second_card)
	local third_battle,third_oppent = card_battle_value(tp.third_card)
	if get_max_value(frist_battle,second_battle,third_battle) then
		oppent_value = frist_oppent
	elseif get_max_value(second_battle,frist_battle,third_battle) then
		oppent_value = second_oppent
	elseif get_max_value(third_battle,second_battle,frist_battle) then
		oppent_value = third_oppent
	end
	local verify_value = ur:get_max_atrribute()
	if verify_value*1.5/oppent_value >= 1 then
		ur.battle_verify = true
	else
		ur.battle_verify = false
	end
end

REQ[IDUM_REQENTERCLUBSCENE] = function(ur, v)
	local club_info = ur.club
	local crop_state = 0
	for i=1,#club_info.crops do
		if club_info.crops[i].corpsid == v.clubid then
			crop_state = club_info.crops[i].corps_state
			break
		end
	end
	if not club.check_club_state(ur) then
		if crop_state == NOT_CHALLENGE then
			return SERR_FRONT_CHALLENGE_NOT_OVER
		end
	end
	if crop_state == OVER_CHALLENGE then
		return SERR_CLUB_ALREADY_CHALLENGE_OVER
	end
	if crop_state == NOT_CHALLENGE then
		club_info.challengecnt = club_info.challengecnt + 1
	end
	if club_info.challengecnt > tpgamedata.club_number then
		return SERR_CHALLENGE_CNT_MAX
	end
	local tp = tpclub[v.clubid]
	if not tp then
		return SERR_ERROR_LABEL
	end
	local ok = scene.enter(ur, tp.customspass)
    if ok then	
		for i=1,#club_info.crops do
			if club_info.crops[i].corpsid == v.clubid then
				if crop_state == NOT_CHALLENGE then
					crop_state = crop_state + 1
					club_info.crops[i].corps_state = crop_state
				end
				break
			end
		end
		--verify_battle(ur,v.clubid)
		ur.info.map_entertime = shaco.now()//1000;
		task.change_task_progress(ur,40,1,1)
		task.refresh_toclient(ur, 40)
		--print("club_info.challengecnt  === "..club_info.challengecnt)
		ur:send(IDUM_ACKENTERCLUBSCENE, {clubid = v.clubid,state = crop_state,challenge_cnt = club_info.challengecnt})
		ur:db_tagdirty(ur.DB_CLUB)
	end
end

REQ[IDUM_REQEXCHANGECARD] = function(ur, v)
	local tp = tpsplinter_shop[v.cardid]
	if not tp then
		return 
	end
	if card_container.enough(ur,v.card_count) == false then
		return SERR_CARD_BAG_SIZE_NOT_ENOUGH
	end
	local violet_item = 1000
	local orange_item = 2000
	local material_cnt = itemop.count(ur, v.cardid)
	local target_cnt = tp.chip_quantity[1][2] * v.card_count
	local fragment = 0
	local item_id = 0
	local flag = false
	if material_cnt >= target_cnt then
		itemop.take(ur, v.cardid, target_cnt)
		flag = true
	elseif v.buy_type == USE_OMNIPOTENT_FRAGMENT then
		if tp.quality == CARD_VIOLET then
			item_id = 1000
		elseif tp.quality == CARD_ORANGE then
			item_id = 2000
		end
		fragment = itemop.count(ur, item_id) 
		if material_cnt + fragment >= target_cnt then
			flag = true
			itemop.take(ur, v.cardid, material_cnt)
			itemop.take(ur, item_id, target_cnt - material_cnt )
		end
	end
    --shaco.debug("req card:", v.cardid, v.card_count, v.buy_type)
    --tbl.print(ur.club.card_framgent, "fragment--", shaco.debug)
	--[[local club_info = ur.club
	
	for i =1,#club_info.card_framgent do
		if club_info.card_framgent[i].card_framgent_id == tp.chip_quantity[1][1] then
			if card_container.enough(ur,v.card_count) == false then
				return SERR_CARD_BAG_SIZE_NOT_ENOUGH
			end
			if club_info.card_framgent[i].count >= tp.chip_quantity[1][2] * v.card_count then
				club_info.card_framgent[i].count = club_info.card_framgent[i].count - tp.chip_quantity[1][2] * v.card_count 
				flag = true
				break
			elseif v.buy_type == USE_OMNIPOTENT_FRAGMENT then
				if tp.quality == CARD_VIOLET then
					if club_info.card_framgent[i].count + club_info.violet_framgent >= tp.chip_quantity[1][2] * v.card_count then
						club_info.violet_framgent = club_info.card_framgent[i].count + club_info.violet_framgent - tp.chip_quantity[1][2] * v.card_count 
						club_info.card_framgent[i].count = 0
						club_info.card_framgent[i].card_framgent_id = 0
						flag = true
						break
					else
						break
					end
				elseif tp.quality == CARD_ORANGE then
					if club_info.card_framgent[i].count + club_info.orange_framgent >= tp.chip_quantity[1][2] * v.card_count then
						club_info.orange_framgent = club_info.card_framgent[i].count + club_info.orange_framgent - tp.chip_quantity[1][2] * v.card_count 
						club_info.card_framgent[i].count = 0
						club_info.card_framgent[i].card_framgent_id = 0
						flag = true
						break
					else
						break
					end
				end
			end
		end
	end]]
    --shaco.debug("card exchange flag")
	if flag == false then
		return SERR_CARD_FRAGMENT_NOT_ENOUGH
	end
    --shaco.debug("card exchange ok")
	if ur.cards:put(ur,v.cardid,v.card_count) > 0 then
		card_container.refresh(ur)
		ur:db_tagdirty(ur.DB_CARD)
		local tp = tpcard[v.cardid]
		if tp and tp.quality >= 4 and tp.quality <= 5 then
			local ids = {}
			ids[#ids + 1] = v.cardid
			broad_cast.set_borad_cast(ur,ids,NOTICE_FRAGEMENT_T)
		end
		--broad_cast.check_card_compose(ur,v.cardid)
	end
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
	--ur:db_tagdirty(ur.DB_CLUB)
	--ur:send(IDUM_ACKEXCHANGECARD, {info = club_info})
end

local function get_item(ur,lucky_draw,item_list,hole_cnt,wash_cnt)
	local total_weight = 0
	local club_treasure_list = {}
	local tp = tpclub_treasure[lucky_draw]
	for i = 1,#tp do
		local function check_exsit(item_list,item_id,count,item_type)
			for j =1,#item_list do
				if item_list[j].itemid == item_id and item_list[j].itemcnt == count and item_list[j].item_type == item_type then
					return false
				end
			end
			return true
		end
		if check_exsit(item_list,tp[i].item_id,tp[i].count,tp[i].type) then
			total_weight = total_weight + tp[i].weighing 
			club_treasure_list[#club_treasure_list + 1] = tp[i]
		end
	end
	local itemid = 0
	local itemcnt = 0
	local item_type = 0
	if total_weight >= 1 then
		local weight = 0
		local random_value = math.random(1,total_weight)
		for i = 1,#club_treasure_list do
			weight = weight + club_treasure_list[i].weighing
			if weight >= random_value then
				itemid = club_treasure_list[i].item_id
				itemcnt = club_treasure_list[i].count
				item_type = club_treasure_list[i].type
				break
			end
		end
	end
	return itemid,itemcnt,item_type
end

local function random_count(countv)
	local total_weight = 0
	local count_list = {}
	for i = 1,#countv do
		if #countv[i] > 0 then
			total_weight = total_weight + countv[i][2] 
			count_list[#count_list + 1] = countv[i]
		end
	end
	local itemcnt = 0
	if total_weight >= 1 then
		local weight = 0
		local random_value = math.random(1,total_weight)
		for i = 1,#count_list do
			weight = weight + count_list[i][2]
			if weight >= random_value then
				itemcnt = count_list[i][1]
				break
			end
		end
	end
	return itemcnt
end

local function get_lucky_draw(random_cnt,lucky_drawv)
	local lucky_draw = {}
	local function check_lucky_draw(lucky_draw_list,id)
		for i = 1,#lucky_draw_list do
			if lucky_draw_list[i] == id then
				return true
			end
		end
		return true
	end
	local function get_temp_lucky_draw(lucky_drawv,lucky_draw)
		local temp_list = {}
		for i = 1,#lucky_drawv do
			local flag = false
			for j = 1,#lucky_draw do
				if lucky_drawv[i] == lucky_draw[j] then
					flag = true
					break
				end
			end
			if not flag then
				temp_list[#temp_list + 1] = lucky_drawv[i]
			end
		end
		return temp_list
	end
	for i = 1,random_cnt do
		local cur_list = get_temp_lucky_draw(lucky_drawv,lucky_draw)
		local cur_cnt = #cur_list
		if cur_cnt >= 1 then
			local random_indx = math.random(1,cur_cnt)
			lucky_draw[#lucky_draw + 1] = cur_list[random_indx]
		end
	end
	return lucky_draw
end

local function get_club_reward(ur,clubid)
	local club_info = ur.club
	local tp = tpclub[clubid]
	if not tp then
		return 
	end
	local score = 0
	local lucky_draw = {}
	local random_cnt = 0
	local countv = 0
	local lucky_drawv = {}
	if  club_info.score >= 1 and  club_info.score <=2 then
		countv = tp.item_count1
		lucky_drawv = tp.lucky_draw1
	elseif  club_info.score >= 3 and  club_info.score <=4 then
		countv = tp.item_count2
		lucky_drawv = tp.lucky_draw2
	elseif  club_info.score >= 5 and  club_info.score <=6 then
		countv = tp.item_count3
		lucky_drawv = tp.lucky_draw3
	end
	random_cnt = random_count(countv)
	lucky_draw = get_lucky_draw(random_cnt,lucky_drawv)
	club_info.score = 0
	local function item_base_gen()
		return {
			itemid=0,
			itemcnt=0,
			item_type = 0,
		}
	end
	local item_list = {}
	local item_array = {}
	local card_array = {}
	local bug_flag = false
	for i = 1,#lucky_draw do
		local item_base = item_base_gen()
		item_base.itemid,item_base.itemcnt,item_base.item_type= get_item(ur,lucky_draw[i],item_list,tp.GemMax,tp.WashMax)
		if item_base.item_type == 1 or item_base.item_type == 3 then
			item_array[#item_array + 1] = item_base
		elseif item_base.item_type == 2 then
			card_array[#card_array + 1] = item_base
		end
		if item_base.itemid ~= 0 then
			item_list[#item_list + 1] = item_base
		end
	end
	local item_flag = false
	local card_flag = false
	for i = 1,#item_array do
		local item = item_array[i]
		itemop.gain(ur,item.itemid,item.itemcnt,tp.GemMax,tp.WashMax)
		item_flag = true
		local tp = tpitem[item.itemid]
		if tp and tp.quality >= 5 and tp.itemType == ITEM_EQUIP then
			broad_cast.set_borad_cast(ur,item.itemid,NOTICE_CLUB_T)
		end
	end
	if item_flag then
		itemop.refresh(ur)
		ur:db_tagdirty(ur.DB_ITEM)
	end
	local cards = ur.cards
	local left_pos_cnt = card_container.get_residual_position(ur)
	local left_card = {}
	local left_flag = false
	local left = false
	--if left_pos_cnt > 0 then
		local indx = 0
		for i = 1,#card_array do
			local card = card_array[i]
			if indx < left_pos_cnt then
				cards:put(ur,card.itemid,card.itemcnt)
				indx = indx + 1
				card_flag = true
			else
				left_card[#left_card + 1] = card
				left = true
			end
		end
	--end
	if card_flag then
		card_container.refresh(ur)
		ur:db_tagdirty(ur.DB_CARD)
	end
	if left then
		mail.send_club_card_mail(ur,left_card)
	end
	ur:db_tagdirty(ur.DB_CLUB)
	ur:send(IDUM_EXTRACTREWARD, {item_list = item_list})
end



REQ[IDUM_CHALLENGEOVER] = function(ur, v)
	local club_info = ur.club
	local score = 0
	local clubid = v.clubid
	local tp = tpclub[clubid]---[v.clubid]
	if not tp then
		return SERR_ERROR_LABEL
	end
	local corps_state = 0
	local battle_over = false
	for i =1,#club_info.crops do
		if club_info.crops[i].corpsid == clubid then
			if club_info.crops[i].corps_state == PERSONAL_CHALLENGE then
				club_info.crops[i].corps_state = TEAM_CHALLENGE
				corps_state = TEAM_CHALLENGE
				local pass_time = shaco.now()-ur.info.map_entertime*1000
				if v.die_flag == 0 then
					if pass_time - v.battle_time < tp.personal_1star  then
					
					end
					if tp.personal_1star < v.battle_time then
						score =0
					elseif tp.personal_1star >= v.battle_time and tp.personal_2star < v.battle_time then
						score =1
					elseif tp.personal_2star >= v.battle_time and tp.personal_3star < v.battle_time then
						score =2
					elseif tp.personal_3star >= v.battle_time then
						score =3
					end
				else
					score =0
				end
			elseif club_info.crops[i].corps_state == TEAM_CHALLENGE then
				club_info.crops[i].corps_state = OVER_CHALLENGE
				corps_state = OVER_CHALLENGE
				if v.die_flag == 0 then
					local pass_time = shaco.now() - ur.info.map_entertime* 1000
					if tp.personal_1star < v.battle_time then
						score =1
					elseif tp.personal_1star >= v.battle_time and tp.personal_2star < v.battle_time then
						score =1
					elseif tp.personal_2star >= pass_time and tp.personal_3star < v.battle_time then
						score =2
					elseif tp.personal_3star >= v.battle_time then
						score =3
					end
				else
					score =1
				end
				battle_over = true
			end
			club_info.score = club_info.score + score
			break
		end
	end
	ur:send(IDUM_CHALLENGERESULT, {corpsid = clubid,corps_state = corps_state,score = club_info.score})	
	if battle_over == true then
		get_club_reward(ur,clubid)
		task.set_task_progress(ur,41,tp.club_hardness,0)
		task.refresh_toclient(ur, 41)
		if not ur.battle_verify then
			if club_info.score >= 5 then
				ur:x_log_role_cheat(0,clubid,0,0)
			end
		end
		task.change_task_progress(ur,54,1,1)
		task.refresh_toclient(ur, 54)
		local club = club.refresh_club(ur)
		ur.club = club
		--tbl.print(club, "=============init club == ", shaco.trace)
		ur:send(IDUM_ACKRESHRESHCLUB, {info = club})
	end
	ur:db_tagdirty(ur.DB_CLUB)
end

REQ[IDUM_NOTICEENTERTEAMBATTLE] = function(ur, v)
	ur.info.map_entertime = shaco.now()//1000
end

return REQ

