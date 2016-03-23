-------------------interface---------------------

-------------------------------------------------
local shaco = require "shaco"
local tptask = require "__tptask"
local bit32 = require"bit32"
local tbl = require "tbl"
local rcall = shaco.callum
local CTX = require "ctx"
local pb = require "protobuf"
local ipairs = ipairs
local sfmt = string.format
local sfind = string.find
local sub = string.sub
local len = string.len
local floor = math.floor
local tonumber = tonumber
local tpgamedata = require "__tpgamedata"
local tpfestival_main = require "__tpfestival_main"
local tpfestival_bingtest_moneytower = require "__tpfestival_bingtest_moneytower"
local tpfestival_bingtest_exptower = require "__tpfestival_bingtest_exptower"
local tpfestival_bingtest_endlesstower = require "__tpfestival_bingtest_endlesstower"
local tpfestival_openservice = require "__tpfestival_openservice"
local tpdeadcanyon = require "__tpdeadcanyon"
local config = require "config"
local userpool = require "userpool"
local mail = require "mail"
local util = require "util"
local itemop = require "itemop"
local rank_fight = require "rank_fight"

local activity_fast = {}
local open_activity = {}
--极限挑战
local ultimate_money_list = {}
--极速时刻
local speed_exp_list = {}
local act_wood_barrel_rank = {} --木桶阵

local five_money_ranks = {}
local five_exp_ranks = {}
local activity_money = {}
local start_update = false
local clear_flag = false
local other_mail_id = 100000
local sync_update_time = 0
local last_open_time = {}
local stage_list = {}

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

local function wood_barrel_gen(score,name,roleid,rank)
	return {score = score,name = name,roleid = roleid,rank = rank}
end 

local function sort_wood_barrel()
	local function sort_score_Asc(a,b)
		if a.score == b.score then return a.name >= b.name 
		else return a.score > b.score end
	end
	table.sort(act_wood_barrel_rank,sort_score_Asc)
	local indx = 0
	for k,v in pairs(act_wood_barrel_rank) do
		indx = indx + 1
		v.rank = indx
	end
end

local function activity_ids_gen()
	return {
		activity_id = 0,-- 
	}
end

local function money_gen()
	return {
		roleid = 0,
		name = "",
		reward_money = 0,
		difficulty = 0,
		date_time = 0,
		rank = 0,
	}
end

local function exp_gen()
	return {
		roleid = 0,
		name = "",
		over_time = 0,
		difficulty = 0,
		date_time = 0,
		rank = 0,
	}
end

--local conn2user = userpool.get_conn2user()
	--for _, ur in pairs(conn2user) do
		--ur:send(IDUM_ACKLADDERRANK, {activity_list = activity_list})
    --end
local function mail_gen()
	return {
		mail_read_time=0,
		mail_id=0,
		mail_type = 0,
		mail_theme = "",
		mail_content = "",
		mail_gold = 0,
		mail_cion = 0,
		item_info = {},
		read_save = 0, 
		unread = 0,
		send_time = 0,
	}
end
local function mail_item_gen()
	return {
		item_type = 0,
		item_id = 0,
		item_cnt = 0,
		hole_cnt = 0,
		washcnt = 0,
	}
end

