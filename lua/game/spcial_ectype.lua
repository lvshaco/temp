local shaco = require "shaco"
local tbl = require "tbl"
local card_container = require "card_container"
local sfmt = string.format
local itemop = require "itemop"
local tppayprice = require "__tppayprice"
local tpexptower = require "__tpexptower"
local tpmoneytower = require "__tpmoneytower"
local tpgamedata = require "__tpgamedata"
local tpendlesstower = require "__tpendlesstower"
local tpdeadcanyon = require "__tpdeadcanyon"
local scene = require "scene"
local task = require "task"
local itemdrop = require "itemdrop"
--local activity_fast = require "activity_fast"
local spectype = {}

local function partner_state_gen()
	return {
		pos = 0,
		state = 0,
		blood_percent = 0,
	}
end

local function reward_data_gen()
	return {
		itemid = 0,
		itemcnt = 0,
		tower_floor = 0,
	}
end

local function topspeed_moment_challenge_gen()
	return {
		challengecnt = 0,
		difficulty = 0,
		type = 0,
	}
end

local function special_ectype_gen()
	return {
		max_floor = 0,
		revivecnt = 0,
		challengecnt = 0,
		buyrevivecnt = 0,
		partners = {},
		reward = {},
		state = 0,
		blood_percent = 0,
		topspeed_info = {},
		front_floor = 0,
		buy_endless_cnt =0,
		buy_moment_cnt = 0,
		buy_challenge_cnt = 0,
	}
end

local function endless_tower_gen()
	return {
		max_floor = 0,
		revivecnt = 0,
		challengecnt = 0,
		buyrevivecnt = 0,
		partners = {},
		reward = {},
		state = 0,
		blood_percent = 0,
		front_floor = 0,
	}
end

local function moment_reward_gen()
	return {
		cardid = 0,
		cardcnt = 0,
	}
end

local function set_new_partners()
	local partners = {}
	for i = 1,3 do
		local card = partner_state_gen()
		if i ~= 3 then
			card.state = 1
		else
			card.state = 2
		end
		partners[i] = card
	end
	return partners
end

local function set_card_data(spartners)
	local card_arrary = {}
	if spartners then
		local indx = 1
		for i = 1,#spartners do
			local card = partner_state_gen()
			card.pos = spartners[i].pos or 0
			card.state = spartners[i].state
			card.blood_percent = spartners[i].blood_percent or 0
			--tbl.print(card, "=============init card", shaco.trace)
			card_arrary[i] = card
		end
	else
		card_arrary = set_new_partners()
	end
	return card_arrary
end

