local shaco = require "shaco"
local scene = require "scene"
local itemdrop = require "itemdrop"
local tbl = require "tbl"
local sfmt = string.format
local ladder = require "ladder"
local ladder_fast = require "ladder_fast"
local tpladder_item = require "__tpladder_item"
local tpgamedata = require "__tpgamedata"
local tppayprice = require "__tppayprice"
local config = require "config"
local task = require "task"
local itemop = require "itemop"
local broad_cast = require "broad_cast"
local tpitem = require "__tpitem"
local REQ = {}

REQ[IDUM_REQENTERLADDER] = function(ur, v)
	ladder_fast.enter_ladder(ur)
end

REQ[IDUM_REQLADDERRANK] = function(ur, v)
	ladder_fast.req_ladder_rank(ur,v.flag)
	
end

REQ[IDUM_REQLADDERSHOP] = function(ur, v)
	ladder.req_ladder_shop(ur)
end

REQ[IDUM_REQREFRESHLADDERSHOP] = function(ur, v)
	ladder.req_refresh_shop(ur)
end

REQ[IDUM_REQBUYITEMFROMLADDERSHOP] = function(ur, v)
	local ladder_info = ur.ladder
	local item_list = ladder_info.ladder_shop.info
	local flag = false
	local take = 0
	for i =1,#item_list do
		local info = item_list[i]
		if v.itemid == info.itemid and info.itemcnt == v.itemcnt and info.falg == 0 and v.pos == info.pos then
			flag = true
			take = info.money
			break
		end
	end
	
	if flag == false then
		return SERR_BUY_OVER
	end
	if ladder_info.honor < take then
		return SERR_HONOR_NOT_ENOUGH
	end

	local left_cnt = 0
	for i =1,#item_list do
		if v.itemid == item_list[i].itemid and item_list[i].itemcnt == v.itemcnt and v.pos == item_list[i].pos then
			left_cnt = item_list[i].itemcnt
			ladder_info.honor = ladder_info.honor - take
			itemop.gain(ur,v.itemid,v.itemcnt,item_list[i].hole_cnt,item_list[i].wash_cnt)
			local tp = tpitem[v.itemid]
			--print("tp.quality ==== "..tp.quality)
			if tp.quality >= 5 and  tp.itemType == ITEM_EQUIP then
				broad_cast.set_borad_cast(ur,v.itemid,NOTICE_LADDER_T)
			end
			item_list[i].falg = 1
			itemop.refresh(ur)
			ur:db_tagdirty(ur.DB_ITEM)
			break
		end
	end
	ur:db_tagdirty(ur.DB_LADDER)
	ur:send(IDUM_ACKBUYITEMFROMLADDERSHOP, {itemid = v.itemid,cnt = left_cnt,pos = v.pos,honor = ladder_info.honor})
	task.set_task_progress(ur,51,1,0)
	task.refresh_toclient(ur, 51)
end

REQ[IDUM_REQBUYCHALLENGECNT] = function(ur, v)
	local ladder_info = ur.ladder
	local buy_count = ladder_info.buy_challenge_cnt
	--print("---   buy_count == "..buy_count)
	if ladder_info.challengecnt >= tpgamedata.MaxChallenge then
		return SERR_MAX_LADDER_CHALLENGE_CNT
	end
	if buy_count >= ur:get_vip_value(VIP_BUY_LADDER_T) then
		return SERR_LADDER_BUY_CHALLENGE_MAX
	end
	local take = 0
	for k,u in pairs(tppayprice) do
		if u.type == 4 and u.start <= (buy_count + 1) and u.stop >= (buy_count + 1) then
			take = u.number
			break
		end
	end
	if ur:gold_take(take) == false then
		return SERR_GOLD_NOT_ENOUGH
	end
	ladder_info.buy_challenge_cnt = ladder_info.buy_challenge_cnt + 1
	ladder_info.challengecnt = ladder_info.challengecnt + 1
	task.set_task_progress(ur,46,1,0)
	task.refresh_toclient(ur, 46)
	ur:db_tagdirty(ur.DB_LADDER)
	ur:send(IDUM_ACKBUYCHALLENGECNT,{challenge_cnt = ladder_info.challengecnt,buy_count = ladder_info.buy_challenge_cnt})
