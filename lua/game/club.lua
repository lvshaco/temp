--local shaco = require "shaco"
local shaco = require "shaco"
local pb = require "protobuf"
local tbl = require "tbl"
local sfmt = string.format
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local tpclub = require "__tpclub"
local tpclub_treasure = require "__tpclub_treasure"
local clubs = {}

local function clubs_gen()
	return {
		crops = {},
		card_framgent = {},
		club_refresh_cnt =0,
		violet_framgent =0,
		orange_framgent =0,
		score =0,
		last_refresh_time =0,
		challengecnt = 0,
	}
end

local function corp_gen()
	return {
		corpsid =0,
		corps_state =0,
	}
end

local function card_framgent_info_gen()
	return {
		card_framgent_id =0,
		count =0,
	}
end

local function check_crop_exsit(ur,id,crops)
	if ur then
		for i = 1,5 do
			local club = ur.club.crops[i]
			if club and club.corpsid == id then
				return false
			end
		end
	end
	for i =1,#crops do
		if crops[i].corpsid == id then
			return false
		end
	end
	return true
end

function clubs.check_club_state(ur)
	if ur then
		for i = 1,5 do
			local club = ur.club.crops[i]
			if club and club.corps_state > NOT_CHALLENGE and  club.corps_state < OVER_CHALLENGE then
				return false
			end
		end
	end
	return true
end

