local shaco = require "shaco"
local itemop = require "itemop"
local tpitem = require "__tpitem"
local tbl = require "tbl"
local task = require "task"
local club = require "club"
local card_container = require "card_container"
local mail = require "mail"
local ladder = require "ladder"
local ladder_fast = require "ladder_fast"
local tppayprice = require "__tppayprice"
local tpgamedata = require "__tpgamedata"
local recharge = require "recharge"
local spectype = require "spcial_ectype"
local endless_fast = require "endless_fast"
local activity_fast = require "activity_fast"
local sfmt = string.format
local REQ = {}

local function sync_card_info(ur)
	if not ur.cards.sync_partner_flag then
		spectype.sync_special_ectype(ur)
		card_container.refresh(ur)
		ur:send(IDUM_CARDPARTNERLIST,{partners = ur.cards.__partner,alternate = spectype.get_alternate_pos(ur)})
		ur.cards.sync_partner_attribute(ur)
		ur.cards.sync_partner_flag = true
	end
end

REQ[IDUM_REQFUNCTION] = function(ur, v)
	if (ur.bit_value >> REQ_BAG) & 1 == 0 then
		itemop.refresh(ur)
		ur.bit_value = ur.bit_value + 2^REQ_BAG
	end
	if v.func_type == REQ_BAG then  --请求主角界面
	elseif v.func_type == REQ_WEAPON then   --请求武器界面
		if (ur.bit_value >> REQ_WEAPON) & 1 == 0 then 
			ur.bit_value = ur.bit_value + 2^REQ_WEAPON
			itemop.refresh(ur)
			sync_card_info(ur)
		end
	elseif v.func_type == REQ_SKILL then   --请求技能界面
		local open_bit = ur.info.open_bit
		if (open_bit >> FUNC_SKILL) & 1 == 0 then
			return SERR_FUNCTION_NOT_OPEN
		end
		if (ur.bit_value >> REQ_SKILL) & 1 == 0 then
			ur.bit_value = ur.bit_value + 2^REQ_SKILL
			--itemop.refresh(ur)
		end
	elseif v.func_type == REQ_FORMATION then  --请求阵容
		local open_bit = ur.info.open_bit
		if (open_bit >> FUNC_CARD) & 1 == 0 then
			return SERR_FUNCTION_NOT_OPEN
		end
		if (ur.bit_value >> REQ_FORMATION) & 1 == 0 then
			ur.bit_value = ur.bit_value + 2^REQ_FORMATION
			sync_card_info(ur)
		end
	elseif v.func_type == REQ_CARD then   --请求卡牌界面
		local open_bit = ur.info.open_bit
		if (open_bit >> FUNC_CARD) & 1 == 0 then
			return SERR_FUNCTION_NOT_OPEN
		end
		if (ur.bit_value >> REQ_CARD) & 1 == 0 then
			ur.bit_value = ur.bit_value + 2^REQ_CARD
			--itemop.refresh(ur)
			sync_card_info(ur)
			
		end
	elseif v.func_type == REQ_TRAIN then   --请求训练界面
		if (ur.bit_value >> REQ_TRAIN) & 1 == 0 then
			ur.bit_value = ur.bit_value + 2^REQ_TRAIN
			sync_card_info(ur)
		end
	elseif v.func_type == REQ_MAIL then  -- 请求邮件界面
		if (ur.bit_value >> REQ_MAIL) & 1 == 0 then
			ur.bit_value = ur.bit_value + 2^REQ_MAIL
			ur:send(IDUM_MAILLIST,{data = ur.mail.data})
		end
	elseif v.func_type == REQ_ECTYPE then  --请求副本界面
        if (ur.bit_value >> REQ_ECTYPE) & 1 == 0 then
			ur.bit_value = ur.bit_value + 2^REQ_ECTYPE
			sync_card_info(ur)
		end
	elseif v.func_type == REQ_TASK then --請求任務界面
		if (ur.bit_value >> REQ_TASK) & 1 == 0 then
			ur.bit_value = ur.bit_value + 2^REQ_TASK
			ur:send(IDUM_TASKLIST, {info = ur.task.tasks})
		end
	elseif v.func_type == REQ_CLUB then  -- 請求俱樂部界面
		if (ur.bit_value >> REQ_CLUB) & 1 == 0 then
			ur.bit_value = ur.bit_value + 2^REQ_CLUB
			ur:send(IDUM_NOTICECLUBINFO, {info = ur.club})
			sync_card_info(ur)
		end
	elseif v.func_type == REQ_LADDER_SHOP then --请求荣誉商店
		if ((ur.bit_value >> REQ_LADDER_SHOP) & 1) == 0 then
			ladder.req_ladder_shop(ur)
			ur.bit_value = ur.bit_value + 2^REQ_LADDER_SHOP
		end
	elseif v.func_type == REQ_LADDER then  --请求天梯界面
		if ((ur.bit_value >> REQ_LADDER) & 1) == 0 then
			ladder_fast.enter_ladder(ur)
			ur.bit_value = ur.bit_value + 2^REQ_LADDER
			sync_card_info(ur)
		end
	elseif v.func_type == REQ_LADDER_RANK then  --请求排行榜
		if ((ur.bit_value >> REQ_LADDER_RANK) & 1) == 0 then
			ladder_fast.req_ladder_rank(ur,1)
			ur.bit_value = ur.bit_value + 2^REQ_LADDER_RANK
		end
	elseif v.func_type == REQ_SPECIAL_ECTYPE then   --请求试练之地
		if ((ur.bit_value >> REQ_SPECIAL_ECTYPE) & 1) == 0 then
			sync_card_info(ur)
			--spectype.sync_special_ectype(ur)
			endless_fast.req_endless_rank(ur,4)  ---无尽回廊排行榜
			ur.bit_value = ur.bit_value + 2^REQ_SPECIAL_ECTYPE
		end
	elseif v.func_type == REQ_ENDLESS_RANK then   ---请求无尽回廊排行榜
		if ((ur.bit_value >> REQ_ENDLESS_RANK) & 1) == 0 then
			endless_fast.req_endless_rank(ur,1)
			ur.bit_value = ur.bit_value + 2^REQ_ENDLESS_RANK
		end
	elseif v.func_type == REQ_ACTIVITY_MAIN then   ---请求活动界面
		if ((ur.bit_value >> REQ_ACTIVITY_MAIN) & 1) == 0 then
			activity_fast.req_open_activity_list(ur)
			sync_card_info(ur)
			ur.bit_value = ur.bit_value + 2^REQ_ACTIVITY_MAIN
		end
	elseif v.func_type == REQ_ACTIVITY_MONEY_RANK then --极限挑战排行
		if ((ur.bit_value >> REQ_ACTIVITY_MONEY_RANK) & 1) == 0 then
			if not activity_fast.req_activity_money_rank(ur) then
                ur.bit_value = ur.bit_value + 2^REQ_ACTIVITY_MONEY_RANK
            end
		end
	elseif v.func_type == REQ_ACTIVITY_EXP_RANK then --极速时刻排行
		if ((ur.bit_value >> REQ_ACTIVITY_EXP_RANK) & 1) == 0 then
			if not activity_fast.req_activity_exp_rank(ur) then
                ur.bit_value = ur.bit_value + 2^REQ_ACTIVITY_EXP_RANK
            end
		end
	elseif v.func_type == REQ_ACTIVITY_WOOD_BARREL then --木桶阵排行
		if ((ur.bit_value >> REQ_ACTIVITY_WOOD_BARREL) & 1) == 0 then
			if not activity_fast.req_wood_barrel_rank(ur) then
                ur.bit_value = ur.bit_value + 2^REQ_ACTIVITY_WOOD_BARREL
            end
		end
	elseif v.func_type == REQ_SHOP then --商店界面
		if ((ur.bit_value >> REQ_SHOP) & 1) == 0 then
			ur.bit_value = ur.bit_value + 2^REQ_SHOP
			sync_card_info(ur)
		end
	end
	ur:send(IDUM_ACKFUNCTION,{func_type = v.func_type})
