local shaco = require "shaco"
local tbl = require "tbl"
local CTX = require "ctx"
local pb = require "protobuf"
local userpool = require "userpool"
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

local ladder_fast = {}
local ladder_record = {}
local ladder_front_five = {}
local ladder_front_hundred = {}
local rank_update = 0
local season_state = 0
local five_rank_update = 0
local cur_season = 0
local sync_update_time = 0

function ladder_fast.init()
end

local function ladder_partner_data_gen()
	return {
		cardid = 0,
		level = 0,
		skills = {},
		attribute = {}
	}
end

local function get_container(ur)
	local cards = card_container.get_card_container(ur.cards.__card.__cards)
    local container = {list = cards,partners = ur.cards.__partner}
	--tbl.print(cards,"cards ==============  ")
	return container
end

local function set_self_partner_data(ur)
	local partner_list = {}
	local cards = ur.cards.__card.__cards
	for i = 1,#cards do
		local flag = false
		local card = cards[i]
		for j = 1,#ur.cards.__partner do
			local partner = ur.cards.__partner[j]
			if partner.pos == card.pos and partner.pos ~= 0 then
				flag = true
			end
		end
		if flag then
			local data = ladder_partner_data_gen()
			data.cardid = card.cardid
			data.level = card.level
			if #card.skills ~= 0 then
				data.skills = card.skills
			end
			data.attribute = card_container.total_card_attribute(ur.cards.__card.__attributes[card.pos])
			--tbl.print(data.attribute,"data.attribute =========  ")
			partner_list[#partner_list + 1] = data
		end
	end
	return partner_list
end

local function _gen(ur,rank)
    return {
			score= ur.ladder.score,
			level=ur.base.level,
			name=ur.base.name,
			joincnt=ur.ladder.joincnt,
			wincnt=ur.ladder.wincnt,
			roleinfo=ur.info,
			ranking=rank,
			roleid=ur.base.roleid,
			container=get_container(ur),
			battle_value = ur.battle_value,
			equip = ur.equip.__items,
			season = 0,
			tpltid = ur.base.tpltid,
			partner_data = set_self_partner_data(ur),
    }
end

local function rank_info_gen(score,name,joincnt,wincnt,ranking)
	return {
		score=score,
		name=name,	
		joincnt=joincnt,
		wincnt=wincnt,
		ranking=ranking,
	}
end

local function ladder_data_gen(name)
	return {
		score=0,
		level=0,
		name=name,	
		joincnt=0,
		wincnt=0,
		ranking=0,
		challengecnt=0,
		refreshcnt=0,
		honor=0,
		last_rank = 0,
		buy_challenge_cnt = 0,
	}
end

local function set_partner_data(container)
	local partner_list = {}
	for i = 1,#container.list do
		local flag = false
		local card = container.list[i]
		for j = 1,#container.partners do
			local partner = container.partners[j]
			if partner.pos == card.pos then
				flag = true
			end
		end
		if flag then
			local data = ladder_partner_data_gen()
			data.cardid = card.cardid
			data.level = card.level
			if #card.skills ~= 0 then
				data.skills = card.skills
			end
			data.attribute = card_attribute.compute_partner_attribute(card)
			--tbl.print(data.attribute,"data.attribute =========  ")
			partner_list[#partner_list + 1] = data
		end
	end
	return partner_list
end

local function ladder_record_gen(ladder_info,equip,roleid,info,container,base)
	  return {
        	score= ladder_info.score or 0,
			level=base.level or 0,
			name=ladder_info.name or "",
			joincnt=ladder_info.joincnt or 0,
			wincnt=ladder_info.wincnt or 0,
			roleinfo=info,
			ranking=ladder_info.ranking or 0,
			roleid=roleid,
			container=container,
			battle_value = info.battle_value,
			equip = equip,
			season = 0,
			tpltid = base.tpltid,
			partner_data = set_partner_data(container)
    }
end

local function set_cur_season()
	local open_server_time = config.open_server_time --开服时间
	local cur_time = shaco.now()//1000 --当前时间
	local __time=os.date("*t",open_server_time)
	local deffrent = cur_time - open_server_time
	cur_season = ((__time.hour - 8)*3600 + __time.min * 60 + __time.sec + deffrent)//(3*86400) + 1  --赛季
end

local function is_rest_season(now)
	local open_server_time = config.open_server_time --开服时间
	local test_time =os.date("*t",now)
	--print("test__hour == "..test.hour.." ---- test min =="..test.min.."---  test sec == "..test.sec)
	
	local __time=os.date("*t",open_server_time)
	local deffrent = now - open_server_time
	local __hour = __time.hour
	local season = math.floor(((__hour - 8)*3600 + __time.min * 60 + __time.sec + deffrent)/(3*86400)) + 1  --赛季
	local cur_season_time =((__hour - 8)*3600 + __time.min * 60 + __time.sec + deffrent) - (season - 1)*3*86400
	local season_total_time = 3*86400
	local flag = false
	--print("__hour == "..__hour.." ---- min =="..__time.min.."---  sec == "..__time.sec)
	--print("cur_season_time == "..cur_season_time.."  season_total_time == "..season_total_time)
	if cur_season_time >= (season_total_time - 8*3600) and cur_season_time < season_total_time then
		--print("__hour == "..test_time.hour.." ---- min =="..test_time.min.."---  sec == "..test_time.sec)
		--print("cur_season_time == "..cur_season_time.."  season_total_time == "..season_total_time)
		return true
	end
	return false
end

function ladder_fast.load(all)
	local cur_time = shaco.now()//1000 --当前时间
	set_cur_season()
    ladder_record = {}
    for _, v in ipairs(all) do
		local one = pb.decode("ladder_base", v.data).ladder_data
		--  local one = pb.decode("ladder_base", v.data)
		--print("one.season == "..one.season.." cur_season == "..cur_season)
		if one.season == cur_season then
			local equip = {}
			local roleid = tonumber(v.roleid)
			local item = rcall(CTX.db, "L.ex", {roleid=roleid, name="item"})
			if item then
				equip = pb.decode("item_list", item).equip
			end
			local info = rcall(CTX.db, "L.role", roleid)
			if info then
				info = pb.decode("role_info", info)
			end 
			local base = rcall(CTX.db, "L.base", roleid) 
			if base then
				base = pb.decode("role_base", base)
			end 
			local card = rcall(CTX.db, "L.ex", {roleid=roleid, name="card"})
			if card then
				card = pb.decode("card_list", card).list
			end
			local container = {list = card.list,partners = card.partners}
			local record_info = ladder_record_gen(one,equip,roleid,info,container,base)
			ladder_record[#ladder_record + 1] = record_info
			--shaco.trace(sfmt("user   name ==%s ------opponentid === %d .-------- =..role",record_info.name,record_info.tpltid))
		end
    end 
	local function sort_score_Asc(a,b)
		if a.score == b.score then return a.name >= b.name 
		else return a.score >= b.score end
	end
	table.sort(ladder_record,sort_score_Asc)
	for i =1,#ladder_record do
		ladder_record[i].ranking = i
		if i <= 5 then
			ladder_front_five[#ladder_front_five + 1] = ladder_record[i]
		end
		if i <= 100 then
			ladder_front_hundred[#ladder_front_hundred + 1] = ladder_record[i]
		end
		if ladder_record[i].name == "赫歆英光" then
			--tbl.print(ladder_record[i].container,"ladder_record ====== ")
		end
	end
	if is_rest_season(cur_time) == true then
		--print("------------------------load_ladder-----season_state ==---------------------------"..season_state)
		season_state = 1
	else
	--	print("------------------------load_ladder-----season_state ==------------------111111111---------"..season_state)
	end
	
end

function ladder_fast.enter_ladder(ur)
	local ladder_info = ur.ladder
	local roleid = ur.base.roleid
	local record_info = ladder_fast.get_role_ladder_info(roleid)
	if record_info then
		ladder_info.ranking = record_info.ranking
	else
		ladder_info.ranking = 0
	end
	local __rank = {}
	local flag = 0
	if ur.five_rank_update == 0 and five_rank_update == 0 then
		flag = 1
		if ur.five_rank_update == 0 then
			ur.five_rank_update = -1
		end
	else
		if five_rank_update >0 and ur.five_rank_update < five_rank_update then
			flag = 1
			ur.five_rank_update = five_rank_update
		end
	end
	if flag == 1 then
		for i =1,#ladder_front_five do
			__rank[i] = rank_info_gen(ladder_front_five[i].score,ladder_front_five[i].name,ladder_front_five[i].joincnt,ladder_front_five[i].wincnt,ladder_front_five[i].ranking)
		end
		
	end
	local __data = ladder_data_gen(ur.base.name)
	__data.score = ladder_info.score
	__data.level = ur.base.level
	__data.joincnt = ladder_info.joincnt
	__data.wincnt = ladder_info.wincnt
	__data.ranking = ladder_info.ranking
	__data.challengecnt = ladder_info.challengecnt
	__data.refreshcnt = ladder_info.refreshcnt
	__data.honor = ladder_info.honor
	__data.last_rank = ladder_info.last_rank
	__data.buy_challenge_cnt = ladder_info.buy_challenge_cnt
	local now = shaco.now()//1000
	ur:send(IDUM_ACKENTERLADDER, {data = __data,rank = __rank,refresh_time = now})
	
end

local function _tagdirty(id)
    for _, v in ipairs(dirty_flag) do
        if v == id then
            return
        end
    end
    dirty_flag[#dirty_flag+1] = id
end

function ladder_fast.get_role_ladder_info(roleid)
	for i =1,#ladder_record do
		if ladder_record[i].roleid == roleid then
			return ladder_record[i]
		end
	end
end

local function check_rank(ladder_array,roleid)
	for i =1,#ladder_array do
		local ladder_info = ladder_array[i]
		if ladder_info.roleid == roleid then
			
			return true
		end
	end
	return  false
end

function ladder_fast.get_ladder_arrary()
	return ladder_record
end

function ladder_fast.sort_ladder_rank()
	local function sort_score_Asc(a,b)
		if a.score == b.score then return a.name >= b.name 
		else return a.score >= b.score end
	end
	table.sort(ladder_record,sort_score_Asc)
	for i =1,#ladder_record do
		ladder_record[i].ranking = i
	end
end

function ladder_fast.update_ranking(ur)
	local five_rank = {}
	local hundred_rank = {}
	local roleid = ur.base.roleid
	local record_info = ladder_fast.get_role_ladder_info(roleid)
	local front_rank = record_info.ranking
	ladder_fast.sort_ladder_rank()
	record_info = ladder_fast.get_role_ladder_info(roleid)
	ur.ladder.ranking = record_info.ranking
	local hundred_flag = false
	local five_flag = false
	if record_info.ranking <= 100 then
		--local flag = false
		if not check_rank(ladder_front_hundred,roleid) then
			hundred_flag = true
		elseif record_info.ranking < front_rank then
			hundred_flag = true
		end
		if hundred_flag then
			ladder_front_hundred = {}
			rank_update = rank_update + 1
			for i =1,#ladder_record do
				if ladder_record[i].ranking <= 100 then
					ladder_front_hundred[#ladder_front_hundred + 1] = ladder_record[i]
					hundred_rank[i] = rank_info_gen(ladder_record[i].score,ladder_record[i].name,ladder_record[i].joincnt,ladder_record[i].wincnt,ladder_record[i].ranking)
				end
			end
		end
	end
	if  record_info.ranking <= 5 then
		--local flag = false
		if not check_rank(ladder_front_five,roleid) then
			five_flag = true
		elseif record_info.ranking < front_rank then
			five_flag = true
		end
		if five_flag then
			ladder_front_five = {}
			rank_update = rank_update + 1
			five_rank_update = five_rank_update + 1
			for i =1,#ladder_record do
				if ladder_record[i].ranking <= 5 then
					ladder_front_five[#ladder_front_five + 1] = ladder_record[i]
					five_rank[i] = rank_info_gen(ladder_record[i].score,ladder_record[i].name,ladder_record[i].joincnt,ladder_record[i].wincnt,ladder_record[i].ranking)
				end
			end
		end
	end
	if five_flag and hundred_flag then
		ur:send(IDUM_SYNCRANKINFO, {five_rank = five_rank,hundred_rank = hundred_rank})
	elseif not five_flag and hundred_flag then
		ur:send(IDUM_SYNCRANKINFO, {five_rank = {},hundred_rank = hundred_rank})
	elseif five_flag and not hundred_flag then
		ur:send(IDUM_SYNCRANKINFO, {five_rank = five_rank,hundred_rank = {}})
	end
end

function ladder_fast.req_ladder_rank(ur,value_flag)
	local flag = 0
	local __rank = {}
	if ur.rank_update == 0 and rank_update == 0 then
		flag = 1
		if ur.rank_update == 0 then
			ur.rank_update = -1
		end
	else
		if rank_update >0 and ur.rank_update < rank_update then
			flag = 1
			ur.rank_update = rank_update
		end
	end
	if flag == 1 then
		for i =1,#ladder_front_hundred do
			__rank[i] = rank_info_gen(ladder_front_hundred[i].score,ladder_front_hundred[i].name,ladder_front_hundred[i].joincnt,ladder_front_hundred[i].wincnt,ladder_front_hundred[i].ranking)
		end
	end
	ur:send(IDUM_ACKLADDERRANK, {update_flag = flag,rank = __rank})
end

function ladder_fast.changelastrank(ur,last_rank)
	local roleid = ur.base.roleid
	local record_info = ladder_fast.get_role_ladder_info(roleid)
	if not record_info then
		return
	end
	record_info.last_rank = last_rank
end

local function sync_update_rank_info()
	for i =1,#ladder_record do
		local ur = userpool.find_byid(ladder_record[i].roleid)
		if ur then
			local flag = 0
			local hundred_rank = {}
			local five_rank = {}
			ladder_front_five = {}
			ladder_front_hundred = {}
			
			ladder_fast.sort_ladder_rank()
			for i =1,#ladder_record do
				ladder_record[i].ranking = i
				if i <= 5 then
					ladder_front_five[#ladder_front_five + 1] = ladder_record[i]
					five_rank[i] = rank_info_gen(ladder_record[i].score,ladder_record[i].name,ladder_record[i].joincnt,ladder_record[i].wincnt,ladder_record[i].ranking)
				end
				if i <= 100 then
					ladder_front_hundred[#ladder_front_hundred + 1] = ladder_record[i]
					hundred_rank[i] = rank_info_gen(ladder_record[i].score,ladder_record[i].name,ladder_record[i].joincnt,ladder_record[i].wincnt,ladder_record[i].ranking)
				end
			end
			ur:send(IDUM_SYNCRANKINFO, {five_rank = five_rank,hundred_rank = hundred_rank})
		end
	end
end

function ladder_fast.update(now)
	local time = now//1000
    local cur_time=os.date("*t",time)
	--tbl.print(cur_time, "=============init cur_time", shaco.trace)
	--is_rest_season(time)
	--print("------------------------season_state == "..season_state.."------ cur_time.hour =="..cur_time.hour)
	if (cur_time.hour == 24 or cur_time.hour == 0) and season_state == 0 then
		if is_rest_season(time) == true then
			print("------------------------update_ladder--------------------------------")
			season_state = 1
			for i =1,#ladder_record do
				ladder_record[i].last_rank = ladder_record[i].ranking
				shaco.sendum(CTX.db, "S.ladder", {
				name="ladder_info",
				roleid=ladder_record[i].roleid,
				rank = ladder_record[i].ranking,
				})
				local ur = userpool.find_byid(ladder_record[i].roleid)
				if ur then
					ur.ladder.last_rank = ladder_record[i].last_rank
					ladder_fast.enter_ladder(ur)
				end
			end
		end
	elseif cur_time.hour == 8 and season_state == 1 then
		print("--------------------------------------------------------111111111111111111111111")
		set_cur_season()
		season_state = 0
		ladder_front_five = {}
		ladder_front_hundred = {}
		for i =1,#ladder_record do
			local ur = userpool.find_byid(ladder_record[i].roleid)
			if ur then
				ur.ladder.score = 0
				ur.ladder.ranking = 0
				ur.ladder.wincnt = 0
				ur.ladder.joincnt = 0
				ur:db_tagdirty(ur.DB_LADDER)
				ladder_fast.enter_ladder(ur)
			end
		end
		ladder_record = {}
	end
	
	if sync_update_time > 0 then
		local difference_time = time - sync_update_time
		local flag,temp = math.modf(difference_time/300)
		if flag >= 1 then
			sync_update_time = time
			
			sync_update_rank_info()
		end
	else
		if sync_update_time == 0 then
			sync_update_time = time
		end
	end
	
--	if ur.five_rank_update > 0 and ur.five_rank_update < five_rank_update then
	
	--end
end

function ladder_fast.req_search_opponent(ur,search_flag)
	local now = shaco.now()//1000
	local ladder_info = ur.ladder
	local now_day = floor(now/86400)
	local last_day = floor(ladder_info.battle_time/86400)
	if now_day ~= last_day then
		ladder_info.battle_time = 0
		ladder_info.robot_id = 0
	end
	local score = ladder_info.score
	local max_score = score + 20
	local min_score = score - 20
	if min_score < 0 then
		min_score = 0
	end
	local roleid = ur.base.roleid
	local record_info = ladder_fast.get_role_ladder_info(roleid)
    if (ur.info.special_event >> LADDER_EVENT_T) & 1 == 0 then
		ladder_info.robot_id = 999
	end
	
	if not record_info and search_flag == 1 then
	
		if ladder_info.robot_id > 0 then
			ur:send(IDUM_ACKSEARCHOPPONENTROBOT,{robot_id = ladder_info.robot_id})
		else
			ladder_info.battle_time = now
			local robot_list = {}
			for k,v in pairs(tprobotteam) do
				if  v.Integral >= min_score and v.Integral <= max_score then
					robot_list[#robot_list + 1] = v
				end
			end
			if #robot_list == 0 then
				for k,v in pairs(tprobotteam) do
					robot_list[#robot_list + 1] = v
					break
				end
			end
			local random_indx = math.random(1,(#robot_list))
			local select_target = robot_list[random_indx]
			ladder_info.robot_id=select_target.id
			ur:send(IDUM_ACKSEARCHOPPONENTROBOT,{robot_id = select_target.id})
		end
	
		ladder_info.season = cur_season
		ur:db_tagdirty(ur.DB_LADDER)
		return
	else
	end
	
	if ladder_info.battle_time > 0 and search_flag == 1 then
		if ladder_info.robot_id > 0 then
			ur:send(IDUM_ACKSEARCHOPPONENTROBOT,{robot_id = ladder_info.robot_id})
		else
			for i = 1,#ladder_info.opponent_container_new do
				
			end
			print("select_target.opponent_level === "..ladder_info.opponent_level.."  --- select_target.battle_value ==== "..ladder_info.opponent_battle_value.."---- select_target.name ==== "..ladder_info.opponent_name_new)
			--tbl.print(ladder_info.opponent_container_new,"ladder_info.opponent_container_new = ===== ")
			ur:send(IDUM_ACKSEARCHOPPONENTROLE,{level=ladder_info.opponent_level,name = ladder_info.opponent_name_new,info=ladder_info.opponent_info,container =ladder_info.opponent_container_new,tpltid = ladder_info.opponent_tpltid,
												battle_value = ladder_info.opponent_battle_value,equip = ladder_info.opponent_equip,partner_data = ladder_info.partner_data})
		end
		ladder_info.season = cur_season
		ur:db_tagdirty(ur.DB_LADDER)
		return
	end
	ladder_info.battle_time = now
	--shaco.trace(sfmt("user score ==== %d ------tpgamedata.LadderPVP === %d   create role ...",score,tpgamedata.LadderPVP))
	if score < tpgamedata.LadderPVP then
		
		local robot_list = {}
		for k,v in pairs(tprobotteam) do
			if  v.Integral >= min_score and v.Integral <= max_score then
				robot_list[#robot_list + 1] = v
			end
		end
		local random_indx = math.random(1,(#robot_list))
		local select_target = robot_list[random_indx]
		ladder_info.robot_id=select_target.id
		ur:send(IDUM_ACKSEARCHOPPONENTROBOT,{robot_id = select_target.id})
	
		ladder_info.season = cur_season
		ur:db_tagdirty(ur.DB_LADDER)
	else
		--shaco.trace(sfmt("user score ==== %d --1111111111----tpgamedata.LadderPVP === %d   create role ...",score,tpgamedata.LadderPVP))
		local target_list = {}
		for i =1,#ladder_record do
			if ladder_record[i].roleid ~= roleid  and ladder_record[i].score >= min_score and ladder_record[i].score <= max_score and ladder_record[i].score >= tpgamedata.LadderPVP then
				target_list[#target_list + 1] = ladder_record[i]
			end
		end
		local flag = false
		if #target_list > 0 then
			local random_indx = math.random(1,#target_list)
			local select_target = target_list[random_indx]
			if select_target then
				flag = true
				ladder_info.opponent_info = select_target.roleinfo
				ladder_info.opponent_equip = select_target.equip
				ladder_info.opponent_level = select_target.level
				ladder_info.opponent_name_new = select_target.name
				ladder_info.opponent_container_new = select_target.container
				ladder_info.opponent_tpltid = select_target.tpltid
				ladder_info.opponent_battle_value = select_target.battle_value
				ladder_info.opponent_info = select_target.roleinfo
				ladder_info.partner_data = select_target.partner_data
				--tbl.print(ladder_info.opponent_container_new,"ladder_info.opponent_container_new = ==1111=== ")
				print("select_target.level === "..select_target.level.."  --- select_target.battle_value ==== "..select_target.battle_value.."---- select_target.name ==== "..select_target.name)
				ur:send(IDUM_ACKSEARCHOPPONENTROLE,{level=select_target.level,name = select_target.name,info=select_target.roleinfo,container =select_target.container,tpltid = select_target.tpltid,
							battle_value = select_target.battle_value,equip = select_target.equip,partner_data = select_target.partner_data})
				shaco.trace(sfmt("user   name ==%s ------opponentid === %d .--------select_target.tpltid ==== %d..role",ur.base.name,select_target.tpltid,select_target.tpltid))
				ladder_info.season = cur_season
				ur:db_tagdirty(ur.DB_LADDER)
				return
			else
				flag = false
			end
		else
			local temp_list = {}
			local __flag = false
			for i =1,10000 do
				if __flag == true then
					break
				end
				for i =1,#ladder_record do
					local __min_score = min_score - 20*i
					if __min_score <= 0 then
						__min_score = 0
					end
					local __max_score = max_score - 20*i
					if __max_score <= 0 then
						__max_score = 0
					end
					if ladder_record[i].roleid ~= roleid  and ladder_record[i].score >= __min_score and ladder_record[i].score <= __max_score and ladder_record[i].score >= tpgamedata.LadderPVP then
						temp_list[#temp_list + 1] = ladder_record[i]
						__flag = true
					end
				end
			end
			if #temp_list > 0 then
				local random_indx = math.random(1,#temp_list)
				local select_target = temp_list[random_indx]
				if select_target then
					flag = true
					ladder_info.opponent_info = select_target.roleinfo
					ladder_info.opponent_equip = select_target.equip
					ladder_info.opponent_level = select_target.level
					ladder_info.opponent_name_new = select_target.name
					ladder_info.opponent_container_new = select_target.container
					ladder_info.opponent_tpltid = select_target.tpltid
					ladder_info.opponent_battle_value = select_target.battle_value
					ladder_info.partner_data = select_target.partner_data
					ur:send(IDUM_ACKSEARCHOPPONENTROLE,{level=select_target.level,name = select_target.name,info=select_target.roleinfo,container =select_target.container,tpltid = select_target.tpltid,
															battle_value = select_target.battle_value,equip = select_target.equip,partner_data = select_target.partner_data})
					shaco.trace(sfmt("user   name ==%s ------opponentid === %d ...max_role",ur.base.name,select_target.tpltid))
					ladder_info.season = cur_season
					ur:db_tagdirty(ur.DB_LADDER)
					
					return
				else
					flag = false
				end
			end
		end
		if flag == false then
			local select_target = {}
			for k,v in pairs(tprobotteam) do
				if  v.Integral == tpgamedata.LadderPVP then
					select_target = v
				end
			end
			ladder_info.robot_id = select_target.id
			ladder_info.season = cur_season
			ur:db_tagdirty(ur.DB_LADDER)
			ur:send(IDUM_ACKSEARCHOPPONENTROBOT,{robot_id = select_target.id})
		end
	end
end


function ladder_fast.join_ladder_game(ur)
	local roleid = ur.base.roleid
	local record_info = ladder_fast.get_role_ladder_info(roleid)
	local dirty = false
	if record_info == nil then
		record_info = _gen(ur,#ladder_record+1)
		card_container.set_equip(ur)
		ladder_record[#ladder_record + 1] = record_info
		dirty = true
		ur.ladder.season = cur_season
		ur.ladder.ranking = #ladder_record
	else
		record_info.battle_value = ur.battle_value
		record_info.equip = ur.equip.__items
		record_info.roleinfo=ur.info
		record_info.level = ur.base.level
		record_info.partner_data = set_self_partner_data(ur)
	end
	record_info.score = ur.ladder.score
	ladder_fast.update_ranking(ur)
	ur:db_tagdirty(ur.DB_LADDER)
end


return ladder_fast
