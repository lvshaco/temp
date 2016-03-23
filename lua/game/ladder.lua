local shaco = require "shaco"
local tbl = require "tbl"
local CTX = require "ctx"
local pb = require "protobuf"
local tbl = require "tbl"
local ipairs = ipairs
local tpladdershop = require "__tpladdershop"
local tpmystery_item = require "__tpmystery_item"
local tpladder_item = require "__tpladder_item"
local tppayprice = require "__tppayprice"
local tpgamedata = require "__tpgamedata"
local tpladderfixedaward = require "__tpladderfixedaward"
local tpladderexclusiveaward = require "__tpladderexclusiveaward"
local tprobotteam = require "__tprobotteam"
local config = require "config"
local card_container = require "card_container"
local club = require "club"
local scene = require "scene"
local itemop = require "itemop"
local task = require "task"
local attribute = require "attribute"
local card_attribute = require "card_attribute"
local tpladderrobot = require "__tpladderrobot"
local tpcard = require "__tpcard"
local sfmt = string.format
local floor = math.floor
local rcall = shaco.callum
local tonumber = tonumber

local dirty_flag = {}

local ladder = {}
local ladder_record = {}
local ladder_front_five = {}
local ladder_front_hundred = {}
local rank_update = 0
local season_state = 0
local five_rank_update = 0


function ladder.init()
end

local function ladder_shop_gen()
	return {
		refresh_time=0,
		info={},
		refresh_cnt=0,
	}
end

local function ladder_shop_item_gen()
	return {
		itemid = 0,
		itemcnt = 0,
		pos = 0,
		falg = 0,
		mystery_id = 0,
		mystery_item_id=0,
		money_type = 0,
		money = 0,
		hole_cnt = 0,
		wash_cnt = 0,
	}
end