end

REQ[IDUM_REQBUYPHYSICAL] = function(ur ,v)
	local buy_physical_cnt = ur.info.buy_physical_cnt + 1
	local max_cnt = ur:get_vip_value(VIP_BUY_POWER_T)
	local money_type = 0
	local take = 0
	if max_cnt < buy_physical_cnt then
		return SERR_BUY_PHYSICAL_MAX
	end
	if ur.info.physical >= tpgamedata.PhysicalMax then
		return SERR_PHYSICAL_MAX
	end
	for k,v in pairs(tppayprice) do
		if v.type == 5 and v.start <= buy_physical_cnt and v.stop >= buy_physical_cnt then
			money_type = v.money_tpye
			take = v.number
			break
		end
	end
	if money_type == 0 then
		if take == 0 then
			return SERR_BUY_PHYSICAL_MAX
		end
		if ur:gold_take(take) == false then
			return SERR_GOLD_NOT_ENOUGH
		end
	end
	ur.info.physical = ur.info.physical + tpgamedata.PhysicalMax
	ur.info.buy_physical_cnt = buy_physical_cnt
	ur:sync_role_data()
	ur:db_tagdirty(ur.DB_ROLE)
	ur:send(IDUM_ACKBUYPHYSICAL,{buy_count = buy_physical_cnt})
	task.set_task_progress(ur,45,1,0)
	task.refresh_toclient(ur, 45)
end

REQ[IDUM_SYNCGUIDANCE] = function(ur, v)
	ur.info.guidance = v.guidance_step
	ur:db_tagdirty(ur.DB_ROLE)
end

REQ[IDUM_NOTICEORDERID] = function(ur, v)
	--recharge.add_recharge_order(ur,v.str_order)	
	--ur:send(IDUM_AFFIRMORDERID,{str_order = v.str_order})
end

return REQ
