--local shaco = require "shaco"
local shaco = require "shaco"
local pb = require "protobuf"
local tbl = require "tbl"
local sfmt = string.format
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local tpmail = require "__tpmail"
local mail_fast = require "mail_fast"
local tpfestival_bingtest_moneytower = require "__tpfestival_bingtest_moneytower"
local tpfestival_bingtest_exptower = require "__tpfestival_bingtest_exptower"
local tpitem = require "__tpitem"
local floor = math.floor
local mail = {}
local other_mail_id = 100000

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
		mail_content2 = "",
		mail_content3 = "",
	}
end

local function old_mail_gen()
	return {
		mail_id = 0,
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


function mail.check_old_mail(old_info,mailid)
	for i = 1,#old_info do
		if old_info[i].mail_id == mailid then
			return true
		end
	end
	return false
end

function mail.new(mailv)
	local mails = mailv
	local now = shaco.now()//1000
	local mail_list = {}
	if not mails.data or #mails.data == 0 then
		mails.data = {}
	end
	if not mails.old_info or #mails.old_info == 0 then
		mails.old_info = {}
	end
--	tbl.print(mailv)
	
		--local tp = tpmail[mails.data[i].mail_id]
		--if tp then
			--[[if tp.type == ITEM_MAIL then
				if tp.send_time + tp.unread/1000 < now then
					if mail.check_old_mail(mails.old_info,mails.data[i].mail_id) then
						local old_mail = old_mail_gen()
						old_mail.mail_id = mails.data[i].mail_id
						mails.old_info[#mails.old_info + 1] = old_mail
					end
				else
					mail_list[#mail_list + 1] = mails.data[i]
				end
			else]]
	for i=1,#mails.data do	
		local data = mails.data[i]
		if data.mail_read_time > data.send_time then
			if data.mail_read_time + data.read_save//1000 <= now then
				if mail.check_old_mail(mails.old_info,data.mail_id) then
					local old_mail = old_mail_gen()
					old_mail.mail_id = data.mail_id
					mails.old_info[#mails.old_info + 1] = old_mail
				end
			else
				mail_list[#mail_list + 1] = data
			end
		elseif data.mail_read_time == 0 then
			if data.send_time + data.unread//1000 <= now then
				if mail.check_old_mail(mails.old_info,data.mail_id) then
					local old_mail = old_mail_gen()
					old_mail.mail_id = data.mail_id
					mails.old_info[#mails.old_info + 1] = old_mail
				end
			else
				mail_list[#mail_list + 1] = data
			end
		end
	end
	mails.data = mail_list
    return mails
end

local function mail_init(ur,mail_list)
	local cur_time = shaco.now()//1000
	local own_list = ur.mail.data
	local old_mails = ur.mail.old_info
	old_mails = old_mails or {}
	local new_list = {}
	for i=1,#mail_list do
		local flag = false
		if mail_list[i].send_time + mail_list[i].unread/1000 > cur_time then
			for j=1,#old_mails do
				if old_mails[j].mail_id and old_mails[j].mail_id == mail_list[i].id then
					flag = true
					break
				end
			end
		else
			flag = true
		end
		if flag == false then
			local __flag = true
			for j =1,#own_list do
				if own_list[j].mail_id == mail_list[i].id then
					__flag = false
					break
				end
			end
			if __flag == true then
				new_list[#new_list + 1] = mail_list[i]
			end
		end
	end
	return new_list
end

local function get_mail_item(tpmail_info)
	local items = {}
	for i = 1,5 do
		local item_info = mail_item_gen()
		item_info.item_type = tpmail_info["Item"..i.."_type"]
		item_info.item_id = tpmail_info["Item"..i.."_id"]
		item_info.item_cnt = tpmail_info["Item"..i.."_count"]
		items[#items + 1] = item_info
	end
	return items
end

function mail.init(ur)
	local mail_list = ur.mail.data
	local temp_list = {}
	temp_list = mail_init(ur,mail_fast.get_mail_list())
	for i =1,#temp_list do
		local tp = temp_list[i]
		local mail_info = mail_gen()
		mail_info.mail_id = tp.id
		mail_info.mail_type = tp.type
		mail_info.mail_theme = tp.theme
		mail_info.mail_content = tp.content
		mail_info.mail_gold = tp.diamond
		mail_info.mail_cion = tp.glod
		mail_info.item_info = get_mail_item(tp)
		mail_info.read_save = tp.read
		mail_info.unread = tp.unread
		mail_info.send_time = tp.send_time
		mail_info.mail_content2 = tp.content2
		mail_info.mail_content3 = tp.content3
		mail_list[#mail_list + 1] = mail_info
	end
	--tbl.print(mail_list, "=============init mail_list", shaco.trace)
	if #temp_list > 0 then
		return true
	end
	return false
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

local function add_mail(ur,mail_info)
	local mail_list = ur.mail.data
	mail_info.mail_id = create_mail_id(ur.mail)
	mail_info.send_time = shaco.now()//1000
	mail_list[#mail_list + 1] = mail_info
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

function mail.add_new_mail(ur,id,num,hole_cnt,wash_cnt,item_type)
	local mail_info = mail_gen()
	mail_info.mail_type = 1
	mail_info.item_info = get_mail_item(id,num,hole_cnt,wash_cnt,item_type)
	mail_info.unread = 86400000
	mail_info.read_save = 0
	mail_info.mail_theme = "奖励"
	mail_info.mail_content = "测试奖励"
	mail_info.mail_content2 = ""
	mail_info.mail_content3 = ""
	add_mail(ur,mail_info)
	--tbl.print(mail_info)
	ur:db_tagdirty(ur.DB_MAIL)
	ur:send(IDUM_MAILLIST,{data = ur.mail.data})
end

local function get_activity_reward_tp(tp,stage,rank)
	local _tp
	local greater_than = 0
	local greater_indx = 0
	local less_than = 0
	local less_indx = 0
	local max_than = 0
	local max_indx = 0
	local equal = 0
	for k,v in ipairs(tp) do
		if v.Rank[1] <= rank and v.Rank[2] >= rank then
			if stage == v.Stage then
				equal = v.ID
			end
			if stage > v.Stage then
				if greater_than < v.Stage then
					greater_than = v.Stage
					greater_indx = v.ID
				end
			end
			if stage < v.Stage then
				if less_than == 0 then
					less_than = v.Stage
					less_indx = v.ID
				end
				if less_than > v.Stage then
					less_than = v.Stage
					less_indx = v.ID
				end
			end
			if max_than < v.Stage then
				max_than = v.Stage
				max_indx = v.ID
			end
		end
	end
	if equal >0 then
		_tp = tp[equal]
	else
		if greater_than > 0 and less_than > 0 then
			_tp = tp[greater_indx]
		else
			_tp = tp[max_indx]
		end
	end
	return _tp
end

function mail.get_activity_reward(tp,rank,stage)
	local itemid = 0
	local money_type = 0
	local cnt = 0
	local items = {}
	local mail_cion = 0
	local mail_gold = 0
	local _tp = get_activity_reward_tp(tp,stage,rank)
	for i = 1,#_tp.BOUNS do
		local item_type = 0
		local bouns = _tp.BOUNS[i]
		if bouns[1] == 0 then --道具
			item_type = ITEM_TYPE
		else --道具
			item_type = CARD_TYPE
		end
		local item_info = mail_item_gen()
		item_info.item_type = item_type
		item_info.item_id = bouns[2]
		item_info.item_cnt = bouns[3]
		items[#items + 1] = item_info
	end
	return items
end

function mail.add_activity_mail(ur,_type,rank,stage)
	local itemid = 0
	local money_type = 0
	local cnt = 0
	local mail_info = mail_gen()
	mail_info.mail_type = 1
	local tp
	local id = 0
	local string_name = ""
	if _type == 1 then --money 
		tp = tpfestival_bingtest_moneytower
		id = 9001
		--string_name = "大试练极限挑战"
	else  --exp
		tp = tpfestival_bingtest_exptower
		id = 9002
		--string_name = "大试练极速时刻"
	end
	local tp_mail = tpmail[id]
	local items = mail.get_activity_reward(tp,rank,stage)
	--tbl.print(items," items ======  ur")
	mail_info.item_info = items
	mail_info.unread = 86400000
	mail_info.read_save = 0
	mail_info.mail_theme = tp_mail.theme
	mail_info.mail_content = tp_mail.content
	mail_info.mail_content2 = tp_mail.content2
	mail_info.mail_content3 = tp_mail.content3
	if ur then
		add_mail(ur,mail_info)
		--tbl.print(mail_info,"   mail_info  ===== ")
		--tbl.print(ur.mail.data,"   ur.mail.data  ===== ")
		ur:db_tagdirty(ur.DB_MAIL)
		ur:send(IDUM_MAILLIST,{data = ur.mail.data})
	end
end

function mail.get_club_reward(left_card)
	local items = {}
	for i = 1,#left_card do
		local card = left_card[i]
		local item_info = mail_item_gen()
		item_info.item_type = CARD_TYPE
		item_info.item_id = card.itemid
		item_info.item_cnt = card.itemcnt
		items[#items + 1] = item_info
	end
	return items
end

function mail.send_club_card_mail(ur,left_card)
	local mail_info = mail_gen()
	mail_info.mail_type = 1
	local items = mail.get_club_reward(left_card)
	--tbl.print(items," items ======  ur")
	mail_info.item_info = items
	mail_info.unread = 86400000
	mail_info.read_save = 0
	mail_info.mail_theme = "俱乐部奖励"
	mail_info.mail_content = "俱乐部奖励"
	mail_info.mail_content2 = ""
	mail_info.mail_content3 = ""
	add_mail(ur,mail_info)
	ur:db_tagdirty(ur.DB_MAIL)
	--tbl.print(mail_info,"   mail_info  11111===== ")
	ur:send(IDUM_MAILLIST,{data = ur.mail.data})
end

function mail.get_strongest_fight_reward(race,items)
	local item_list = {}
	for i = 1,#items do
		local item = items[i]
		if item[1] == 0 or race == item[1] then
			local item_info = mail_item_gen()
			if item[2] == 0 then
				item_info.item_type = ITEM_TYPE
			elseif item[2] == 1 then
				item_info.item_type = CARD_TYPE
			end
			item_info.item_id = item[3]
			item_info.item_cnt = item[4]
			item_list[#item_list + 1] = item_info
		end
	end
	return item_list
end

function mail.send_strongest_fight_mail(ur,items)
	local mail_info = mail_gen()
	mail_info.mail_type = 1
	local items = mail.get_strongest_fight_reward(ur.base.race,items)
	--tbl.print(items," items ======  ur")
	mail_info.item_info = items
	mail_info.unread = 86400000
	mail_info.read_save = 0
	mail_info.mail_theme = "强力高手排名奖励"
	mail_info.mail_content = "鉴于你在强力高手排行榜的表现，特发放以下奖励。"
	mail_info.mail_content2 = ""
	mail_info.mail_content3 = ""
	add_mail(ur,mail_info)
	ur:db_tagdirty(ur.DB_MAIL)
	--tbl.print(mail_info,"   mail_info  11111===== ")
	ur:send(IDUM_MAILLIST,{data = ur.mail.data})
end

function mail.send_gm_mail(ur,mails)
	local mail_list = ur.mail.data
	for i = 1,#mails do
		local _mail = mails[i]
		local mail_info = mail_gen()
		mail_info.mail_id = tonumber(_mail.mail_id)
		mail_info.mail_type = tonumber(_mail.mail_type)
		mail_info.item_info = _mail.mail_tems
		mail_info.unread = 86400000
		mail_info.read_save = 0
		mail_info.mail_theme = _mail.mail_theme
		mail_info.mail_content = _mail.mail_content
		mail_info.mail_content2 = _mail.mail_content2
		mail_info.mail_content3 = _mail.mail_content3
		mail_info.mail_gold = tonumber(_mail.mail_gold)
		mail_info.mail_cion = tonumber(_mail.mail_cion)
		mail_info.send_time = shaco.now()//1000
		mail_list[#mail_list + 1] = mail_info
	end
	ur:db_tagdirty(ur.DB_MAIL)
	ur:send(IDUM_MAILLIST,{data = ur.mail.data})
end

return mail