function spectype.new(spectypev)
	local __spectype = special_ectype_gen()
	if spectypev then
		__spectype.max_floor = spectypev.max_floor or 0
		__spectype.revivecnt = spectypev.revivecnt or 0
		__spectype.challengecnt = spectypev.challengecnt or 0
		__spectype.buyrevivecnt = spectypev.buyrevivecnt or 0
		
		__spectype.partners = set_card_data(spectypev.partners)
		if #spectypev.reward == 0 then
			spectypev.reward = {}
		end
		__spectype.reward = spectypev.reward
		
		__spectype.state = spectypev.state or 0
		__spectype.blood_percent = spectypev.blood_percent or 0
		__spectype.front_floor = spectypev.front_floor or 0
		--__spectype.topspeed_info = spectypev.topspeed_info
		for i = 1,2 do
			local info = topspeed_moment_challenge_gen()
			info.type = i
			info.difficulty = spectypev.topspeed_info[i].difficulty
			info.challengecnt = spectypev.topspeed_info[i].challengecnt or 0
			__spectype.topspeed_info[#__spectype.topspeed_info + 1] = info
		end
		__spectype.buy_endless_cnt = spectypev.buy_endless_cnt
		__spectype.buy_moment_cnt = spectypev.buy_moment_cnt
		__spectype.buy_challenge_cnt = spectypev.buy_challenge_cnt
		--tbl.print(__spectype,"--------------1111111----__spectype.buy_moment_cnt === "..__spectype.buy_moment_cnt)
	else
		__spectype.challengecnt = 1
		__spectype.partners = set_new_partners()
		for i = 1,2 do
			local info = topspeed_moment_challenge_gen()
			info.type = i
			if i == 1 then
				info.challengecnt = tpgamedata.addexpcnt
			else
				info.challengecnt = tpgamedata.addmoneycnt
			end
			__spectype.topspeed_info[#__spectype.topspeed_info + 1] = info
		end
	end
	if spectypev then
      --  print(spectypev.max_floor)
		--tbl.print(__spectype, "=============init spectypev")
	end
	return __spectype
end

local function is_candidate_partners(spectypev,pos)
	for i = 1,#spectypev.partners do
		local partner = spectypev.partners[i]
		if partner.state == 1 and partner.pos == pos then
			return true
		end
	end
	return false
end

function spectype.set_candidate(ur,v)
	local spectypev = ur.spectype
	local flag = false
	if is_candidate_partners(spectypev,v.pos) then
		return SERR_CANDIDATE_IS_PARTNER
	end
	
	local partner = spectypev.partners[3]
	if partner.state == 2 and (partner.blood_percent == 100 or partner.blood_percent == 0) then
		flag = true
		partner.pos = v.pos
		partner.blood_percent = 100
	end
	if flag then
		ur:send(IDUM_ACKSETCANDIDATE,{pos = v.pos})
		ur:db_tagdirty(ur.DB_SPECTYPE)
	else
		return SERR_CANDIDATE_USED
	end
end

local function check_partner_data(spectypev)
	local indx = 0
	for i = 1,#spectypev.partners do
		local partners = spectypev.partners[i]
		if partners.state == 1 then
			indx = indx + 1
		end
	end
	return indx
end

function spectype.set_partner_data(ur)
	local spectypev = ur.spectype
	local partners = ur.cards.__partner
	for i = 1,#partners do
		if spectypev.state ~= 1 and partners[i].pos ~= 0 then
			local partner = partner_state_gen()
			partner.state = 1
			partner.pos = partners[i].pos
			partner.blood_percent = 100
			spectypev.partners[i] = partner
		end
	end
end

function spectype.get_alternate_pos(ur)
	local partner = ur.spectype.partners[3]
	return partner.pos
end

function spectype.sync_special_ectype(ur)
    --tbl.print(ur.spectype, "ur.spectype", shaco.debug)
	ur:send(IDUM_SYCSPECIALECTYPE,{data = ur.spectype})
end

function spectype.enter_endless_tower(ur,enter_type)
	local spectypev = ur.spectype
	local endless_tower = endless_tower_gen()
	if spectypev.state ~= 1 then
		if spectypev.state ~= 2 then
			spectypev.front_floor = 0
			spectypev.reward = {}
		end
		spectype.set_partner_data(ur)
		spectypev.state = 1
		--spectypev.buyrevivecnt = 0
		spectypev.blood_percent = 100
		spectypev.challengecnt = 0
	end
	endless_tower.max_floor = spectypev.max_floor
	endless_tower.revivecnt = spectypev.revivecnt
	endless_tower.challengecnt = spectypev.challengecnt
	endless_tower.buyrevivecnt = spectypev.buyrevivecnt
	endless_tower.partners = spectypev.partners
	endless_tower.reward = spectypev.reward
	endless_tower.state = spectypev.state
	endless_tower.blood_percent = spectypev.blood_percent
	endless_tower.front_floor = spectypev.front_floor
	ur:db_tagdirty(ur.DB_SPECTYPE)
	--tbl.print(endless_tower, "====111111111111111111111111=========endless_tower", shaco.trace)
	ur:send(IDUM_ACKSTARTCHALLENGE,{enter_type = enter_type,data = endless_tower})
end

local function get_reward(arrary,item_list)
	local reward_list = {}
	for k,v in pairs (arrary) do
		reward_list[#reward_list + 1] = v
	end
	local total_weigh = 0
	
	for i = 1,#reward_list do
		local tp = reward_list[i]
		total_weigh = total_weigh + tp.weigh
	end

	if total_weigh > 0 then
		local random_weigh = math.random(1,total_weigh)
		local weigh = 0
		for i = 1,#reward_list do
			local tp = reward_list[i]
			weigh = weigh + tp.weigh
			if weigh >= random_weigh then
				item_list[#item_list + 1] = tp
				break
			end
		end
	end
end

local function get_reward_list(__floor,item_list)
	for k,v in pairs (tpendlesstower) do
		if v.Number == __floor then
			for m,n in pairs (v.Reward) do
				---tbl.print(n.reward_list,"------- n.reward_list =====")
				--itemdrop.random_endless_reward_rule(rewards,count,item_list)
				itemdrop.random_endless_reward_rule(n.reward_list,n.num,item_list,__floor)
			--	tbl.print(item_list,"------- item_list =====")
				--for i = 1,n.num do
				--	get_reward(n.reward_list,item_list)
			--	end
			end
		end
	end 
end

function spectype.sync_endless_tower_ectype(ur, v)
	local spectypev = ur.spectype
	spectypev.blood_percent = v.data.blood_percent
	spectypev.partners = v.data.partners
	if v.endless_state == 1 then
		spectypev.front_floor = spectypev.front_floor + 1
		local item_list = {}
		get_reward_list(spectypev.front_floor,item_list)
		local floor_reward = {}
		for i = 1,#item_list do
			local tp = item_list[i]
			local reward_info = reward_data_gen()
			reward_info.itemid = tp.itemid
			reward_info.itemcnt = tp.cnt
			reward_info.tower_floor = spectypev.front_floor
			floor_reward[#floor_reward + 1] = reward_info
			spectypev.reward[#spectypev.reward + 1] = reward_info
			itemop.gain(ur,tp.itemid,tp.cnt)
		end
		if spectypev.front_floor >= spectypev.max_floor then
			spectypev.max_floor = spectypev.front_floor
			local activity = ur.activity
			activity.cur_floor = spectypev.front_floor
			ur:db_tagdirty(ur.DB_ACTIVITY)
		end
		itemop.refresh(ur)
		ur:db_tagdirty(ur.DB_ITEM)
		task.set_task_progress(ur,55,spectypev.max_floor,0)
		task.refresh_toclient(ur, 55)
		task.change_task_progress(ur,61,1,1)
		task.refresh_toclient(ur, 61)
		ur:send(IDUM_SYNCREWARDDATA,{reward = floor_reward})
	end
	ur:db_tagdirty(ur.DB_SPECTYPE)
	return spectypev.front_floor
end

function spectype.auto_matic_challenge(ur)
	local spectypev = ur.spectype
	local item_list = {}
	if spectypev.state ~= 0 then
		return 0
	end
	local integer,decimals = math.modf(spectypev.max_floor/5)
	if integer >= 1 then
		for i =1,integer do
			get_reward_list(5*i,item_list)
		end
	else
		return 0
	end
	local floor_reward = {}
	for i = 1,#item_list do
		local tp = item_list[i]
		local reward_info = reward_data_gen()
		reward_info.itemid = tp.itemid
		reward_info.itemcnt = tp.cnt
		reward_info.tower_floor = tp.floor_cnt
		floor_reward[#floor_reward + 1] = reward_info
		spectypev.reward[#spectypev.reward + 1] = reward_info
		itemop.gain(ur,tp.itemid,tp.cnt)
	end
	spectypev.front_floor = integer * 5
	task.change_task_progress(ur,61,1,spectypev.front_floor)
	task.refresh_toclient(ur, 61)
	spectypev.state = 2
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
	ur:db_tagdirty(ur.DB_SPECTYPE)
	ur:send(IDUM_ACKAUTOMATICCHALLENGE,{reward = floor_reward})
	return spectypev.front_floor
end

function spectype.notice_endless_tower_over(ur)
	local spectypev = ur.spectype
	if spectypev.front_floor >= spectypev.max_floor then
		spectypev.max_floor = spectypev.front_floor
	end
	spectypev.challengecnt = 0
	ur:db_tagdirty(ur.DB_SPECTYPE)
end

function spectype.buy_revive(ur)
	local spectypev = ur.spectype
	local take = 0
	local money_type = 100
	local cnt = spectypev.buyrevivecnt + 1
	local result =1
	for k, u in pairs(tppayprice) do
		if u.type == 6 and cnt >= u.start and cnt <= u.stop then
			take = u.number
			money_type = u.money_tpye
			break
		end
	end
	if money_type == 0 then
		if ur:gold_take(take) == false then
			result = 2
		end
	elseif money_type == 100 then
		result = 3
	end
	if result == 1 then
		spectypev.blood_percent = 100
		spectypev.buyrevivecnt = spectypev.buyrevivecnt + 1
		ur:db_tagdirty(ur.DB_SPECTYPE)
		for i = 1,#spectypev.partners do
			if spectypev.partners[i].pos > 0 then
				spectypev.partners[i].blood_percent = 100
			end
		end
		ur:db_tagdirty(ur.DB_SPECTYPE)
	end
	ur:sync_role_data()
	ur:db_tagdirty(ur.DB_ROLE)
	ur:send(IDUM_ACKBUYREVIVE,{result = result,buyrevivecnt = spectypev.buyrevivecnt})
end

local function get_spectype_state(ectype_type)
	local cur_time = shaco.now()//1000 --当前时间
	local tp = tpdeadcanyon[ectype_type + 1]
	local week_day = os.date("%w",cur_time)
	for i = 1,#tp.WeekTime do
		local week = tp.WeekTime[i]
	--	print("tp.WeekTime[i] === "..tp.WeekTime[i].."week_day == "..week_day)
		if week == tonumber(week_day) then
		--	print("*****************************")
			return true
		end
	end
	return false
end

function spectype.start_spectype(ur,v)
	if not get_spectype_state(v.ectype_type) then
	--	return 
	end
	--tbl.print(v,"--------v--------------------")
	local spectypev = ur.spectype
	local topspeed_info = spectypev.topspeed_info
	for i = 1,#topspeed_info do
		local info = topspeed_info[i]
		if info.type == v.ectype_type then
			--print("info.challengecnt ==== "..info.challengecnt)
			if info.challengecnt < 1 then
				return SERR_CHALLENGE_COUNT_OVER
			else
				info.difficulty = v.ectype_difficulty
			end
		end
	end
	local __sceneid = 0
	if v.ectype_type == 1 then
		__sceneid = 7001
	else
		__sceneid = 8001
	end
	local ok = scene.enter(ur, __sceneid)
	if ok then
		ur:db_tagdirty(ur.DB_SPECTYPE)
		ur:send(IDUM_ACKSTARTSPECTYPE,{ectype_type = v.ectype_type,ectype_difficulty = v.ectype_difficulty})
	end
end

local function get_reward_count(dropnumber)
	local total_weigh = 0
	for i = 1,#dropnumber do
		local num_info = dropnumber[i]
		total_weigh = total_weigh + num_info[2]
	end
	if total_weigh ~= 10000 then
		return 0
	end
	local random_weigh = math.random(1,total_weigh)
	local weigh = 0
	for i = 1,#dropnumber do
		local num_info = dropnumber[i]
		weigh = weigh + num_info[2]
		if weigh >= random_weigh then
			return num_info[1]
		end
	end
	return 0
end

local function get_card_reward(item_list,reward)
	local __list = {}
	local total_weigh = 0
	for i =1,#reward do
		local flag = false
		local info = reward[i]
		for j = 1,#item_list do
			local card = item_list[j]
			if card[1] == info[1] then
				flag = true
				break
			end
		end
		if not flag then
			__list[#__list + 1] = info
			total_weigh = total_weigh + info[3]
		end
	end
	if total_weigh < 1 then
		return
	end
	local random_weigh = math.random(1,total_weigh)
	local weigh = 0
	for i = 1,#__list do
		local card = __list[i]
		weigh = weigh + card[3]
		if weigh >= random_weigh then
			--[[
			if not card_container.enough(ur,1) then
				return
			end
			if cards:put(ur,card[1],card[2]) > 0 then
				cards.refresh(ur)
				ur:db_tagdirty(ur.DB_CARD)
			end]]
			item_list[#item_list + 1] = card
			break
		end
	end
end

local function get_ectype_difficulty(ur,ectype_type)
	local spectypev = ur.spectype
	local topspeed_info = spectypev.topspeed_info
	for i = 1,#topspeed_info do
		local info = topspeed_info[i]
		if info.type == ectype_type then
			return info.difficulty
		end
	end
end
function spectype.moment_reward(ur,number)
	local count = 0
	local item_list = {}
	local difficulty = 1
	for k,v in pairs (tpexptower) do 
		if v.Number == number and difficulty == v.Tpye then
			count = get_reward_count(v.DropNumber)
			if count ==0 then
				return SERR_ERROR_LABEL
			end
			--tbl.print(v.Reward, "-----v.Reward")
			itemdrop.random_reward_rule(v.Reward,count,item_list)
		end
	end
end

function spectype.set_challenge_cnt(ur)
	local spectypev = ur.spectype
	local topspeed_info = spectypev.topspeed_info
	for i = 1,#topspeed_info do
		local info = topspeed_info[i]
		if info.type == 1 then
			info.challengecnt = 1
		end
	end
	ur:db_tagdirty(ur.DB_SPECTYPE)
end

function spectype.get_moment_reward(ur,number)
	local count = 0
	local item_list = {}
	local difficulty = get_ectype_difficulty(ur,1)
	local spectypev = ur.spectype
	local topspeed_info = spectypev.topspeed_info
	for i = 1,#topspeed_info do
		local info = topspeed_info[i]
		if info.type == 1 then
			
			info.challengecnt = info.challengecnt - 1
		end
	end
	local max_floor = 0
	if number > 100 then
		max_floor = 100
	else
		max_floor = number
	end
	ur:db_tagdirty(ur.DB_SPECTYPE)
	for k,v in pairs (tpexptower) do 
		if v.Number == max_floor and difficulty == v.Tpye then
			count = get_reward_count(v.DropNumber)
			--print("count === "..count)
			if count ==0 then
			
				return SERR_ERROR_LABEL
			end
			itemdrop.random_reward_rule(v.Reward,count,item_list)
		end
	end
	local reward_list = {}
	local cards = ur.cards
	for i = 1,#item_list do
		local reward = moment_reward_gen()
		local card = item_list[i]
		reward.cardid = card.itemid
		reward.cardcnt = card.cnt
		reward_list[#reward_list + 1] = reward
		if cards:put(ur,card.itemid,card.cnt) > 0 then
				
		end
	end
	card_container.refresh(ur)
	ur:db_tagdirty(ur.DB_CARD)
	task.set_task_progress(ur,56,difficulty,0)
	task.refresh_toclient(ur, 56)
	
	ur:send(IDUM_ACKMOMENTREWARD,{reward = reward_list})
	return difficulty
end

function spectype.get_challenge_coin(ur, data)
	local difficulty = get_ectype_difficulty(ur,2)
	local max_money = 0
	for k,v in pairs (tpmoneytower) do
		if v.Tpye == difficulty then
			max_money = max_money + ((v.Money *(10000 + v.Float))//10000) * v.Quantity
		end
	end
	if data.drop_coin > max_money and max_money ~= 0 then
		ur:coin_got(max_money)
	else
		ur:coin_got(data.drop_coin)
	end
	ur:sync_role_data()
	if max_money == 0 then
		shaco.trace(sfmt("user data.drop_coin ==%d --- ur.inf.coin == %d --- difficulty == %d login ok",data.drop_coin,ur.info.coin,difficulty)) 
	end
	ur:db_tagdirty(ur.DB_ROLE)
	task.set_task_progress(ur,57,difficulty,0)
	task.refresh_toclient(ur, 57)
	local spectypev = ur.spectype
	local topspeed_info = spectypev.topspeed_info
	for i = 1,#topspeed_info do
		local info = topspeed_info[i]
		if info.type == 2 then
			info.challengecnt = info.challengecnt - 1
		end
	end
	ur:db_tagdirty(ur.DB_SPECTYPE)
	ur:send(IDUM_ACKCHALLENGEREWARD,{coin = money})
	return money,difficulty
end

function spectype.onchangeday(ur,login_state)
	local __spectype = ur.spectype
	__spectype.revivecnt = 1
	__spectype.challengecnt = 1
	__spectype.buyrevivecnt = 0
	__spectype.partners = set_new_partners()
	__spectype.reward = {}
	__spectype.state = 0
	__spectype.blood_percent = 100
	__spectype.front_floor = 0
	__spectype.buy_endless_cnt = 0
	__spectype.buy_moment_cnt = 0
	__spectype.buy_challenge_cnt = 0
	for i = 1,2 do
		local info = __spectype.topspeed_info[i]
		info.difficulty = 0
		if i == 1 then
		--	print("tpgamedata.addexpcnt == "..tpgamedata.addexpcnt)
			info.challengecnt = tpgamedata.addexpcnt
		else
			info.challengecnt = tpgamedata.addmoneycnt
		end
		--info.challengecnt = 1
	end
	--tbl.print(__spectype,"__spectype ========================= ")
	local activity = ur.activity
	activity.base_floor = __spectype.max_floor
	activity.cur_floor = __spectype.max_floor
    activity.floor_award_flags = {}
	ur:db_tagdirty(ur.DB_SPECTYPE)
	ur:db_tagdirty(ur.DB_ACTIVITY)
	if login_state == 2 then
		ur:send(IDUM_SYCSPECIALECTYPE,{data = ur.spectype})
	end
end


function spectype.req_buy_challenge_cnt(ur,buy_type,max_cnt)
	local __spectype = ur.spectype
	if buy_type == 1 then
		if __spectype.challengecnt == 0 then
			if __spectype.buy_endless_cnt == 0 then
				if ur:gold_take(tpgamedata.EndlessTower) then
					ur:sync_role_data()
					__spectype.buy_endless_cnt = __spectype.buy_endless_cnt + 1
					__spectype.challengecnt = 1
					__spectype.revivecnt = 1
					__spectype.partners = set_new_partners()
					__spectype.reward = {}
					__spectype.state = 0
					__spectype.blood_percent = 100
					__spectype.front_floor = 0
					ur:send(IDUM_ACKBUYENDLESSCHALLENGECNT,{result = 1,buy_type = buy_type})
					ur:db_tagdirty(ur.DB_SPECTYPE)
					ur:db_tagdirty(ur.DB_ROLE)
				else
					return SERR_GOLD_NOT_ENOUGH
				end
			else
				return SERR_BUY_ENDLESS_CHALLENGE_MAX
			end
		else
			return SERR_CHALLENGE_MAX
		end
	else
		for i =1,#__spectype.topspeed_info do
			local topspeed_info = __spectype.topspeed_info[i] --1是极限时刻,2是极限挑战
			if topspeed_info.type == 1 and buy_type == 2 then
				if topspeed_info.challengecnt == 0  then
					if __spectype.buy_moment_cnt == 0 then
						if ur:gold_take(tpgamedata.ExpTower) then
							ur:sync_role_data()
							__spectype.buy_moment_cnt = __spectype.buy_moment_cnt + 1
							topspeed_info.challengecnt = 1
							topspeed_info.difficulty = 0
							ur:send(IDUM_ACKBUYENDLESSCHALLENGECNT,{result = 1,buy_type = buy_type})
							ur:db_tagdirty(ur.DB_SPECTYPE)
							ur:db_tagdirty(ur.DB_ROLE)
						else
							return SERR_GOLD_NOT_ENOUGH
						end
					else
						return SERR_BUY_ENDLESS_CHALLENGE_MAX
					end
				else
					return SERR_CHALLENGE_MAX
				end
			elseif topspeed_info.type == 2 and buy_type == 3 then
				if topspeed_info.challengecnt == 0  then
					if __spectype.buy_challenge_cnt == 0 then
						if ur:gold_take(tpgamedata.MoneyTower) then
							ur:sync_role_data()
							__spectype.buy_challenge_cnt = __spectype.buy_challenge_cnt + 1
							topspeed_info.challengecnt = 1
							topspeed_info.difficulty = 0
							ur:send(IDUM_ACKBUYENDLESSCHALLENGECNT,{result = 1,buy_type = buy_type})
							ur:db_tagdirty(ur.DB_SPECTYPE)
							ur:db_tagdirty(ur.DB_ROLE)
						else
							return SERR_GOLD_NOT_ENOUGH
						end
					else
						return SERR_BUY_ENDLESS_CHALLENGE_MAX
					end
				else
					return SERR_CHALLENGE_MAX
				end
			end
		end
	end
end

function spectype.clear_state(ur)
	local __spectype = ur.spectype
	__spectype.state = 0
	ur:db_tagdirty(ur.DB_SPECTYPE)
end

function spectype.set_max_floor(ur,max_floor)
	local __spectype = ur.spectype
	__spectype.max_floor = max_floor
	ur:db_tagdirty(ur.DB_SPECTYPE)
end

return spectype