function clubs.update(ur,login)
	local now = shaco.now()//1000
	local curtime=os.date("*t",now)
	local level = ur.base.level
	--if curtime.hour >= 5 then
		--if not login then
	--		if ur.across_day ~= 1 then
		--		return
	--		else
	--			ur.across_day = 0 
		--	end
	--	end
	local open_bit = ur.info.open_bit
	if (open_bit >> FUNC_CLUB) & 1 == 0 then
		return 
	end
	local total_weight = 0
	local clubs = {}
	for k,v in pairs(tpclub) do
		if v.user_level[1][1] <= level and v.user_level[1][2] >= level then
			if v.club_hardness == 1 then
				clubs[#clubs + 1] = v
				total_weight = total_weight + v.club_probability 
			end
		end
	end
	if total_weight < 1 then
		return
	end
	local random_weight = math.random(1,total_weight)
	local weight = 0
	local crop_list = {}
	for j =1,5 do
		for i =1,#clubs do
			weight = weight + clubs[i].club_probability
			if weight >= random_weight then
				if check_crop_exsit(nil,clubs[i].id,crop_list) == true then
					local crop = corp_gen()
					crop.corpsid = clubs[i].id
					crop_list[#crop_list + 1] = crop
					break
				end
			end
		end
	end
	if (ur.info.special_event >> CLUB_EVENT_T) & 1 == 0 then
		ur.info.special_event = ur.info.special_event + 2^CLUB_EVENT_T
		crop_list[1].corpsid = 999999
	end
	local club_info = ur.club 
	local club = clubs_gen()
	club.crops = crop_list
	club.last_refresh_time = now
	club.card_framgent = club_info.card_framgent
	club.club_refresh_cnt = 0
	club.violet_framgent = club_info.violet_framgent
	club.orange_framgent = club_info.orange_framgent
	club.score = 0
	club.challengecnt = 0
	ur.club = club
	ur:db_tagdirty(ur.DB_CLUB)
	--elseif curtime.hour < 5 and login then
	--	ur.across_day = 1
	--end
end

local function get_club_info(ur)
	local level = ur.base.level
	local total_weight = 0
	for k,v in pairs(tpclub) do
		if v.user_level[1][1] <= level and v.user_level[1][2] >= level then
			if v.club_hardness == 1 then
				clubs[#clubs + 1] = v
				total_weight = total_weight + v.club_probability 
			end
		end
	end
	local crop_list = {}
	if total_weight >= 1 then
		local random_weight = math.random(1,total_weight)
		local weight = 0
		for j =1,5 do
			for i =1,#clubs do
				weight = weight + clubs[i].club_probability
				if weight >= random_weight then
					if check_crop_exsit(nil,clubs[i].id,crop_list) == true then
						local crop = corp_gen()
						crop.corpsid = clubs[i].id
						crop_list[#crop_list + 1] = crop
						break
					end
				end
			end
		end
	end
	if (ur.info.special_event >> CLUB_EVENT_T) & 1 == 0 then
		ur.info.special_event = ur.info.special_event + 2^CLUB_EVENT_T
		crop_list[1].corpsid = 999999
	end
	return crop_list
end

function clubs.new(ur,clubv,open_bit) 
	--local clubs	
	--[[if (open_bit >> FUNC_CLUB) & 1 == 0 then
		return false,clubs
	end]]
	local flag = true
	local club = clubs_gen()
	if #clubv ~= 0 then
		club.crops = clubv.crops
		club.last_refresh_time = shaco.now()//1000
		if #clubv.card_framgent == 0 then
		else
			club.card_framgent = clubv.card_framgent
		end
		club.club_refresh_cnt = clubv.club_refresh_cnt or 0
		club.violet_framgent = clubv.violet_framgent or 0
		club.orange_framgent = clubv.orange_framgent or 0
		club.score = clubv.score or 0
		club.challengecnt = clubv.challengecnt or 0
		flag = false
	else
		local crop_list = get_club_info(ur)
		club.crops = crop_list
		flag = true
	end
	--tbl.print(club, "==========11111===init club == ", shaco.trace)
    return flag,club
end

function clubs.init_club(ur)
	
	local crop_list = get_club_info(ur)
	local club = clubs_gen()
	club.crops = crop_list
	ur.club = club
	ur:db_tagdirty(ur.DB_CLUB)
end

local function check_club_refresh(ur,pos)
	local club = ur.club.crops[pos]
	if not club or club.corps_state == 0 then
		return false,club
	end
	return true,club
end

local function check_seat(seats,index)
	for i = 1,#seats do
		if seats[i] == index then
			return true
		end
	end
	return false
end

local function get_club_list(ur,crop_list,pos)
	local level = ur.base.level
	local total_weight = 0
	local clubv = {}
	for k,v in pairs(tpclub) do
		if v.user_level[1][1] <= level and v.user_level[1][2] >= level then
			if check_crop_exsit(ur,v.id,crop_list) == true and check_seat(v.seat[1],pos) then
				clubv[#clubv + 1] = v
				total_weight = total_weight + v.club_probability 
				if v.club_level > level then
					print("-----***---***---level == "..level.." ---***---v.user_level[1][1] == "..v.user_level[1][1].."v.user_level[1][2] == "..v.user_level[1][2])
				end
			end
		end
	end
	return clubv,total_weight
end

function clubs.refresh_club(ur,club_refresh_cnt)
	local clubv = {} 
	local total_weight = 0
	local random_weight = 0
	local weight = 0
	local crop_list = {}
	local level = ur.base.level
	for i = 1,5 do
		clubv,total_weight = get_club_list(ur,crop_list,i)
		if total_weight >= 1 then
			random_weight = math.random(1,total_weight)
			for i =1,#clubv do
				weight = weight + clubv[i].club_probability
				if weight >= random_weight then
					local crop = corp_gen()
					crop.corpsid = clubv[i].id
					crop_list[#crop_list + 1] = crop
					break
				end
			end
		end
	end
	local club = clubs_gen()
	local cur_club = ur.club
	club.crops = crop_list
	if club_refresh_cnt then
		club.club_refresh_cnt = club_refresh_cnt
	else
		club.club_refresh_cnt = cur_club.club_refresh_cnt or 0
	end
	club.card_framgent = cur_club.card_framgent
	club.violet_framgent = cur_club.violet_framgent or 0
	club.orange_framgent = cur_club.orange_framgent or 0
	club.challengecnt = cur_club.challengecnt or 0
	club.score = cur_club.score
    return club
end

function clubs.add_fragment(ur,fragmentid,count)
	local club = ur.club
	if not club then
		return
	end
	local flag = false
	if fragmentid == 1000 then
		club.violet_framgent = club.violet_framgent + count
	elseif fragmentid == 2000 then
		club.orange_framgent = club.orange_framgent + count
	else
		for i =1,#club.card_framgent do 
			if club.card_framgent[i].card_framgent_id == fragmentid then
				club.card_framgent[i].count = club.card_framgent[i].count + count
				flag = true
				break
			end
		end
		if flag == false then
			for i =1,#club.card_framgent do 
				if club.card_framgent[i].card_framgent_id == 0 then
					club.card_framgent[i].count = count
					club.card_framgent[i].card_framgent_id = fragmentid
					flag = true
					break
				end
			end
		end
		if flag == false then
			local fragment_info = card_framgent_info_gen()
			fragment_info.card_framgent_id = fragmentid
			fragment_info.count = count
			club.card_framgent = club.card_framgent or {}
			club.card_framgent[#club.card_framgent + 1] = fragment_info
		end
	end
	ur:db_tagdirty(ur.DB_CLUB)
end

function clubs.reset_curclub(ur)
	local club_info = ur.club
	club_info.challengecnt = 0
	ur:db_tagdirty(ur.DB_CLUB)
	ur:send(IDUM_NOTICECLUBINFO, {info = club_info})
end

return clubs