local function get_item_data(itemid,pos,hole_cnt,wash_cnt)
	local item_list = {}
	local total_weight = 0
	local tp_array = tpladder_item[itemid]
	if tp_array  then
		for i=1,#tp_array do
			if tp_array[i].mystery_item_id == itemid then
				item_list[#item_list + 1] = tp_array[i]
				total_weight = total_weight + tp_array[i].weighing
			end
		end
	end
	if total_weight < 1 then
		return
	end
	local random_weight = math.random(1,total_weight)
	local weight = 0
	local item_info = ladder_shop_item_gen()
	for i=1,#item_list do
		local info = item_list[i]
		weight = weight + info.weighing 
		if weight >= random_weight then
			item_info.itemid = info.item_id
			item_info.itemcnt = info.count
			item_info.pos = pos
			item_info.falg = 0
			item_info.mystery_id = 0
			item_info.mystery_item_id = itemid
			item_info.money_type = 0
			item_info.money = info.money_count
			item_info.hole_cnt = hole_cnt
			item_info.wash_cnt = wash_cnt
			break
		end
	end
	return item_info
end

local function init_ladder_shop(level)
	local item_list = {}
	for k,v in pairs(tpladdershop) do
		if v.Start <= level and v.End >= level then
			for i =1,14 do
				item_list[#item_list + 1] = get_item_data(v["Item"..i],i,v.GemMax,v.WashMax)
			end
		end
	end
	local now = shaco.now()//1000
   -- local now_day = floor(now/86400)
    --local last_day = floor(self.info.refresh_time/86400)
	local ladder_shop = ladder_shop_gen()
	ladder_shop.refresh_time = now
	ladder_shop.info = item_list
	return ladder_shop
end

local function role_ladder_gen(base)
    return {
        	score=0,
			joincnt=0,
			wincnt=0,
			ranking=0,
			challengecnt=tpgamedata.MaxChallenge,
			refreshcnt=5,
			honor=0,
			ladder_shop= init_ladder_shop(base.level),
			buy_challenge_cnt=0,
			last_rank = 0,
			robot_id=0,
			opponent_info=nil,
			battle_time=0,
			opponent_equip = {},
			opponent_level = 0,
			opponent_name_new = "",
			opponent_container_new = {},
			opponent_tpltid = 0,
			opponent_battle_value = 0,
			season = 0,
			level = base.level,
			name = base.name,
			refresh_challcnt_time= 0,
			tpltid = base.tpltid,
    }
end

local function get_ladder_data(ladder_info)
    ladder_info.score= ladder_info.score or 0
	ladder_info.joincnt=ladder_info.joincnt or 0
	ladder_info.wincnt=ladder_info.wincnt or 0
	ladder_info.ranking=ladder_info.ranking or 0
	ladder_info.challengecnt=ladder_info.challengecnt or 0
	ladder_info.refreshcnt=ladder_info.refreshcnt or 0
	ladder_info.honor=ladder_info.honor or 0
	ladder_info.buy_challenge_cnt=ladder_info.buy_challenge_cnt or 0
	ladder_info.last_rank = ladder_info.last_rank or 0
	ladder_info.robot_id=ladder_info.robot_id or 0
	ladder_info.opponent_level = ladder_info.opponent_level or 0
	ladder_info.opponent_name_new = ladder_info.opponent_name_new or ""
	ladder_info.opponent_tpltid = ladder_info.opponent_tpltid or 0
	ladder_info.opponent_battle_value = ladder_info.opponent_battle_value or 0
	ladder_info.season = ladder_info.season or 0
	ladder_info.level = ladder_info.level or 0
	ladder_info.name = ladder_info.name or ""
	ladder_info.refresh_challcnt_time = ladder_info.refresh_challcnt_time or 0
	ladder_info.tpltid = ladder_info.tpltid or 0
	local open_server_time = config.open_server_time --开服时间
	local cur_time = shaco.now()//1000--当前时间
	local __time=os.date("*t",open_server_time)
	local deffrent = cur_time - open_server_time
	local test_time=os.date("*t",cur_time)
	local cur_season = ((__time.hour - 8)*3600 + __time.min * 60 + __time.sec + deffrent)//(3*86400) + 1  --赛季
	if cur_season ~= ladder_info.season then
		ladder_info.score = 0
		ladder_info.wincnt = 0
		ladder_info.joincnt = 0
		ladder_info.ranking = 0
		--print("cur_season == "..cur_season.."----- ladder_info.season ==  "..ladder_info.season)
	else
		--print("----------cur_season == "..cur_season.."----- ladder_info.season ==  "..ladder_info.season.."-------------------")
	end
end

function ladder.new(ladderv,base)
	local __ladder = nil
	if ladderv then
		__ladder = ladderv
		get_ladder_data(__ladder)
	else
		__ladder = role_ladder_gen(base)
	end
	return __ladder
end

function ladder.add_ladder_score(ur,score)	
	ur.ladder.score = ur.ladder.score + score
	ur:db_tagdirty(ur.DB_LADDER)
end

function ladder.reduce_ladder_score(ur,score)
	ur.ladder.score = ur.ladder.score - score
	ur:db_tagdirty(ur.DB_LADDER)
end

function ladder.req_ladder_shop(ur)
	local ladder_shop = nil
	if ur.ladder.ladder_shop then
		ladder_shop = ur.ladder.ladder_shop
	else
		ladder_shop = init_ladder_shop(ur.base.level)
		ur.ladder.ladder_shop= ladder_shop
	end
	local now = shaco.now()//1000
	ur:send(IDUM_ACKLADDERSHOP, {info = ladder_shop.info,refresh_cnt =ladder_shop.refresh_cnt,honor = ur.ladder.honor,refresh_time = now})
end

function ladder.req_refresh_shop(ur)
	local ladder_shop = ur.ladder.ladder_shop
	local level = ur.base.level
	local item_list = {}
	local money_type = 0
	local take = 0
	for k,v in pairs(tppayprice) do
		if v.type == 2 and v.start <= (ladder_shop.refresh_cnt + 1) and v.stop >= (ladder_shop.refresh_cnt + 1) then
			money_type = v.money_tpye
			take = v.number
			break
		end
	end
	if money_type == 0 then
		if ur:gold_take(take) == false then
			return SERR_GOLD_NOT_ENOUGH
		end
	elseif money_type == 1 then
		if ur.ladder.honor >= take then
			ur.ladder.honor = ur.ladder.honor - take
		elseif ur.ladder.honor < take then
			return SERR_HONOR_NOT_ENOUGH
		end
	end
	for k,v in pairs(tpladdershop) do
		if v.Start <= level and v.End >= level then
			for i =1,14 do
				item_list[#item_list + 1] = get_item_data(v["Item"..i],i)
			end
		end
	end
	ladder_shop.info = {}
	ladder_shop.info = item_list
	ladder_shop.refresh_cnt = ladder_shop.refresh_cnt + 1
	ur:db_tagdirty(ur.DB_ROLE)
	ur:db_tagdirty(ur.DB_LADDER)
	local now = shaco.now()//1000
	ur:send(IDUM_ACKLADDERSHOP, {info = ladder_shop.info,refresh_cnt =ladder_shop.refresh_cnt,honor = ur.ladder.honor,refresh_time = now})
end

function ladder.req_season_reward(ur)
	local ladder_info = ur.ladder
	local open_server_time = config.open_server_time --开服时间
	local __time=os.date("*t",open_server_time)
	local cur_time = shaco.now()//1000 --当前时间
	local deffrent = cur_time - open_server_time
	local season = math.floor(((__time.hour - 8)*3600 + deffrent)/(3*86400))  --赛季
	--print(" season === "..season.."  ladder_info.last_rank ===== "..ladder_info.last_rank)
	if season <= 0 or ladder_info.last_rank == 0 then
		return
	end
	
	for k,v in pairs(tpladderfixedaward) do
		if v.Start <= ladder_info.last_rank and v.End >= ladder_info.last_rank then
			ladder_info.honor = ladder_info.honor + v.Glory
			ur:coin_got(v.Money)
			ur:gold_got(v.DMoney)
			local flag = false
			for i=1,5 do
				if v["Item"..i.."ID"] > 0 then
					itemop.gain(ur,v["Item"..i.."ID"],v["Item"..i.."Number"])
					flag = true
				end
			end
			if flag == true then
				itemop.refresh(ur)
				ur:db_tagdirty(ur.DB_ITEM)
			end
			break
		end
	end
	local tp = tpladderexclusiveaward[season]
	if not tp then
		return
	end
	for i =1,8 do
		if ladder_info.last_rank >= tp["Place"..i][1][1] and ladder_info.last_rank <= tp["Place"..i][1][2] then
			if tp["Reward"..i.."Tpye"] == REWARD_CARD then 
				local cards = ur.cards
				if cards:put(ur,tp["Reward"..i.."ID"],tp["Reward"..i.."Number"]) > 0 then
					card_container.refresh(ur)
					ur:db_tagdirty(ur.DB_CARD)
					
				end
			elseif tp["Reward"..i.."Tpye"] == REWARD_FRAGMENT then
				itemop.gain(ur,tp["Reward"..i.."ID"],tp["Reward"..i.."Number"])
				--ur:send(IDUM_NOTICEADDFRAGMENT, {fragmentid =tp["Reward"..i.."ID"],fragment_cnt = tp["Reward"..i.."Number"]})
			end
		end
	end
	ur:db_tagdirty(ur.DB_ROLE)
	ur:sync_role_data()
	ur:send(IDUM_ACKGETLADDERREWARD, {last_season = season,last_rank = ladder_info.last_rank})
	ladder_info.last_rank = 0
	ur:db_tagdirty(ur.DB_LADDER)
	shaco.sendum(CTX.db, "S.ladder", {
				name="ladder_info",
				roleid=ur.base.roleid,
				rank = 0,
				})
end

local function get_partner_info(record_info)
	local cards = record_info.opponent_container_new.list
	local partners = record_info.opponent_container_new.partners
	local partner_info = {}
	for i = 1,#partners do
		for j=1, #cards do
			local card = cards[j]
			if card.pos == partners[i].pos then
				local partner_attribute = card_attribute.new(card.cardid,card.level,card.break_through_num)
				local par_battle_value = partner_attribute:compute_battle(card.cardid)
				local par_verify = partner_attribute:compute_verify()
				local __partner_info = {}
				__partner_info.par_battle_value = par_battle_value
				__partner_info.par_verify = par_verify
				__partner_info.pos = partners[i].pos
				partner_info[#partner_info + 1] = __partner_info
			end
		end
	end
	return partner_info
end

local function card_battle_value(monsterid)
	local ladder_monster =  tpladderrobot[monsterid]
	local tp = tpcard[ladder_monster.card]
	local battle_value = 0
	battle_value = tp.atk/10 + tp.magic/10 + tp.def/10 + tp.magicDef/10 + tp.hP/100 + tp.atkCrit/10 + tp.magicCrit/10 + tp.atkResistance/10 + tp.magicResistance/10 + tp.blockRate/10 + tp.dodgeRate/10  + tp.hits/10
				   + tp.level*(tp.hPRate/100 + tp.atkRate/10 + tp.defRate/10 + tp.magicRate/10 + tp.magicDefRate/10 + tp.atkResistanceRate/10 + tp.magicResistanceRate/10 + tp.dodgeRateRate/10 
				   + tp.atkCritRate/10 + tp.magicCritRate/10 + tp.blockRateRate/10 + tp.hitsRate/10)
	local verify_value = tp.hP/ math.max(tp.atk + tp.level*tp.atkRate + tp.magic + tp.level*tp.magicRate - (tp.def + tp.level*tp.defRate + tp.magicDef + tp.level*tp.magicDefRate),1)
	return battle_value,verify_value
end

local function get_min_value(value1,value2,value3)
	if value1 -  value2 < 0 and value1 - value3 < 0 then
		return true
	end
	return false
end

local function get_robot_min_verify(robot_id)
	local oppent_value = 0
	local tp = tprobotteam[robot_id]
	if not tp then
		return oppent_value
	end
	local frist_battle,frist_oppent = card_battle_value(tp.monster1)
	local second_battle,second_oppent = card_battle_value(tp.monster2)
	local third_battle,third_oppent = card_battle_value(tp.monster3)
	if get_min_value(frist_battle,second_battle,third_battle) then
		oppent_value = frist_oppent
	elseif get_min_value(second_battle,frist_battle,third_battle) then
		oppent_value = second_oppent
	elseif get_min_value(third_battle,second_battle,frist_battle) then
		oppent_value = third_oppent
	end
	return oppent_value
end

local function get_opponent_min_attribute(tpltid,record_info)
	local verify_value = 0
	if record_info.robot_id > 0 then
		verify_value = get_robot_min_verify(record_info.robot_id)
		return verify_value
	end
	local attributes = attribute.new(0,0,record_info.opponent_info.attribute,true)
	local battle_value = attributes:get_battle_value(tpltid)
	verify_value = attributes:compute_verify()
	local cards = record_info.opponent_container_new.list
	local partners = record_info.opponent_container_new.partners
	local partner_info = get_partner_info(record_info)
	local min_indx = 0
	if #partner_info > 1 then
		if partner_info[1].par_battle_value < partner_info[2].par_battle_value then
			min_indx = 1
		else
			min_indx = 2
		end
	else
		min_indx = 3
	end
	if min_indx ~= 3 then
		if partner_info[min_indx].par_battle_value > battle_value then
			return verify_value
		else
			return partner_info[min_indx].par_verify
		end
	else
		return verify_value
	end
end

local function verify_battle(ur,ladder_info)
	local oppent_value = get_opponent_min_attribute(ur.base.tpltid,ladder_info)
	local verify_value = ur:get_max_atrribute()
	if verify_value*1.5/oppent_value >= 1 then
		ur.battle_verify = true
	else
		ur.battle_verify = false
	end
end

function ladder.req_enter_ladder_scene(ur)
	local ladder_info = ur.ladder
	if ladder_info.challengecnt <  1 then
		return
	end
	local __sceneid = 3001
	local ok = scene.enter(ur, __sceneid)
    if ok then	
		--verify_battle(ur,ladder_info)
		ladder_info.joincnt = ladder_info.joincnt + 1
		ladder_info.challengecnt = ladder_info.challengecnt - 1
		ur:send(IDUM_ACKENTERLADDERSCENE, {sceneid = __sceneid,joincnt = ladder_info.joincnt,challengecnt = ladder_info.challengecnt})
		task.set_task_progress(ur,19,ladder_info.joincnt,0)
		task.refresh_toclient(ur, 19)
		ur:db_tagdirty(ur.DB_LADDER)
	end
end

function ladder.add_honor(ur,id,add_count)
	ur.ladder.honor = ur.ladder.honor + add_count
	ur:db_tagdirty(ur.DB_LADDER)
end

function ladder.add_ladder_honor(ur,honor)
	local ladder_info = ur.ladder
	ladder_info.honor =  ladder_info.honor + honor
	ur:db_tagdirty(ur.DB_LADDER)
end

local function system_refresh_shop(ur)
	local ladder_shop = ur.ladder.ladder_shop
	if not ladder_shop then
		return
	end
	local level = ur.base.level
	local item_list = {}
	for k,v in pairs(tpladdershop) do
		if v.Start <= level and v.End >= level then
			for i =1,14 do
				item_list[#item_list + 1] = get_item_data(v["Item"..i],i)
				ur.ladder.ladder_shop.info[i] = get_item_data(v["Item"..i],i)
			end
		end
	end
	local now = shaco.now()//1000
	local __time=os.date("*t",now)
	--tbl.print(ladder_shop.info, "=====1111111111========init ladder_shop.info", shaco.trace)
	--ur.ladder.ladder_shop.info = item_list
	--tbl.print(__time, "=============init __time", shaco.trace)
	ur.ladder.ladder_shop.refresh_cnt = 0 
	--ur.ladder.ladder_shop = ladder_shop
	--tbl.print(ur.ladder.ladder_shop, "=============init ur.ladder.ladder_shop", shaco.trace)
	ur:send(IDUM_ACKLADDERSHOP, {info = ur.ladder.ladder_shop.info,refresh_cnt =ur.ladder.ladder_shop.refresh_cnt,honor = ur.ladder.honor,refresh_time = now})
end

function ladder.onchangeday(ur)
	ur.ladder.challengecnt = tpgamedata.MaxChallenge
	ur.ladder.buy_challenge_cnt = 0
	system_refresh_shop(ur)
	ur:db_tagdirty(ur.DB_LADDER)
	ur:db_flush(true)
end

function ladder.update(ur,now)
	if ur.ladder.refresh_challcnt_time > 0 then
		local __now =now//1000
		local difference_time = __now - ur.ladder.refresh_challcnt_time
		local __cnt,temp = math.modf(difference_time/3600)
		if __cnt >= 1 then
			ur.ladder.refresh_challcnt_time = __now
			if ur.ladder.challengecnt < tpgamedata.MaxChallenge then
				if ur.ladder.challengecnt + __cnt >= tpgamedata.MaxChallenge then
					ur.ladder.challengecnt = tpgamedata.MaxChallenge
				else
					ur.ladder.challengecnt = ur.ladder.challengecnt + __cnt	
				end
				ur:send(IDUM_SYNCCHALLENGECNT, {challenge_cnt = ur.ladder.challengecnt})
			end
			ur:db_tagdirty(ur.DB_LADDER)
			ur:db_flush(true)
		end
	else
		ur.ladder.refresh_challcnt_time = now//1000
		ur:db_tagdirty(ur.DB_LADDER)
		ur:db_flush(true)
	end
end

return ladder
