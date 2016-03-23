local shaco = require "shaco"
local tpmail = require "__tpmail"
local tostring = tostring
local sfmt = string.format
local mail = require "mail"
local tbl = require "tbl"
local itemop = require "itemop"
local club = require "club"
local card_container = require "card_container"
local ladder = require "ladder"
local tpitem = require "__tpitem"

local REQ = {}

local function old_info_gen()
	return {
		mail_id = 0,
	}
end

local function get_mail_item(ur,tp)
	local item_flag = false
	local fragment_flag = false
	local card_flag = false
	local honor_flag = false
	local money_flag = false
	local card_list = {}
	local total_card_cnt = 0
	for i = 1,#tp.item_info do
		local info = tp.item_info[i]
		if info.item_type == ITEM_TYPE then
			local tp_item = tpitem[info.item_id]
			if tp_item.itemType == ITEM_RESOURCE then
				if info.item_id == 1 then
					ur:coin_got(info.item_cnt)
				elseif info.item_id == 2 then
					ur:gold_take(info.item_cnt)
				end
				money_flag = true
			else
				item_flag = true
				itemop.gain(ur,info.item_id,info.item_cnt)
			end
		elseif info.item_type == CARD_TYPE then
			card_list[#card_list + 1] = info
			total_card_cnt = total_card_cnt + info.item_cnt
		end
	end
	if total_card_cnt > 0 then
		local left_pos_cnt = card_container.get_residual_position(ur)
		if total_card_cnt > left_pos_cnt then
			return SERR_CARD_GRID_NOT_ENOUGH
		end
		local cards = ur.cards
		for i = 1,#card_list do
			local card = card_list[i]
			cards:put(ur,card.item_id,card.item_cnt)
		end
		card_container.refresh(ur)
		ur:db_tagdirty(ur.DB_CARD)
	end
	--[[for i=1,5 do
		if tp["Item"..i.."_type"] == ITEM_TYPE or tp["Item"..i.."_type"] == CARD_FRAGMENT then
			item_flag = true
			itemop.gain(ur,tp["Item"..i.."_id"],tp["Item"..i.."_count"])
		elseif tp["Item"..i.."_type"] == CARD_TYPE then
			local cards = ur.cards
			if cards:put(ur,tp["Item"..i.."_id"],tp["Item"..i.."_count"]) > 0 then
				card_flag = true
			end
		elseif tp["Item"..i.."_type"] == HONOR_TYPE then
			honor_flag = true
			ladder.add_honor(ur,tp["Item"..i.."_id"],tp["Item"..i.."_count"])
		end
			
	end]]
	if money_flag then
		ur:db_tagdirty(ur.DB_ROLE)
		ur:sync_role_data()
	end
	if item_flag == true then
		itemop.refresh(ur)
		ur:db_tagdirty(ur.DB_ITEM)
	end
end

REQ[IDUM_REQMAILREWARD] = function(ur, v)
	local mail_list = ur.mail.data
	local target_mail = nil
	local temp_mails = {}
	for i=1,#mail_list do
		if mail_list[i].mail_id == v.mail_id then
			target_mail = mail_list[i]
		else
			temp_mails[#temp_mails + 1] = mail_list[i]
		end
	end
	if not target_mail then
		return
	end
	--tbl.print(target_mail,"--- target_mail ==== ")
	--local tp = tpmail[v.mail_id]
	--if not tp then
	----	return
	--end
	ur.mail.old_info = ur.mail.old_info or {}
	if target_mail.mail_type == ITEM_MAIL then
		if mail.check_old_mail(ur.mail.old_info,v.mail_id) then
			return SERR_ALREADY_TAKE_MAIL_REWARD
		end
	end
	local now = shaco.now()//1000
	if target_mail.send_time + target_mail.unread/1000 < now then
		return
	end
	if target_mail.mail_type == ITEM_MAIL then --item_mail
		local money_flag = false
		if target_mail.mail_gold > 0 then
			ur:gold_take(target_mail.mail_gold)
			money_flag = true
		end
		if target_mail.mail_cion > 0 then
			ur:coin_got(target_mail.mail_cion)
			money_flag = true
		end
		local result = get_mail_item(ur,target_mail)
		if result then
			return result
		end
		local temp_list = {}
		for i=1,#mail_list do
			if mail_list[i].mail_id ~= v.mail_id then
				temp_list[#temp_list + 1] = mail_list[i]
			end
		end
		mail_list  = {}
		mail_list = temp_list
		if money_flag then
			ur:db_tagdirty(ur.DB_ROLE)
			ur:sync_role_data()
		end
	elseif target_mail.type == WORD_MAIL then --word_mail
		target_mail.mail_read_time = now
	end
	
	
	local old_mail_info = old_info_gen()
	old_mail_info.mail_id = v.mail_id
	if target_mail.mail_type == WORD_MAIL then
		if not mail.check_old_mail(ur.mail.old_info,v.mail_id) then
			ur.mail.old_info[#ur.mail.old_info + 1] = old_mail_info
		end
	else
		ur.mail.data = temp_mails
		ur.mail.old_info[#ur.mail.old_info + 1] = old_mail_info
	end
	ur:db_tagdirty(ur.DB_MAIL)
	ur:send(IDUM_ACKMAILREWARD,{mail_id = v.mail_id,mail_read_time = now})
end

REQ[IDUM_ONEKEYGETMAILREWARD] = function(ur, v)
	local mail_list = ur.mail.data
	local mail_word_list = {}
	for i=1,#mail_list do
		local target_mail =  mail_list[i]
		local mail_id = target_mail.mail_id
		--local tp = tpmail[mail_list[i].mail_id]
		if target_mail then
			if target_mail.mail_type == ITEM_MAIL then
				if not mail.check_old_mail(ur.mail.old_info,mail_id) then
					local result = get_mail_item(ur,target_mail)
					if result then
						return result
					end
					local old_mail_info = old_info_gen()
					old_mail_info.mail_id = mail_id
					ur.mail.old_info[#ur.mail.old_info + 1] = old_mail_info
				end
			else
				--
				target_mail.mail_read_time = now
				mail_word_list[#mail_word_list + 1] = target_mail
			end
		end
	end
	ur.mail.data = mail_word_list
	ur:db_tagdirty(ur.DB_MAIL)
	ur:send(IDUM_ONEKEYSUCCESS,{result = 1})
end

return REQ
