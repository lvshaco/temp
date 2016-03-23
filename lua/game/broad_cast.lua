-------------------interface---------------------
--function task_check_state(task, task_type, parameter1, parameter2)
--function task_accept(task,id)
-------------------------------------------------
local shaco = require "shaco"
local bit32 = require"bit32"
local tbl = require "tbl"
local ipairs = ipairs
local sfmt = string.format
local sfind = string.find
local sub = string.sub
local len = string.len
local floor = math.floor
local userpool = require "userpool"
local tpgamedata = require "__tpgamedata"
local tpautobroadcast = require "__tpautobroadcast"
local tpcard = require "__tpcard"
local tpitem = require "__tpitem"
local tpdazzle = require "__tpdazzle"
local broad_cast = {}
local system_notice = {}
local send_time = 0
local activity_time = 0
--math.randomseed(os.time())


local function Split(szFullString, szSeparator)
	local nFindStartIndex = 1
	local nSplitIndex = 1
	local nSplitArray = {}
	while true do
		local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
		if not nFindLastIndex then
			nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
			break
		end
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
		nFindStartIndex = nFindLastIndex + string.len(szSeparator)
		nSplitIndex = nSplitIndex + 1
	end
	return nSplitArray
end

local function check_cur_time(temp_time,cur_time,temp_type)
	local __time = {}
	local indx = 1
	local year_time = ""
	local hour_time = ""
	for w in string.gmatch(temp_time, "[^,]+") do
		if indx == 1 then
			year_time = w
		--	print("year_time == "..year_time)
		else
			hour_time = w
		--	print("hour_time == "..hour_time)
		end
		indx = indx + 1
	end
	for w in string.gmatch(year_time, "[^/]+") do
		__time[#__time + 1] = tonumber(w)
	end
	if cur_time.year > __time[1] then
		return 4
	end
	local check_flag = false
	if temp_type == 1 then
		if cur_time.month < __time[2] then
			return 4
		elseif cur_time.month == __time[2] then
			if cur_time.day < __time[3] then
				return 4
			elseif cur_time.day == __time[3] then
				check_flag = true
			end
		end
	else
		if cur_time.month > __time[2] then
			return 4
		elseif cur_time.month == __time[2] then
			if cur_time.day > __time[3] then
				return 4
			elseif cur_time.day == __time[3] then
				check_flag = true
			end
		end
	end
	if check_flag then
		__time = {}
		for w in string.gmatch(hour_time, "[^:]+") do
			__time[#__time + 1] = tonumber(w)
		end
	--	tbl.print(__time, "=============init __time", shaco.trace)
		if temp_type == 1 then
			if cur_time.hour < __time[1] then
				return 4
			elseif cur_time.hour == __time[1] then
				if cur_time.min < __time[2] then
					return 4
				elseif cur_time.min == __time[2] then
					if cur_time.sec <= __time[3] then
						return 4
					end
				end
			end
		else
			if cur_time.hour > __time[1] then
				return 4
			elseif cur_time.hour == __time[1] then
				if cur_time.min > __time[2] then
					return 4
				elseif cur_time.min == __time[2] then
					if cur_time.sec >= __time[3] then
						return 4
					end
				end
			end
		end
	end
end

local function check_time(_time)
	local now = shaco.now()//1000
    local cur_time=os.date("*t",now)
	--tbl.print(cur_time, "=============init cur_time ", shaco.trace)
	local indx = 1
	for w in string.gmatch(_time, "[^_]+") do
		if check_cur_time(w,cur_time,indx) then
			return false
		end
		indx = indx + 1
	end 
	return true
end

function broad_cast.init()
	for k,v in pairs(tpautobroadcast) do
		--tbl.print(v, "=============init v", shaco.trace)
		--print("k == "..k)
		local type = v[1].type
		if type == 1 or type == 2 then
			if check_time(v[1].time) then
				system_notice[#system_notice + 1] = v[1]
			end
		end
	end
	--tbl.print(system_notice, "=============init system_notice", shaco.trace)
end

function broad_cast.send_broad_cast(_type,id,item_list,name,ur)
	local notice_list = {}
	if _type == 1 then
		for i = 1,#system_notice do
			local info = system_notice[i]
			if info.type == NOTICE_SYSTEM_T then
				notice_list[#notice_list + 1] = info
			end
		end
	end
	local notice_id = id
	if _type == 1 then
		local indx = math.random(1,#notice_list)
		local info = notice_list[indx]
		notice_id = info.id
	end 
	local conn2user = userpool.get_conn2user()
	for _, ur in pairs(conn2user) do
		ur:send(IDUM_NOTICEBROADCAST,{id = notice_id,info = item_list,name = name})
    end
end

local function update_activity_notice(now)
	for i = 1,#system_notice do
		local info = system_notice[i]
		if info.type == NOTICE_ACTIVITY_T then
			if check_time(info.time) then
				local condition,temp = math.modf((now - activity_time) / info.interval)
				if condition > 0 then
					activity_time = now
					--broad_cast.send_broad_cast(2,info.id,{})
				end
			end
		end
	end
end

function broad_cast.update(now)
	local open_server_time = config.open_server_time --开服时间
	local diffrent_time = now - open_server_time
	local day_cnt,temp = math.modf(diffrent_time/3600)
	--print("day_cnt == "..day_cnt)
    local cur_time=os.date("*t",now)
	local time_state = 0
	local base_time = now
	if (cur_time.hour <= 14 and cur_time.hour >= 12) or (cur_time.hour >= 18 and cur_time.hour <= 20) then
		time_state = 1 --- 高峰
	elseif (cur_time.hour > 14 and cur_time.hour < 18) or (cur_time.hour > 20 and cur_time.hour <= 23) and (cur_time.hour >= 8 and cur_time.hour < 12) then
		time_state = 2  ---平峰
	end
	if day_cnt < 3 then
		if time_state == 1 then
			base_time = 180
		elseif time_state == 2 then
			base_time = 600
		end
	elseif day_cnt >= 3 and day_cnt < 7 then
		if time_state == 1 then
			base_time = 300
		elseif time_state == 2 then
			base_time = 1200
		end
	elseif day_cnt >= 7 then
		if time_state == 1 then
			base_time = 600
		elseif time_state == 2 then
			base_time = 1800
		end
	end
	local condition,temp = math.modf((now - send_time)/base_time)
	if condition > 0 then
		send_time = now
		--broad_cast.send_broad_cast(1,0,{})
	end
	--update_activity_notice(now)
end

local function get_notice(_type)
	for k,v in pairs(tpautobroadcast) do
		local type = v[1].type
		if type == _type then
			return v[1]
		end
	end
end

local function broad_cast_gen()
	return {
		id = 0,
		count = 0,
		original_id = 0,
	}
end

function broad_cast.check_buy_card(ur,card_array,PriceType)
	local card_list = {}
	local falg = false
	for i = 1,#card_array do
		local card = card_array[i]
		if card.card_type == 1 then
			local tp = tpcard[card.cardid]
			if tp and tp.quality >= 4 and tp.quality <= 5 then
				local info = broad_cast_gen()
				info.id = card.cardid
				card_list[#card_list + 1] = info
				falg = true
			end
		end
	end
	local tp_notice 
	if PriceType == 0 then
		tp_notice = get_notice(NOTICE_COIN_CARD_T)
	elseif PriceType == 1 then
		tp_notice = get_notice(NOTICE_GOLD_CARD_T)
	end
	if tp_notice  and  falg then
		broad_cast.send_broad_cast(3,tp_notice.id,card_list,ur.base.name,ur)
	end
end

function broad_cast.check_card_compose(ur,cardid)
	local card_list = {}
	local tp = tpcard[cardid]
	if tp and tp.quality >= 4 and tp.quality <= 5 then
		local info = broad_cast_gen()
		info.id = cardid
		card_list[#card_list + 1] = info
		local tp_notice = get_notice(NOTICE_FRAGEMENT_T)  
		if tp_notice then
			broad_cast.send_broad_cast(3,tp_notice.id,card_list,ur.base.name,ur)
		end
	end
end

function broad_cast.check_card_break_through(ur,card) -------
	local card_list = {}
	local tp = tpcard[card.cardid]
	if tp and card.break_through_num > 0 then
		local info = broad_cast_gen()
		info.id = card.cardid
		info.count = card.break_through_num
		card_list[#card_list + 1] = info
		local tp_notice = get_notice(NOTICE_CARD_BREAK_T)  
		if tp_notice then
			broad_cast.send_broad_cast(3,tp_notice.id,card_list,ur.base.name,ur)
		end
	end
end


function broad_cast.check_weapon_forge(ur,original_id,itemid) -- 锻造------
	local card_list = {}
	local tp = tpitem[itemid]
    shaco.trace('force', itemid, tp)
    if tp then
        shaco.trace('qua', tp.quality)
    end
	if tp and tp.quality >= 5 and tp.quality <= 6 then
		local info = broad_cast_gen()
		info.id = itemid
		info.original_id = original_id
		card_list[#card_list + 1] = info
		local tp_notice = get_notice(NOTICE_FORGE_T)  
		if tp_notice then
			broad_cast.send_broad_cast(3,tp_notice.id,card_list,ur.base.name,ur)
		end
	end
end

function broad_cast.check_weapon_godcast(ur,itemid,refinecnt)  --精炼-------------
	local card_list = {}
	local info = broad_cast_gen()
	info.id = itemid
	info.count = refinecnt
	card_list[#card_list + 1] = info
	local tp_notice = get_notice(NOTICE_GOD_CAST_T)  
	if tp_notice then
		broad_cast.send_broad_cast(3,tp_notice.id,card_list,ur.base.name,ur)
	end
end

function broad_cast.check_gem_compose(ur,gem_level)  --宝石------
	local card_list = {}
	local info = broad_cast_gen()
	info.count = gem_level
	card_list[#card_list + 1] = info
	local tp_notice = get_notice(NOTICE_GEM_COMPOSE_T)  
	if tp_notice then
		broad_cast.send_broad_cast(3,tp_notice.id,card_list,ur.base.name,ur)
	end
end

function broad_cast.check_dazzle_up(ur,original_id,itemid) -- 
	local card_list = {}
	local info = broad_cast_gen()
	info.id = itemid
	info.original_id = original_id
	card_list[#card_list + 1] = info
	local tp_notice = get_notice(NOTICE_DAZZLE_T)  
	if tp_notice then
		broad_cast.send_broad_cast(3,tp_notice.id,card_list,ur.base.name,ur)
	end
end

function broad_cast.check_equip_info(ur,itemid,notice_type) 
	local card_list = {}
	local tp = tpitem[itemid]
	if tp and tp.quality >= ORANGE then
		local info = broad_cast_gen()
		info.id = itemid
		card_list[#card_list + 1] = info
		local tp_notice = get_notice(notice_type)  
		if tp_notice then
			broad_cast.send_broad_cast(3,tp_notice.id,card_list,ur.base.name,ur)
		end
	end
end

local function get_item_color(quality)
	local card_color = {{quality = 3,color = "gold"},{quality = 4,color = "purple"},{quality = 5,color = "orange"},{quality = 6,color = "silver"}}
	for j = 1,#card_color do
		if card_color[j].quality == quality then
			return card_color[j].color
		end
	end
end

local function get_card_color(quality)
	local card_color = {{quality = 1,color = "white"},{quality = 2,color = "green"},{quality = 3,color = "blue"},{quality = 4,color = "purple"},{quality = 5,color = "orange"}}
	for j = 1,#card_color do
		if card_color[j].quality == quality then
			return card_color[j].color
		end
	end
end

local function get_dazzle_color(quality)
	local card_color = {{quality = 0,color = "white"},{quality = 1,color = "green"},{quality = 2,color = "blue"},{quality = 4,color = "purple"},{quality = 5,color = "orange"}}
	for j = 1,#card_color do
		if card_color[j].quality == quality then
			return card_color[j].color
		end
	end
end

local function set_name_color(ids)
	local str = ""
	local cnt = 0
	--local multiple,decimal = math.modf(#ids/2)
	local count = #ids
	for i = 1,count do
		local tp = tpcard[ids[i]]
		--if cnt == multiple and cnt > 0 then
		--	str = str.."[txt:size=20 color=white]"..","
		--end
		local color = get_card_color(tp.quality)
		if color then
			str = str.."[txt:size=20 color="..color.."]"..tp.name
		end
		cnt = cnt + 1
		if cnt ~= count then
			str = str.."[txt:size=20 color=white]"..","
		end
	end
	return str
end

local function set_card_exchange_color(ids)
	local str = ""
	for i = 1,#ids do
		local tp = tpcard[ids[i]]
		local color = get_card_color(tp.quality)
		if color then
			str = str.."[txt:size=20 color="..color.."]"..tp.name
		end
	end
	return str
end

local function set_card_break_through_color(card) --突破
	local str = ""
	local tp = tpcard[card.cardid]
	local color = get_card_color(tp.quality)
	if color then
		str = str.."[txt:size=20 color="..color.."]"..tp.name.."[txt:size=20 color=white]"
	end
	return str,card.break_through_num
end

local function set_weapon_forge(common) -- 锻造
	local card_list = {}
	local tp_original = tpitem[common.original_id]
	local original_color = get_item_color(tp_original.quality)
	local tp_outputEquip = tpitem[common.outputEquip]
	local output_color = get_item_color(tp_outputEquip.quality)
	local original_name = "[txt:size=20 color="..original_color.."]"..tp_original.name.."[txt:size=20 color=white]"
	local output_name = "[txt:size=20 color="..output_color.."]"..tp_outputEquip.name.."[txt:size=20 color=white]"  
    return original_name,output_name
end

local function set_weapon_godcast(common)  --精炼
	local tp = tpitem[common.itemid]
	local color = get_item_color(tp.quality)
	local str = "[txt:size=20 color="..color.."]"..tp.name.."[txt:size=20 color=white]"
	return str,common.refinecnt
end

local function set_dazzle_up(common)-- original_id,itemid) -- 
	local original_tp = tpdazzle[common.original_id]
	local original_color = get_dazzle_color(original_tp.quality)
	local cur_tp = tpdazzle[common.cur_id]
	local cur_color = get_dazzle_color(cur_tp.quality)
	local original_name = "[txt:size=20 color="..original_color.."]"..original_tp.name.."[txt:size=20 color=white]"
	local cur_name = "[txt:size=20 color="..output_color.."]"..cur_tp.name.."[txt:size=20 color=white]" 
	return original_name,cur_name
end

local function set_equip_info(equipid) 
	local tp = tpitem[equipid]
	--print("tp.quality ==== "..tp.quality)
	local color = get_item_color(tp.quality)
	local str = "[txt:size=20 color="..color.."]"..tp.name.."[txt:size=20 color=white]"
    return str
end

function broad_cast.set_borad_cast(ur,common,notice_type)
	local tp_notice 
	local str = ""
	tp_notice = get_notice(notice_type)
	local name = ""
	name = name.."[txt:size=20 color=orange]"..ur.base.name.."[txt:size=20 color=white]"
	--print(tp_notice.content)
	local front_content = "[txt:size=20 color=white]"..tp_notice.content
	if notice_type == NOTICE_FRAGEMENT_T then -- 碎片合成公告
		local card_name = set_card_exchange_color(common)
		str = string.format(front_content,name,card_name)
	elseif notice_type == NOTICE_COIN_CARD_T or notice_type == NOTICE_GOLD_CARD_T  or notice_type == NOTICE_MYSTERY_BAG_T then --金币、钻石、神秘 抽卡公告
		local card_name = set_name_color(common)
		str = string.format(front_content,name,card_name)
	elseif notice_type == NOTICE_CARD_BREAK_T then --突破公告
		local card_name,break_through_num = set_card_break_through_color(common)
		str = string.format(front_content,name,card_name,break_through_num)
	elseif notice_type == NOTICE_FORGE_T then -- 武器锻造公告
		local original_name,output_name = set_weapon_forge(common)
		str = string.format(front_content,name,original_name,output_name)
	elseif notice_type == NOTICE_GOD_CAST_T then --武器精练公告
		local equip_name,refinecnt = set_weapon_godcast(common)
		str = string.format(front_content,name,equip_name,refinecnt)
	elseif notice_type == NOTICE_GEM_COMPOSE_T then  --宝石合成公告
		str = string.format(front_content,name,common)
	elseif notice_type == NOTICE_DAZZLE_T then --炫纹公告
		local original_name,cur_name = set_dazzle_up(common)
		str = string.format(front_content,name,original_name,cur_name)
    elseif notice_type == NOTICE_LADDER_T then --天梯公告
        local equip_name = set_equip_info(common)
		str = string.format(front_content,name,equip_name)
	elseif notice_type == NOTICE_CLUB_T then --俱乐部公告
		local equip_name = set_equip_info(common)
		str = string.format(front_content,name,equip_name)
	elseif notice_type == NOTICE_EQUIP_COMPOSE_T then --装备熔炼公告
		local equip_name = set_equip_info(common)
		str = string.format(front_content,name,equip_name)
	end
	local conn2user = userpool.get_conn2user()
	for _, ur in pairs(conn2user) do
		ur:send(IDUM_NEWNOTICEBROADCAST,{content = str})
    end
end

return broad_cast