end

REQ[IDUM_REQGETLADDERREWARD] = function(ur, v)
	ladder.req_season_reward(ur)
end

REQ[IDUM_REQSEARCHOPPONENT] = function(ur, v)
	local open_server_time = config.open_server_time --开服时间
	local __time=os.date("*t",open_server_time)
	local cur_time = shaco.now()//1000 --当前时间
	local deffrent = cur_time - open_server_time
	local season = ((__time.hour - 8)*3600 + deffrent)//(3*86400) + 1  --赛季
	local cur_season_time =((__time.hour - 8)*3600 + deffrent) - (season - 1)*3*86400
	local season_total_time = 3*86400
	print(" cur_season_time === "..cur_season_time.."  season_total_time - 8*3600 === "..season_total_time - 8*3600)
	if cur_season_time > (season_total_time - 8*3600) then
		return SERR_SEASON_REST
	end
	ladder_fast.req_search_opponent(ur,v.search_flag)
end

REQ[IDUM_REQENTERLADDERSCENE] = function(ur, v)
	local open_server_time = config.open_server_time --开服时间
	local cur_time = shaco.now()//1000 --当前时间
	local __time=os.date("*t",open_server_time)
	local deffrent = cur_time - open_server_time
	local season = ((__time.hour - 8)*3600 + deffrent)//(3*86400) + 1  --赛季
	local cur_season_time =((__time.hour - 8)*3600 + deffrent) - (season - 1)*3*86400
	local season_total_time = 3*86400
	if cur_season_time > (season_total_time - 8*3600) then
		return SERR_SEASON_REST
	end
	task.set_task_progress(ur,32,0,0)
	task.refresh_toclient(ur, 32)
	ladder.req_enter_ladder_scene(ur)
end

REQ[IDUM_NOTICEBATTLEOVER] = function(ur, v)
	local ladder_info = ur.ladder
	local front_seat = ladder_info.ranking
	if v.battle_result == 1 then --win
		ladder_info.score = ladder_info.score + tpgamedata.WinIntegral
		ladder_info.honor = ladder_info.honor + tpgamedata.WinHonor
		task.change_task_progress(ur,35,1,1)
		task.refresh_toclient(ur, 35)
		task.set_task_progress(ur,20,1,0)
		task.refresh_toclient(ur, 20)
		ladder_info.wincnt = ladder_info.wincnt + 1
		--task.change_task_progress(ur,34,1,tpgamedata.WinHonor)
	elseif v.battle_result == 2 then
		ladder_info.score = ladder_info.score + tpgamedata.LoseIntegral
		ladder_info.honor = ladder_info.honor + tpgamedata.LoseHonor
		task.change_task_progress(ur,35,0,0)
		--task.change_task_progress(ur,34,1,tpgamedata.LoseHonor)
	end
	local honor_value = ladder_info.wincnt * tpgamedata.WinHonor + (ladder_info.joincnt - ladder_info.wincnt) * tpgamedata.LoseHonor
	task.set_task_progress(ur,34,honor_value,0)
	if (ur.info.special_event >> LADDER_EVENT_T) & 1 == 0 then
		ur.info.special_event = ur.info.special_event + 2^LADDER_EVENT_T
	    ur:db_tagdirty(ur.DB_ROLE)
    end
	ladder_info.battle_time=0
	ladder_info.robot_id = 0
	ladder_info.opponent_info = nil
	--task.refresh_toclient(ur, 34)
	if not ur.battle_verify then
		if v.battle_result == 1 then
			ur:x_log_role_cheat(0,0,ladder_info.robot_id,ladder_info.opponent_battle_value)
		end
	end
	task.set_task_progress(ur,33,ladder_info.score,0)
	task.refresh_toclient(ur, 33)
	ladder_fast.join_ladder_game(ur)
	ladder_fast.enter_ladder(ur)
	ladder_fast.req_ladder_rank(ur,0)
	ur:send(IDUM_ACKBATTLERESULT,{front_seat = front_seat,cur_seat = ladder_info.ranking,cur_score = ladder_info.score,cur_honor = ladder_info.honor})
	ur:db_tagdirty(ur.DB_LADDER)
end

return REQ