local function get_mail_item(id,num,hole_cnt,wash_cnt,item_type)
	local items = {}
	local item_info = mail_item_gen()
	item_info.item_type = item_type
	item_info.item_id = id
	item_info.item_cnt = num
	item_info.hole_cnt = hole_cnt or 0	
	item_info.washcnt = wash_cnt or 0
	items[#items + 1] = item_info
	return items
end

local function create_mail_id(mailv)
	local old_mails = mailv.old_info
	local mail_list = mailv.data
	local create_id = other_mail_id
	while true do
		local flag = false
		for i = 1,#old_mails do
			local info = old_mails[i]
			if info.mail_id == create_id then
				flag = true
				break
			end
		end
		for i = 1,#mail_list do
			local info = mail_list[i]
			if info.mail_id == create_id then
				flag = true
				break
			end
		end
		if not flag then
			return create_id
		end
		create_id = create_id + 1
	end
end

local function get_activity_reward(tp,rank,difficulty)
	local itemid = 0
	local money_type = 0
	local cnt = 0
	for k,v in ipairs(tp) do
		if v.Difficult == difficulty  then
			if v.BOUNS[1] == 1 then --资源
				money_type = v.BOUNS[2]
			else --道具
				itemid = v.BOUNS[2]
			end
			cnt = v.BOUNS[3]
			break
		end
	end
	return itemid,money_type,cnt
end

local function check_special_activity(continue_time,create_time)
	local cur_time = shaco.now()//1000
	if continue_time * 60 + create_time >= cur_time then
		--print(" continue_time * 60 + create_time ==== "..(continue_time * 60 + create_time).."-----=== cur_time === "..cur_time)
		return false
	end
	return true
end

local function sync_type_four_activity()
	local conn2user = userpool.get_conn2user()
	for _, ur in pairs(conn2user) do
		local close_activity = {}
		for i =1,#ur.special_activity do
			for k,v in ipairs(open_activity) do
				local flag = true
				if v.TIME_TYPE == 4 and ur.special_activity[i] == v.ID then
					if not check_special_activity(v.TIME3,ur.base.create_time) then
						ur.special_activity[i] = 0
						close_activity[#close_activity + 1] = v.ID
					end
				end
			end
		end
		if #close_activity > 0 then
			--print(close_activity,"close_activity========= ")
			ur:send(IDUM_SYNCCLEARACTIVITY, {activity_ids = close_activity})
		end
	end
end

local function add_activity_mail(_type,rank,stage,mailv)
	local itemid = 0
	local money_type = 0
	local cnt = 0
	local mail_info = mail_gen()
	mail_info.mail_type = 1
	local tp
	local string_name = ""
	if _type == 1 then --money 
		tp = tpfestival_bingtest_moneytower
		string_name = "大试练极限挑战"
	else  --exp
		tp = tpfestival_bingtest_exptower
		string_name = "大试练极速时刻"
	end
	local items = mail.get_activity_reward(tp,rank,stage)
	mail_info.item_info = items
	mail_info.unread = 86400000
	mail_info.read_save = 0
	mail_info.mail_theme = string_name.."奖励"
	mail_info.mail_content = string_name

	local mail_list = mailv.data
	mail_info.mail_id = create_mail_id(mailv)
	mail_info.send_time = shaco.now()//1000
	mail_list[#mail_list + 1] = mail_info
end

local function init_money_record(target_list)
	local string_record = ""
	for k,v in ipairs(target_list) do
		local string_info = ""..v.roleid..","..v.difficulty..","..v.rank..";"
		string_record = string_record..string_info
	end
	return string_record
end

local function romve_send_reward_rank(record,index)
	local string_record = ""
	for i = index + 1,#record do
		string_record = string_record..record[i]
	end
	return string_record
end

local function save_local()
	local f = io.open(".activity_money.tmp", "w")
	--local string_list = f:read("*a")
	local string_money_record = init_money_record(ultimate_money_list)
	--print(" string_money_record === "..string_money_record)
	f:write(tostring(string_money_record))
	f:close()
	local f = io.open(".activity_exp.tmp", "w")
	--local string_list = f:read("*a")
	local string_exp_record = init_money_record(speed_exp_list)
	f:write(tostring(string_exp_record))
	f:close()
end

local function read_endless_activity_cnt()
	local f = io.open(".endless_activity.tmp", "a+")
	local string_list = f:read("*a")
	f:close()
	local record = Split(string_list,";")
	for k,v in ipairs(record) do
		local result = Split(v,",")
		local id = tonumber(result[1])
		if id then
			stage_list[id] = tonumber(result[2])
			last_open_time[id] = tonumber(result[3])
		end
	end
	--if record then
	--	local id = tonumber(record[1]) or 0
	--	endless_activity_cnt = tonumber(record[1]) or 0
	--	last_open_time = tonumber(record[2]) or 0
	--end
end

local function save_endless_activity_cnt(id_array)
	local now = shaco.now()//1000
    local now_day = util.second2day(now)
	local string_content = ""
	for i = 1,#id_array do	
		local flag = false
		local id = id_array[i]
		if last_open_time[id] then
			local last_day = util.second2day(last_open_time[id])
			 if now_day ~= last_day then
				stage_list[id] = stage_list[id] + 1
				flag =true
			 end
		else
			last_open_time[id] = now
			stage_list[id] = 1
			flag = true
		end
		if flag then
			string_content = string_content..""..id..","..stage_list[id]..","..now..";"
		end
	end
	if string_content ~= "" then
		local f = io.open(".endless_activity.tmp", "w")
		f:write(string_content)
		f:close()
    end
end
 
local function provide_activity_reward()
	save_local()
	shaco.fork( function()
		local tmp_file = {".activity_money.tmp",".activity_exp.tmp"}
		local stage = 1
		for j =1,2 do
			if j == 1 then
				stage = stage_list[4]
			else
				stage = stage_list[5]
			end
			if not stage then
				stage = 1
			end
			local f = io.open(tmp_file[j], "a+")
			local string_list = f:read("*a")
			--print(" string_list ====  ------- "..string_list)
			f:close()
			--print("-------- string_liststring_list === "..string_list.."  j == "..j.." tmp_file[j] === "..tmp_file[j])
			local record = Split(string_list,";")
			--local record = Split(result,";")
			for i =1,#record do
				local result = Split(record[i],",")
				local roleid = tonumber(result[1])
				local difficulty = tonumber(result[2])
				local rank = tonumber(result[3])
				if roleid and roleid > 0 then
					local ur = userpool.find_byid(roleid)
					if ur then
						mail.add_activity_mail(ur,j,rank,stage)
					else
						local mail= rcall(CTX.db, "L.ex", {roleid=roleid, name="mail"})
						if mail then
							mail = pb.decode("mail_list", mail)
						else
							mail = {}
							mail.data = {}
							mail.old_info = {}
						end
					   -- tbl.print(mail,"-------222222222- v.name ===")
						add_activity_mail(j,rank,stage,mail)
						shaco.sendum(CTX.db, "S.ex", {
							name="mail",
							roleid=roleid,
							data=pb.encode("mail_list", {data = mail.data,old_info = mail.old_info}),
						})
					end
					local f = io.open(tmp_file[j], "w")
					local string_info = romve_send_reward_rank(record,i)
					f:write(tostring(string_info))
					f:close()
				end
			end
		end
	end)
end

local function sort_exp_Asc(a,b)
	if a.difficulty == b.difficulty then
		if a.over_time == b.over_time then 
			return a.name >= b.name 
		else 
			return a.over_time < b.over_time
		end
	else
		return  a.difficulty > b.difficulty
	end
end

function activity_fast.load_activity_exp(all)
	local cur_time = shaco.now()//1000 --当前时间
	local now_day = util.second2day(cur_time)
	for _, v in ipairs(all) do
		local info = exp_gen()
		info.roleid = tonumber(v.roleid)
		info.name = v.name
		info.over_time = tonumber(v.over_time)
		info.difficulty = tonumber(v.difficulty)
		info.date_time = tonumber(v.date_time)
		info.rank = tonumber(v.rank)
		local last_day = util.second2day(info.date_time)
		--print("now_day === "..now_day.."  last_day === "..last_day)
		if now_day == last_day then
		--	clear_flag = true
			speed_exp_list[#speed_exp_list + 1] = info
		end
	end
	table.sort(speed_exp_list,sort_exp_Asc)
	for i = 1,#speed_exp_list do
		speed_exp_list[i].rank = i
	end
end

function activity_fast.load(all)
	local cur_time = shaco.now()//1000 --当前时间
	local now_day = util.second2day(cur_time)
    for _, v in ipairs(all) do
		local info = money_gen()
		info.roleid = tonumber(v.roleid)
		info.name = v.name
		info.reward_money = tonumber(v.reward_money)
		info.difficulty = tonumber(v.difficulty)
		info.date_time = tonumber(v.date_time)
		info.rank = tonumber(v.rank)
		local last_day = util.second2day(info.date_time)
		if now_day == last_day then
			ultimate_money_list[#ultimate_money_list + 1] = info
		end
	end
	local function sort_score_Asc(a,b)
		if a.reward_money == b.reward_money then return a.name >= b.name 
		else return a.reward_money > b.reward_money end
	end
	table.sort(ultimate_money_list,sort_score_Asc)
	for i = 1,#ultimate_money_list do
		ultimate_money_list[i].rank = i
	end
end

local function get_activity_rank(act,ectype_type)
	for i = 1,#act.activity_rank do
		local rank = act.activity_rank[i]
		if rank.ectype_type == ectype_type then
			return rank
		end
	end
end

function activity_fast.load_activity_data(activity)
	--local actv = pb.decode("activity_data", activity.data)
	for _, v in ipairs(activity) do
		local roleid = tonumber(v.roleid)
		local act = pb.decode("activity_data", v.data).data
		--tbl.print(actv,"activity.roleid === ")
		local base = rcall(CTX.db, "L.base", roleid) 
		if base then
			base = pb.decode("role_base", base)
		end
		if act.activity_rank then
			local rank = get_activity_rank(act,TOLL_GATE_RANK_OILDRUM_T)--act.activity_rank[TOLL_GATE_RANK_OILDRUM_T]
			if rank then
				--tbl.print(rank,"rank =====  ")
				if rank.score > 0 then
					local own_rank = wood_barrel_gen(rank.score,base.name,roleid,#act_wood_barrel_rank + 1)
					--act_wood_barrel_rank[roleid] = own_rank
					act_wood_barrel_rank[#act_wood_barrel_rank + 1] = own_rank
				end
			end
		end
	end
	sort_wood_barrel()
	--tbl.print(act_wood_barrel_rank,"act_wood_barrel_rank ====== ")
		--[[local rank = act.activity_rank[v.toll_gate_type]
		if rank then
			rank.difficulty = v.difficulty
		else
			local rank_data = activity_ectype_rank_gen()
			rank_data.ectype_type = v.toll_gate_type
			act.activity_rank[v.toll_gate_type] = rank_data
		end
	--	own_rank = wood_barrel_gen(rank_data.score,ur.base.name,roleid)
		--act_wood_barrel_rank[roleid] = own_rank
	end]]
	--provide_activity_reward()
end

local function is_act_open(v, cur_time, open_server_elapsed)
    if v.TIME_TYPE == 0 then
        return true
    elseif v.TIME_TYPE == 1 then
        for i =1,#v.TIME1 do
            if (cur_time.wday-1) == v.TIME1[i] then
                if cur_time.hour > v.TIME2[1] or (cur_time.hour == v.TIME2[1] and cur_time.min >= v.TIME2[2]) then
                    local cur_sec = ((cur_time.hour - v.TIME2[1]) * 60 + cur_time.min - cur_time.min)*60 + cur_time.sec
                    if cur_sec < v.TIME3 * 60 then
                        return true
                    end
                end
            end
        end
    elseif v.TIME_TYPE == 2 then
        for i = 1,#v.TIME1,2 do
            if v.TIME1[i] == cur_time.month and v.TIME1[i + 1] == cur_time.day then
                if cur_time.hour > v.TIME2[1] or (cur_time.hour == v.TIME2[1] and cur_time.min >= v.TIME2[2]) then
                    local cur_sec = ((cur_time.hour - v.TIME2[1]) * 60 + cur_time.min - cur_time.min)*60 + cur_time.sec
                    if cur_sec < v.TIME3 * 60 then
                        return true
                    end
                end
            end
        end
    elseif v.TIME_TYPE == 3 then
        local start_offset =(v.TIME1[1]-1)*86400
        local persist_time = v.TIME3*60 +start_offset - 302700
        --local open_day_base = util.daybase(open_server_time)
        --local elapsed = now - open_day_base
        if (v.TIME3==0 or open_server_elapsed < persist_time) and open_server_elapsed>=start_offset then
            return true
        end
	elseif v.TIME_TYPE == 4 then
		return true
    end
end

local function get_rank_list()
	local f = io.open(".srongest_fight.tmp", "a+")
	local string_content = f:read("*a")
	f:close()
	local string_list = {}
	for w in string.gmatch(string_content, "[^;]+") do
		string_list[#string_list + 1] = w
	end
	local function fight_rank_gen()
		return {
			rank = 0,
			fight = 0,
			name = "",
			roleid = 0,
			flag = 0,
		}
	end
	local rank_list = {}
	for k,v in ipairs(string_list) do
		local index = 1
		local temp_list = {}
		local fight_info = fight_rank_gen()
		for w in string.gmatch(v, "[^,]+") do
			if index == 1 then
				fight_info.rank = tonumber(w)
			elseif index == 2 then
				fight_info.fight = tonumber(w)
			elseif index == 3 then
				fight_info.name = w
			elseif index == 4 then
				fight_info.roleid = tonumber(w)
			elseif index == 5 then
				fight_info.flag = tonumber(w)
			end
			index = index + 1
		end
		rank_list[#rank_list + 1] = fight_info
	end
	return rank_list
end

local function save_strongest_fight_local(role2rank)
	local f = io.open(".srongest_fight.tmp", "w")
	--local string_list = f:read("*a")
	local string_content = ""
	for k,v in ipairs(role2rank) do
		local content = ""
		content = v.rank..","..v.fight..","..v.name..","..v.roleid..","..v.flag
		string_content = string_content..content..";"
	end
	f:write(tostring(string_content))
	f:close()
end

local function get_reward_data(rank,reward_list)
	local tp
	for i = 1,#reward_list do
		local data = reward_list[i]
		if data.Parameter >= rank then
			if i ==1 then
				tp = data
			else
				local front_data = reward_list[i - 1]
				if rank >= front_data.Parameter + 1 then
					tp = data
				end
			end
		end
	end
	return tp
end

local function send_strongest_fight_mail(race,items,mailv)
	local mail_info = mail_gen()
	mail_info.mail_type = 1
	local items = mail.get_strongest_fight_reward(race,items)
	mail_info.item_info = items
	--tbl.print(items," off_line  items ====== ")
	mail_info.unread = 86400000
	mail_info.read_save = 0
	mail_info.mail_theme = "强力高手排名奖励"
	mail_info.mail_content = "鉴于你在强力高手排行榜的表现，特发放以下奖励。"
	local mail_list = mailv.data
	mail_info.mail_id = create_mail_id(mailv)
	mail_info.send_time = shaco.now()
	mail_list[#mail_list + 1] = mail_info
end

local function send_fight_rank_reward(rank_list)
	local flag = false
	local reward_list = tpfestival_openservice[4]
	for k,v in ipairs(rank_list) do
		local rank = v.rank
		local tp = get_reward_data(rank,reward_list)
		local roleid = v.roleid
		--if v.name == "灵思无声" then
			--return
		--end
		if tp and v.flag == 0 and roleid > 0 then
			v.flag = 1
			flag = true
			local ur = userpool.find_byid(roleid)
			if ur then
				mail.send_strongest_fight_mail(ur,tp.Items)
			else
				local base = rcall(CTX.db, "L.base",roleid) 
				if base then
					base = pb.decode("role_base", base)
				end
				local mail= rcall(CTX.db, "L.ex", {roleid=roleid, name="mail"})
				if mail then
					mail = pb.decode("mail_list", mail)
				else
					mail = {}
					mail.data = {}
					mail.old_info = {}
				end
				send_strongest_fight_mail(base.race,tp.Items,mail)
				shaco.sendum(CTX.db, "S.ex", {
					name="mail",
					roleid=roleid,
					data=pb.encode("mail_list", {data = mail.data,old_info = mail.old_info}),
				})
			end
			save_strongest_fight_local(rank_list)
		end
	end
	if not flag  then
		local f = io.open(".srongest_fight.tmp", "w")
		local string_content = ""
		f:write(tostring(string_content))
		f:close()
	end
end

function activity_fast.init()
	read_endless_activity_cnt()
	local now = shaco.now()//1000 --当前时间
	local cur_time=os.date("*t",now)
    local open_server_elapsed= now - util.daybase(config.open_server_time)
	local id_array = {}
	local flag = false
	for k,v in ipairs(tpfestival_main) do
        if is_act_open(v, cur_time, open_server_elapsed) then
			if v.ID == 3 or v.ID == 4 or v.ID == 5 then
				id_array[#id_array + 1] = v.ID
				flag = true
			end
			open_activity[#open_activity + 1] = v
		end
	end
	if flag then
		save_endless_activity_cnt(id_array)
	end
	start_update = true
	local rank_list = get_rank_list()
	send_fight_rank_reward(rank_list)
	--tbl.print(open_activity, "open_activity")
end

local function sync_activity_list()
	local conn2user = userpool.get_conn2user()
	for _, ur in pairs(conn2user) do
		local activity_list = {}
		for k,v in ipairs(open_activity) do
			if not check_special_activity(v.TIME3,ur.base.create_time) then
				local info = activity_ids_gen()
				info.activity_id = v.ID
				activity_list[#activity_list + 1] = info
			end
		end
		ur:send(IDUM_NOTICEOPENACTIVITYLIST, {activity = activity_list, own_activity = ur.activity})
		--ur:send(IDUM_ACKLADDERRANK, {activity_list = activity_list})
    end
end

function activity_fast.provide_strongest_fight_reward()
	local role2rank = rank_fight.get_rank_list()
	save_strongest_fight_local(role2rank)
	shaco.fork( function()
		local rank_list = get_rank_list()
		send_fight_rank_reward(rank_list)
	end)
end

local function check_open_activity_over(now)
	local cur_time=os.date("*t",now)
    local open_server_elapsed= now - util.daybase(config.open_server_time)
	local over_activity = {}
	for k,v in ipairs(open_activity) do
        if not is_act_open(v, cur_time, open_server_elapsed) then
            over_activity[#over_activity + 1] = v.ID
			if v.ID == 10 then
				activity_fast.provide_strongest_fight_reward()
			end
        end
    end
	local function check_id_exist_over_activity(over_activity,id)
		for j = 1,#over_activity do
			if id == over_activity[j] then
				return true
			end
		end
		return false
	end
	
	if #over_activity > 0 then
		--tbl.print(open_activity[1],"-------- front === ")
		local i = 1
		while open_activity[i] do
			if check_id_exist_over_activity(over_activity,open_activity[i].ID) then
				table.remove(open_activity,i)
			else
				i = i + 1
			end
		end
		--tbl.print(open_activity,"---------back-------")
		sync_activity_list()
    end
	
end

local function check_activity_exist(id)
	for k,v in ipairs(open_activity) do
		if v.ID == id then
			return false
		end
	end
	return true
end

local function sync_endless_activity_cnt()
	local conn2user = userpool.get_conn2user()
	for _, ur in pairs(conn2user) do
		ur:send(IDUM_SYNCENDLESSACTIVITYCNT, {endless_activity_cnt = stage_list[3],activity_money_stage = stage_list[4],activity_exp_stage = stage_list[5]})
    end
end

local function check_new_activity(now)
	local flag = false
	local cur_time=os.date("*t",now)
    local open_server_elapsed= now - util.daybase(config.open_server_time)
	local id_array = {}
	local special_flag = false
	for k,v in ipairs(tpfestival_main) do
        if is_act_open(v, cur_time, open_server_elapsed) then
            if check_activity_exist(v.ID) then
				if v.ID == 3 or v.ID == 4 or v.ID == 5 then
					special_flag = true
					id_array[#id_array + 1] = v.ID
				end
                open_activity[#open_activity + 1] = v
                flag = true
            end
        end
    end
	if special_flag then
		save_endless_activity_cnt(id_array)
		sync_endless_activity_cnt()
	end
	return flag
end

local function get_rank_gen(tp_list)
	local own_rank = {}
	local five_ranks = {}
	for k,v in ipairs(tp_list) do
		
		if v.rank <= 50 then
			five_ranks[#five_ranks + 1] = v
		end
	end
	return own_rank,five_ranks
end

local function sync_update_rank_info()
	local function sort_score_Asc(a,b)
		if a.reward_money == b.reward_money then return a.name >= b.name 
		else return a.reward_money > b.reward_money end
	end
	table.sort(ultimate_money_list,sort_score_Asc)
	for i = 1,#ultimate_money_list do
		ultimate_money_list[i].rank = i
	end
	--tbl.print(ultimate_money_list,"ultimate_money_list === ")

	local five_ranks = {}
	five_ranks = get_rank_gen(ultimate_money_list)
	for k,v in ipairs(ultimate_money_list) do
		local ur = userpool.find_byid(v.roleid)
		if ur then
			local own_rank = {}
			if v.roleid == ur.base.roleid then
				own_rank = v
			end
			ur:send(IDUM_ACKACTIVITYMONEYRANK, {five_ranks = five_ranks,own_rank = own_rank})
		end
	end
	
	table.sort(speed_exp_list,sort_exp_Asc)
	for i = 1,#speed_exp_list do
		speed_exp_list[i].rank = i
	end
	--own_rank = {}
	--five_ranks = {}
	five_ranks = get_rank_gen(speed_exp_list)
	
	for k,v in ipairs(speed_exp_list) do
		local ur = userpool.find_byid(v.roleid)
		if ur then
			local own_rank = {}
			if v.roleid == ur.base.roleid then
				own_rank = v
			end
			ur:send(IDUM_ACKACTIVITYEXPRANK, {five_ranks = five_ranks,own_rank = own_rank})
		end
	end
	rank_fight.sync_update_rank_info()
	local _rank = rank_fight.get_all_rank()
	for k, v in ipairs(_rank) do
		local ur = userpool.find_byid(v.roleid)
		if ur then
			local my_info = rank_fight.get_own_rank_info(v.roleid)
			local need_list = rank_fight.get_need_rank_list()
			ur:send(IDUM_ACKBATTLERANK, {ranks = need_list,own_rank = my_info})
		end
	end
end

local function sync_player_activity_data()
	local player_list = userpool.get_conn2user()
	for _,ur in pairs(player_list) do
		activity_fast.req_open_activity_list(ur)
	end
		--if ur then
end

function activity_fast.update(now)
	if not start_update then
		return
	end
	local now = now//1000
	local cur_time=os.date("*t",now)
	check_open_activity_over(now)
	if check_new_activity(now) then
		sync_activity_list()
	end
	if (cur_time.hour == 24 or cur_time.hour == 0) and not clear_flag then
		clear_flag = true
		provide_activity_reward()
		shaco.sendum(CTX.db, "L.delete", {
			name="activity_money",
		})
		shaco.sendum(CTX.db, "L.delete", {
			name="activity_exp",
		})
		--rcall(CTX.db, "L.delete", {name="activity_money"})
		ultimate_money_list = {}
		speed_exp_list = {}
		sync_player_activity_data()
	elseif cur_time.hour >= 1 and cur_time.hour ~= 24 and clear_flag then
		clear_flag = false
	end
	if sync_update_time > 0 then
		local difference_time = now- sync_update_time
		if difference_time>=300 then -- todo 300 then
			sync_update_time =now 
			sync_update_rank_info()
			sync_type_four_activity()
		end
	else
		if sync_update_time == 0 then
			sync_update_time =now 
		end
	end
	--DELETE * FROM table_name
end

function activity_fast.req_open_activity_list(ur)
	local activity_list = {}
	for k,v in ipairs(open_activity) do
		local flag = true
		if v.TIME_TYPE == 4 then
			if not check_special_activity(v.TIME3,ur.base.create_time) then
				flag = false
			else
				ur.special_activity[#ur.special_activity + 1] = v.ID
			end
		end
		if flag then
			local info = activity_ids_gen()
			info.activity_id = v.ID
			activity_list[#activity_list + 1] = info
		end
	end
--	tbl.print(activity_list, "activity_list", shaco.trace)
   -- shaco.trace(ur.activity)
    --tbl.print(ur.activity, "act", shaco.trace)
	ur:send(IDUM_NOTICEOPENACTIVITYLIST, {activity = activity_list,endless_activity_cnt = stage_list[3],activity_money_stage = stage_list[4],activity_exp_stage = stage_list[5],activity_own = ur.activity})
	--ur:send(IDUM_NOTICEOPENACTIVITYINFO, {own_activity = ur.activity})
end

function activity_fast.get_activity_open(activity_id)
	for k,v in ipairs(open_activity) do
		if v.ID == activity_id then
            return v
		end
	end
end

function activity_fast.req_activity_money_rank(ur)
	local own_rank = {}
	local five_ranks = {}
	for k,v in ipairs(ultimate_money_list) do
		if v.roleid == ur.base.roleid then
			own_rank = v
		end
		if v.rank <= 50 then
			five_ranks[#five_ranks + 1] = v
		end
	end
	--tbl.print(target_list,"target_list ==== ")
--	tbl.print(five_ranks,"five_ranks =====")
	--tbl.print(own_rank,"own_rank =====")
	ur:send(IDUM_ACKACTIVITYMONEYRANK, {five_ranks = five_ranks,own_rank = own_rank})
end

local function get_own_rank(target_list,roleid)
	for k,v in ipairs(target_list) do
		if v.roleid == roleid then
			return v
		end
	end
end

function activity_fast.balance_money_rank(ur,difficulty,coin)
	local act = ur.activity
	local own_rank = get_own_rank(ultimate_money_list,ur.base.roleid)
	if not own_rank then
		local info = money_gen()
		info.roleid = ur.base.roleid
		info.name = ur.base.name
		info.reward_money = coin
		info.difficulty = difficulty
		info.date_time = shaco.now()//1000
		ultimate_money_list[#ultimate_money_list + 1] = info
	else
		if own_rank.reward_money < coin then
			own_rank.reward_money = coin
		end
	end
	local function sort_score_Asc(a,b)
		if a.reward_money == b.reward_money then return a.name >= b.name 
		else return a.reward_money > b.reward_money end
	end
	table.sort(ultimate_money_list,sort_score_Asc)
	for i = 1,#ultimate_money_list do
		ultimate_money_list[i].rank = i
	end
	activity_fast.req_activity_money_rank(ur)
	act.money_cnt = coin
	ur:db_tagdirty(ur.DB_ACTIVITY)
	ur:db_tagdirty(ur.DB_ACTIVITY_MONEY)
end

function activity_fast.req_activity_exp_rank(ur)
	local own_rank = {}
	local five_ranks = {}
	local target_list = speed_exp_list
	for k,v in ipairs(target_list) do
		if v.roleid == ur.base.roleid then
			own_rank = v
		end
		if v.rank <= 50 then
			five_ranks[#five_ranks + 1] = v
		end
	end
	ur:send(IDUM_ACKACTIVITYEXPRANK, {five_ranks = five_ranks,own_rank = own_rank})

end


function activity_fast.balance_exp_rank(ur,difficulty,over_time)
	local act = ur.activity
	local own_rank = get_own_rank(speed_exp_list,ur.base.roleid)
	if not own_rank then
		local info = exp_gen()
		info.roleid = ur.base.roleid
		info.name = ur.base.name
		info.over_time = over_time
		info.difficulty = difficulty
		info.date_time = shaco.now()//1000
		speed_exp_list[#speed_exp_list + 1] = info
	else
		if own_rank.over_time < over_time then
			own_rank.over_time = over_time
		end
	end
	table.sort(speed_exp_list,sort_exp_Asc)
	for i = 1,#speed_exp_list do
		speed_exp_list[i].rank = i
	end
	activity_fast.req_activity_exp_rank(ur)
	--local activity = ur.activity
	--activity.money_difficulty = difficulty
	act.exp_time = over_time
	ur:db_tagdirty(ur.DB_ACTIVITY)
	ur:db_tagdirty(ur.DB_ACTIVITY_EXP)
end

-- helper
local function has_awarded(flags, value)
    for k, v in ipairs(flags) do
        if v == value then
            return true
        end
    end
    return false
end

function activity_fast.get_festival_bingtest_endlesstower(value)
	local equal = 0
	local greater_than = 0
	local greater_indx = 0
	local less_than = 0
	local less_indx = 0
	local max_than = 0
	local max_indx = 0
	local result_list = {}
	local tp
	local _value = value
	if _value  > 10 then
		--_value = 10
		return tp
	end
	local endless_activity_cnt = stage_list[3]
	if not endless_activity_cnt then
		return tp
	end
	for k,v in ipairs(tpfestival_bingtest_endlesstower) do
		if v.FLOOR == _value then
			if endless_activity_cnt == v.Stage then
				equal = #result_list + 1
			end
			if endless_activity_cnt > v.Stage then
				if greater_than < v.Stage then
					greater_than = v.Stage
					greater_indx = #result_list + 1
				end
			end
			if endless_activity_cnt < v.Stage then
				if less_than == 0 then
					less_than = v.Stage
					less_indx = #result_list + 1
				end
				if less_than > v.Stage then
					less_than = v.Stage
					less_indx = #result_list + 1
				end
			end
			if max_than < v.Stage then
				max_than = v.Stage
				max_indx = #result_list + 1
			end
			result_list[#result_list + 1] = v
		end
	end	
	if equal >0 then
		tp = result_list[equal]
	else
		if greater_than > 0 and less_than > 0 then
			tp = result_list[greater_indx]
		else
			tp = result_list[max_indx]
		end
	end
	return tp
end

function activity_fast.check_activity_open(ectype_type)
	local scene_id = 0
	for k,v in ipairs(open_activity) do
		if v.ectype_type == ectype_type then
			scene_id = v.scene_id
		end
	end
	return scene_id
end

local function get_own_wood_barrel(roleid)
	for k,v in pairs(act_wood_barrel_rank) do
		if v.roleid == roleid then
			return v
		end
	end	
end

function activity_fast.req_wood_barrel_rank(ur)
	local roleid = ur.base.roleid
	local own_rank = get_own_wood_barrel(roleid)
	if not own_rank  then
		own_rank = wood_barrel_gen(0,ur.base.name,roleid,0)
	end
	local rank_list = {}
	for k,v in pairs(act_wood_barrel_rank) do
		if v.rank <= 10 then
			rank_list[#rank_list + 1] = v
		end
	end
	ur:send(IDUM_SYNCWOODBARRELRANK, {ranks = rank_list,own_rank = own_rank})
end

function activity_fast.deal_with_wood_barrel(ur,rank_data)
	local roleid = ur.base.roleid
	local own_rank = get_own_wood_barrel(roleid)
	if own_rank then
		own_activity.score = rank_data.score
	else
		own_rank = wood_barrel_gen(rank_data.score,ur.base.name,roleid,#act_wood_barrel_rank + 1)
		act_wood_barrel_rank[#act_wood_barrel_rank + 1] = own_rank
	end
	local old_rank = own_rank.rank
	sort_wood_barrel()
	own_rank = get_own_wood_barrel(roleid)
	local flag = false
	if old_rank <= 10 then
		flag = true
	else
		if own_rank.rank <= 10 then
			flag = true
		end
	end
	if flag then
		local rank_list = {}
		for k,v in pairs(act_wood_barrel_rank) do
			if v.rank <= 10 then
				rank_list[#rank_list + 1] = v
			end
		end
		ur:send(IDUM_SYNCWOODBARRELRANK, {ranks = rank_list,own_rank = own_rank})
	else
		ur:send(IDUM_SYNCWOODBARRELRANK, {ranks = {},own_rank = own_rank})
	end
	--tbl.print(act_wood_barrel_rank,"act_wood_barrel_rank ====== ")
end



return activity_fast
