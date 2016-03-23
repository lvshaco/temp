local shaco = require "shaco"
local util = require "util"
local pb = require "protobuf"
local tbl = require "tbl"
local bor  = bit32.bor
local band = bit32.band
local bnot = bit32.bnot
local lshift = bit32.lshift
local tinsert = table.insert
local sfmt = string.format
local floor = math.floor
local CTX = require "ctx"
local MSG_RESNAME = require "msg_resname"
local bag = require "bag"
local scene = require "scene"
local task = require "task"
local ectype = require "ectype"
local tpcreaterole = require "__tpcreaterole"
local skills = require "skill"
local attributes = require "attribute"
local itemop = require "itemop"
local card_container = require "card_container"
local partner = require "partner"
local tpgamedata = require "__tpgamedata"
local dazzles = require "dazzle"
local mystery = require "mystery"
local tprole = require "__tprole"
local club = require "club"
local ladder = require "ladder"
local config = require "config"
local mail = require "mail"
local tpopen = require "__tpopen"
local recharge = require "recharge"
local tprecharge = require "__tprecharge"
local spectype = require "spcial_ectype"
local tpvip = require "__tpvip"
local activity = require "activity"
local rank_fight = require "rank_fight"
local equip_attributes = require "equip_attribute"
local ipairs = ipairs

local user = {
    DB_ROLE=1,
    DB_ITEM=2,
    DB_TASK=4,
    DB_ROLE_DELAY=8,
    DB_CARD=16,
	DB_CLUB = 32,
	DB_LADDER = 64,
	DB_MAIL = 128,
	DB_RECHARGE = 256,
	DB_SPECTYPE = 512,
	DB_ACTIVITY_MONEY = 1024,
	DB_ACTIVITY_EXP = 2048,
	DB_ACTIVITY = 4096,
	

    -- status
    US_LOGIN = 1,
    US_WAIT_CREATE = 2,
    US_WAIT_SELECT = 3,
    US_GAME = 4,
    US_LOGOUT = 5,
}

local function sync_role_gen()
	return {
	    coin=0,
    	gold=0,
    	exp=0,
   	    level=0,
		physical=0,
		battle = 0,
		physical_time = 0,
		server_time = 0,
	}
end

local function item_drop_gen()
	return {
		itemid = 0,
		cnt = 0,
	}
end

local function turn_card_reward_gen()
	return {
		itemid = 0,
		cnt = 0,
		__type = 0,
	}
end

local function vip_gen()
	return {
		vip_level = 0,
		vip_exp = 0,
		buy_flag = 0,
	}
end

local function role_info_gen()
	return {
		mapid = 0,
		posx = 0,
		posy = 0,
		coin = 0,
		gold = 0,
		package_size = 0,
        exp = 0,
        refresh_time = 0,
        oid = 0,
		ectype = {},
		skills = {},
		attribute = nil,
        map_entertime=0,
        last_city=0,
        cards_size=0,
		dazzles = {},
		mystery = nil,
		normal = nil,
		physical = tpgamedata.Physical,
		physical_time = 0,
		battle_value = 0,
		buy_physical_cnt = 0,
		guidance = 0,
		open_bit = 0,
        lastx = 0,
        lasty=0,
		server_time = 0,
		global_code = "",
		free_card_cnt = 0,
		free_card_time = 0,
		drops = {},
		turn_card = {},
		vip = {},
		special_event = 0,
		check_flag = 0,
        rmb = 0,
        rmb_last_time=0,
        login_time=0,
        logout_time=0,
		exchange_coin_cnt = 0,
	}
end

local function container_gen()
	return {
    	list={},
    	partners={},
    	}
end

function user.new(connid, status, acc)
    local self = {
        connid = connid,
        status = status,
        acc = acc,
        roles = nil,
		gms = nil,
        base = nil,
        info = nil,
        -- scene
        scene = nil,
        lineid = nil,
        scene_visibles = {},
        scene_version = 0,
        moving = false,
        scene_last_update = 0,
        --
        package = nil,
        equip=nil,
        mat=nil,
        task = {},
        cards = nil,
        db_dirty_flag = 0,
		battle_value = 0,
		club = nil,
		refesh_ladder = 0,
		rank_update = 0,
		mail = nil,
		across_day = 0,
		battle_verify = false,
		bit_value = 0,
		five_rank_update = 0,
		gm_level = 0,
		ladder = nil,
		recharge = nil,
		add_exp = 0,
		enter_game = false,
		spectype = nil,
		addition = {},
        lineid = 0,
		red_point = 38,--二进制存储 enum:RED_POINT_T
		activity = nil,
		attribute = nil,
		special_activity = {},
    }
    setmetatable(self, user)
    user.__index = user
    return self
end

local OBJID_ALLOC = ROLE_STARTOID
local function objid_gen()
    if OBJID_ALLOC < ROLE_STARTOID then
        OBJID_ALLOC = ROLE_STARTOID
    end
    OBJID_ALLOC = OBJID_ALLOC+1
    return OBJID_ALLOC
end

local function checkchange_battle_value(self)
	if self.battle_value ~= self.info.battle_value then
		self.info.battle_value = self.battle_value
		self:db_tagdirty(self.DB_ROLE)
        rank_fight.change_fight(self)
	end
end

function user:init(...)
    local tt = {...}
    local info, item, taskv, cardv,clubv, mailv, ladderv,rechargev,spectypev,activityv = ... 
    local new_role = false
    if not info then
        info = role_info_gen()
		info.check_flag = 1
		info.vip = vip_gen()
		info.vip.vip_level = 0
        new_role = true
	end
    -- login_time
    info.login_time = shaco.now()//1000
    self:db_tagdirty(self.DB_ROLE_DELAY) 
	info.ectype = ectype.new(info.ectype)
    local item = item or {}
    local item_pkg = item.package or {}
    local item_equip = item.equip or {}
    local item_mat = item.mat or {}
    if info.package_size < tpgamedata.PlayerBackpack then
        info.package_size = tpgamedata.PlayerBackpack
    end
    if info.cards_size < tpgamedata.CardBackpack then
        info.cards_size = tpgamedata.CardBackpack
    end
   
    if info.last_city == 0 then
        info.last_city = 1
    end
    info.mapid = info.last_city
    info.oid = objid_gen()
	if not info.mystery then
		--if info.mystery.strat_time - os.time() > 500 then
			--info.mystery = nil
		--end
	end
    self.info = info
    self.package = bag.new(BAG_PACKAGE, info.package_size, item_pkg)
	
    self.equip = bag.new(BAG_EQUIP, EQUIP_MAX, item_equip)
    self.mat = bag.new(BAG_MAT, tpgamedata.WarehouseMax, item_mat)
    --tbl.print(self.equip,"--------------- self.equip ===== ")
	rechargev = rechargev or {}
	self.recharge = recharge.new(rechargev)
	
   -- taskv = taskv or {}
    self.task = task.new(TASK_SYSTEM, taskv)
    if self.task then
	--	print("name ======= "..self.base.name)
      --  tbl.print(self.task)
    end

    --info.partners = partner.new(info.partner_size,info.partners)
	info.dazzles = dazzles.new(info.dazzles) 
	local flag = 1
	info.skills,flag = skills.new(self.base.tpltid,info.skills)
	if flag == 1 then
		self:db_tagdirty(self.DB_ROLE)
	end
	 if not cardv then
    	cardv = container_gen()
    end
	self.cards = card_container.new(info.cards_size,cardv,self)
    if new_role then
        local tp = tpcreaterole[self.base.tpltid]
        if tp then
            for _, v in ipairs(tp.Item) do
                itemop.gain(self, v[1], v[2])
            end
            if tp.Weapon > 0 then
                itemop.gain_weapon(self.equip, tp.Weapon)
            end
            self:db_tagdirty(self.DB_ITEM)
            info.coin = tp.Money
            info.gold = tp.Emoney
			info.free_card_cnt = 1
        end
		mystery.normal_shop_init(self)
        -- just test
       -- task.first_accept(self)
	    --task.init_old_task(self)
        self.cards:put(self,100,1)
        self:db_tagdirty(self.DB_ROLE)
        
        self:db_tagdirty(self.DB_TASK)
        self:db_tagdirty(self.DB_CARD)
    end	
	local club_flg = false
	clubv = clubv or {}
	club_flg,self.club = club.new(self,clubv,info.open_bit)
	if club_flg == true then
		self:db_tagdirty(self.DB_CLUB)
	end
	mailv = mailv or {}
	local mail_flag = false
	self.mail = mail.new(mailv)
	mail_flag = mail.init(self)
	--tbl.print(self.mail,"   self.mail ===== ")
	if mail_flag == true then
		self:db_tagdirty(self.DB_MAIL)
	end
	
	self.attribute = attributes.new(self)
    self.attribute:add_attribute(self)
	--tbl.print(self.info.attribute,"-----------111111111111111111111111111---  self.info.attribute  ====  ")
	self:sync_self_attribute()
	self.battle_value = self.attribute:get_battle_value(self.base.tpltid) + card_container.get_partner_battle(self)
	--tbl.print(self.info.attribute,"--------------  self.info.attribute  ====  ")
	--print("self.battle_value ===== "..self.battle_value.."self.attribute:get_battle_value(self.base.tpltid) === "..self.attribute:get_battle_value(self.base.tpltid).."  card_container.get_partner_battle(self) == "..card_container.get_partner_battle(self))
	self.ladder = ladder.new(ladderv,self.base)
	self.spectype = spectype.new(spectypev)
	--	local vip = vip_gen()
	--	vip.vip_level = info.vip.vip_level or 0
	--	vip.vip_exp = info.vip.vip_exp or 0
	--	vip.buy_flag = info.vip.buy_flag or 0
	--end
	shaco.trace(sfmt("user name == %s create role ...",self.base.name))
  
	if info.check_flag ~= 1 then
		info.vip = {}
		info.vip = vip_gen()
		info.check_flag = 1
		info.vip.vip_level = 15
		self:db_tagdirty(self.DB_ROLE)
	end
    --tbl.print(self.info.vip, "=====----self.info.vip==== "..self.base.name)
	--if info.vip then
	self.activity = activity.new(self, activityv)
    --tbl.print(self.activity, "self.activity", shaco.trace)
	local now = shaco.now()//1000
    local now_day = util.second2day(now)
    local last_day = util.second2day(self.info.refresh_time)
        --print ("++++++++++++ on login check changeday:", now_day, last_day,
        --now, self.info.refresh_time)
    if now_day ~= last_day then
        self:onchangeday(1)
    end
	self:check_red_point()
end

function user:entergame()
    local now_ms = shaco.now()
	self.info.server_time = now_ms//1000
	self:send(IDUM_ENTERGAME, {info=self.info,open_time = config.open_server_time,battle_value = self.battle_value,red_point = self.red_point})
    checkchange_battle_value(self)

	scene.enter(self, self.info.last_city)
    self.scene_last_update = now_ms
	if task.daily_update(self) == true then
    	self:db_tagdirty(self.DB_TASK)
    end
	self.enter_game = true
 --[[ local info = self.info
    self:send(IDUM_ENTERGAME, {info=self.info,open_time = config.open_server_time,battle_value = self.battle_value})
	self:send(IDUM_SYNCBATTLEVALUE, {battle_value=self.battle_value})
    itemop.refresh(self)
   if task.daily_update(self) == true then
		self:db_tagdirty(self.DB_ROLE)
    	self:db_tagdirty(self.DB_TASK)
    end
	self:send(IDUM_NOTICECLUBINFO, {info = self.club})
    self:send(IDUM_TASKLIST, {info = self.task.tasks})
    self.cards.refresh(self)
	self:send(IDUM_CARDPARTNERLIST,{partners = self.cards.__partner})
	self.cards.sync_partner_attribute(self)
    scene.enter(self, self.info.last_city)]]
end

function user:compute_attribute()
	
end

function user:exitgame()
    scene.exit(self)
    -- logout_time
    self.info.logout_time = shaco.now()//1000
    self:db_tagdirty(self.DB_ROLE_DELAY)

    self:db_flush(true)
end

function user:ontime(now_ms)
	if not self.enter_game then
        return
	end
    local sync_role = false
    local now =now_ms//1000
    local info = self.info
    if info.physical < tpgamedata.PhysicalMax then
        
        if info.physical_time == 0 then
            info.physical_time = now
            self:db_tagdirty(self.DB_ROLE)
        end
        local elapsed = now - info.physical_time
        local point = elapsed//tpgamedata.PhysicalTime
        if point > 0 then
            info.physical = info.physical + point
            if info.physical > tpgamedata.PhysicalMax then
                info.physical = tpgamedata.PhysicalMax
            end
            if info.physical >= tpgamedata.PhysicalMax then
                info.physical_time = 0
            else
                info.physical_time = info.physical_time + point*tpgamedata.PhysicalTime
            end
            self:db_tagdirty(self.DB_ROLE)
            sync_role = true
        end
    end
    -- role data change , here sync once
    if sync_role then
        self:sync_role_data()
    end

    -- 
	if self.info.free_card_cnt == 0 then
		local difference_time = now - self.info.free_card_time
		local free_cnt,temp = math.modf(difference_time/(tpgamedata.FreeCard * 3600))
		if free_cnt >= 1 then
			self.info.free_card_cnt = 1
			self.info.free_card_time = now
			self:db_tagdirty(self.DB_ROLE)
			self:db_flush(true)
		end
	end
	
	ladder.update(self,now_ms)

    if now_ms - self.scene_last_update >= 200 then
        scene.update(self)
        self.scene_last_update = now_ms
    end
end

function user:onchangeday(login_state)
	self.info.refresh_time = shaco.now()//1000
	mystery.normal_shop_init(self)
	ladder.onchangeday(self)
	club.update(self,true)
	self.info.buy_physical_cnt = 0
	self.info.exchange_coin_cnt = 0
	task.update_daily_task(self)
	self:db_tagdirty(self.DB_ROLE)
	spectype.onchangeday(self,login_state)
        --print ("changeday--------------")
	activity.onchangeday(self,login_state)
	self:db_tagdirty(self.DB_ROLE)
end

-- bag
function user:getbag(t)
    if t == BAG_EQUIP then
        return self.equip
    elseif t == BAG_MAT then
        return self.mat 
    else
        return self.package
    end
end

-- db
function user:db_tagdirty(t)
    self.db_dirty_flag = (self.db_dirty_flag | t)
end

function user:db_flush(force)
    local roleid = self.base.roleid
    local flag = self.db_dirty_flag
    local up_role = false
    if (flag & self.DB_ROLE) ~= 0 then
        flag = (flag & (~(self.DB_ROLE)))
        up_role = true
    elseif (force and ((flag & self.DB_ROLE_DELAY) ~= 0)) then
        flag = (flag & (~(self.DB_ROLE_DELAY)))
        up_role = true
    end
    if up_role then
        shaco.sendum(CTX.db, "S.role", {
            roleid=roleid,
            base=pb.encode("role_base", self.base),
            info=pb.encode("role_info", self.info),
       })
    end 
    if (flag & self.DB_ITEM) ~= 0 then
            shaco.sendum(CTX.db, "S.ex", {
            name="item",
            roleid=roleid,
            data=pb.encode("item_list", {package=itemop.getall(self.package), 
                                         equip=itemop.getall(self.equip),
                                         mat=itemop.getall(self.mat)}),
        })
        flag = (flag & (~(self.DB_ITEM)))
		
    end  
    if (flag & self.DB_TASK) ~= 0 then
        shaco.sendum(CTX.db, "S.ex", {
            name="task",
            roleid=roleid,
            data=pb.encode("task_list", {list = self.task.tasks, old_task = self.task.old_tasks}),
            })
        flag = (flag & (~(self.DB_TASK)))
    end
    if (flag & self.DB_CARD) ~= 0 then	
    	local cards = card_container.get_card_container(self.cards.__card.__cards)
    	local container = {list = cards,partners = self.cards.__partner,own_cards = self.cards.__own_cards}
		--tbl.print(container)
        shaco.sendum(CTX.db, "S.ex", {
            name="card",
            roleid=roleid,
            data=pb.encode("card_list", {list = container}),
            })
        flag = (flag & (~(self.DB_CARD)))
        card_container.set_equip(self)
    end
	if (flag & self.DB_CLUB) ~= 0 then
		--tbl.print(self.club, "==========555555===init self.club == ", shaco.trace)
		 shaco.sendum(CTX.db, "S.ex", {
            name="club_info",
            roleid=roleid,
            data=pb.encode("club_data", {data = self.club}),
            })
        flag = (flag & (~(self.DB_CLUB)))
	end
	if (flag & self.DB_MAIL) ~= 0 then
		 shaco.sendum(CTX.db, "S.ex", {
            name="mail",
            roleid=roleid,
            data=pb.encode("mail_list", {data = self.mail.data,old_info = self.mail.old_info}),
            })
        flag = (flag & (~(self.DB_MAIL)))
	end
	if (flag & self.DB_LADDER) ~= 0 then
		shaco.sendum(CTX.db, "S.ex", {
            name="ladder_info",
            roleid=roleid,
            data=pb.encode("ladder_base", {ladder_data = self.ladder}),
            })
			--[[shaco.sendum(CTX.db, "S.ex", {
            name="ladder_info",
            roleid=roleid,
            data=pb.encode("ladder_base", {ladder_data = self.ladder}),
            }]]
        flag = (flag & (~(self.DB_LADDER)))
	end
	if (flag & self.DB_RECHARGE) ~= 0 then
		shaco.sendum(CTX.db, "S.ex", {
            name="recharge",
            roleid=roleid,
            data=pb.encode("recharge_data", {data = self.recharge}),
            })
        flag = (flag & (~(self.DB_RECHARGE)))
	end
	if (flag & self.DB_SPECTYPE) ~= 0 then
		shaco.sendum(CTX.db, "S.ex", {
            name="special_ectype",
            roleid=roleid,
            data=pb.encode("spectype_data", {sp_data = self.spectype}),
            })
        flag = (flag & (~(self.DB_SPECTYPE)))
	end
	if (flag & self.DB_ACTIVITY_MONEY) ~= 0 then
		shaco.sendum(CTX.db, "S.actmoney", {
            roleid=roleid,
			name=self.base.name,
			reward_money = self.activity.money_cnt,
			difficulty = self.activity.money_difficulty,
			date_time = shaco.now()//1000,
            })
        flag = (flag & (~(self.DB_ACTIVITY_MONEY)))
	end
	
	if (flag & self.DB_ACTIVITY_EXP) ~= 0 then
		shaco.sendum(CTX.db, "S.actexp", {
            roleid=roleid,
			name=self.base.name,
			over_time = self.activity.exp_time,
			difficulty = self.activity.money_difficulty,
			date_time = shaco.now()//1000,
            })
        flag = (flag & (~(self.DB_ACTIVITY_EXP)))
	end
	if (flag & self.DB_ACTIVITY) ~= 0 then
		shaco.sendum(CTX.db, "S.ex", {
            name="activity",
            roleid=roleid,
            data=pb.encode("activity_data", {data = self.activity}),
            })
        flag = (flag & (~(self.DB_ACTIVITY)))
	end
	self.db_dirty_flag = flag
end

function user:open_function()
	local level = self.base.level
	local open_bit = self.info.open_bit or 0
	local indx = 100
	local  __type = 1
	while true do 
		local tp = tpopen[indx]
		if not tp then 
			return
		end
		if tp.Value <= level then
			if (open_bit >> __type) & 1 == 0 then
				open_bit = open_bit + 2 ^ __type
				self.info.open_bit = open_bit
				if __type == FUNC_CLUB then
					--club.init_club(self)
				end
			end
		end
		__type = __type + 1
		indx = indx + 1
	end
end

-- exp
function user:addexp(got)
    if got <= 0 then
        return
    end
    local base = self.base
    local info = self.info
	local previous_level = base.level
    local index = base.race * 1000 + base.level
    info.exp = info.exp + got
	local flag = false
    while true do
        local tp = tprole[index]
        if tp then
            if info.exp >= tp.exp then 
				if base.level >= 100 then
					break
				end
				base.level = base.level+1
                index = index + 1
				task.set_task_progress(self,3,base.level,0)
				task.refresh_toclient(self, 3)
                info.exp = info.exp - tp.exp
                self:db_tagdirty(self.DB_ROLE)
				flag = true
            else
                break
            end
        else
            break
        end
    end
	self.add_exp  = got
	if flag == true then
		self:level_log()
		self.attribute:compute_attribute(base.race,base.level)
		self.attribute:add_attribute(self)
		--tbl.print(self.attribute.attribute,"-----------------------*************self.attribute.attribute  === ****-------------------")
		self:change_attribute()
		if base.level == tpgamedata.dayTaskLevel then
			--print("----------- base.level ==== "..base.level)
			task.update_daily(self,previous_level)
		end
		task.accept_new_task(self)
		--local min_level = task.ectype_task_min_level()
		--if base.level >= min_level and base.level < 10 then
		--	task.check_ectype_task(self)
	--	end
		
		self:open_function()
	end
	 self:db_tagdirty(self.DB_ROLE)
end

function user:sync_self_attribute()
	local attribute = self.attribute.attribute
	for k,v in pairs(self.attribute.equip_attribute) do
		attribute.hp = attribute.hp + v.hp 
		attribute.atk = attribute.atk + v.atk
		attribute.def = attribute.def + v.def
		attribute.mag = attribute.mag + v.mag
		attribute.mag_def = attribute.mag_def + v.mag_def
		attribute.atk_res = attribute.atk_res + v.atk_res
		attribute.mag_res = attribute.mag_res + v.mag_res
		attribute.atk_crit = attribute.atk_crit + v.atk_crit
		attribute.mag_crit = attribute.mag_crit + v.mag_crit
		attribute.hits = attribute.hits + v.hits
		attribute.block = attribute.block + v.block
		attribute.dodge = attribute.dodge + v.dodge
		attribute.hp_reply = attribute.hp_reply + v.hp_reply
		attribute.mp_reply = attribute.mp_reply + v.mp_reply
		--attribute_list[#attribute_list + 1] = equip_attribute_gen(k,v)
	end
	self.info.attribute = attribute
	--print("self.info.attribute:get_battle_value(self.base.tpltid) ==== "..self.info.attribute:get_battle_value(self.base.tpltid))
	--print("self.battle_value ============= "..self.battle_value.." card_container.get_partner_battle(self) === "..card_container.get_partner_battle(self))
	--self:send(IDUM_UPDATEROLEATTRIBUTE,{attribute=self.attribute.attribute,equip = attribute_list})	
end

function user:change_attribute()
	self.battle_value = self.attribute:get_battle_value(self.base.tpltid) + card_container.get_partner_battle(self)
    checkchange_battle_value(self)
	
    task.set_task_progress(self,25,self.battle_value,0)
	task.refresh_toclient(self, 25)
	self:sync_role_data()
	--print("self.base.level ========= "..self.base.level)
	local _attribute = self.attribute:compute_user_total_attribute()
	--tbl.print(_attribute,"---------------- _attribute ============= ")
	self:send(IDUM_UPDATEROLEATTRIBUTE,{attribute=_attribute})	
end

-- coin
function user:coin_enough(take)
    return self.info.coin >= take
end

function user:coin_take(take)
    local old = self.info.coin
    if old >= take then
        self.info.coin = old - take
		self:money_log()
        return true
    else
        return false
    end
end

function user:coin_got(got)
    if got == 0 then
        return 0
    end
    local old = self.info.coin
    self.info.coin = old + got 
    if self.info.coin < 0 then
        self.info.coin = 0
    end
	self:money_log()
    return self.info.coin-old
end

-- gold
function user:gold_enough(take)
    return self.info.gold >= take
end

function user:gold_take(take)
    local old = self.info.gold
    if old >= take then
        self.info.gold = old - take
		self:money_log()
        return true
    else
        return false
    end
end

function user:gold_got(got)
    if got == 0 then
        return 0
    end
    local old = self.info.gold
    self.info.gold = old + got
    if self.info.gold < 0 then
        self.info.gold = 0     
    end
	self:money_log()
    return self.info.gold-old
end

-- send
function user:send(msgid, v)
    local name = MSG_RESNAME[msgid]
    assert(name)
    shaco.sendum(CTX.gate, IDUM_GATE, self.connid, msgid, pb.encode(name, v))
end

function user:senderr(err)
    self:send(self.connid, IDUM_ERROR, {err=err})
end

function user:sync_role_data()
	local data = sync_role_gen()
	data.coin=self.info.coin
    data.gold=self.info.gold
	data.exp=self.info.exp
   	data.level=self.base.level
	data.physical = self.info.physical
	data.battle = self.battle_value
	data.add_exp = self.add_exp
	data.physical_time = self.info.physical_time
	data.server_time = shaco.now()//1000
	data.rmb = self.info.rmb
	--print("data.level ========= "..data.level)
	self:send(IDUM_SYNCROLEDATA,{info=data})
	self.add_exp = 0
end

function user:set_level(level)
	if level > 100 then
		level = 100
	end
	local previous_level = self.base.level
	self.base.level = level
	self.attribute:compute_attribute(self.base.race,level)
	self.attribute:add_attribute(self)
	self:change_attribute()
	self:db_tagdirty(self.DB_ROLE)
	task.accept_new_task(self)
	self:open_function()
	if level >= tpgamedata.dayTaskLevel then
		task.update_daily(self,previous_level)
	end
end

function user:compute_battle_value()
	self.battle_value = self.attribute:get_battle_value(self.base.tpltid) + card_container.get_partner_battle(self)

    checkchange_battle_value(self)
	
    task.set_task_progress(self,25,self.battle_value,0)
	task.refresh_toclient(self, 25)
	self:send(IDUM_SYNCBATTLEVALUE, {battle_value=self.battle_value})
end

function user:money_log()
	local roleid = self.base.roleid
	local coin = self.info.coin
	local gold = self.info.gold
	local create_time = shaco.now()//1000--os.date("%Y-%m-%d %X", shaco.now()//1000)
	shaco.sendum(CTX.logdb, "S.insert",{name = "x_log_money",fields = {roleid = roleid,coin = coin,gold = gold,create_time = create_time}})
end

function user:level_log()
	local roleid = self.base.roleid
	local level = self.base.level
	local log_name =os.date("x_log_level_%Y%m%d", shaco.now()//1000)
	local create_time = shaco.now()//1000--os.date("%Y-%m-%d %X", shaco.now()//1000)
	shaco.sendum(CTX.logdb, "S.insert",{name = "x_log_level",fields = {roleid = roleid,role_level = level,create_time = create_time}})
end

function user:create_log(roleid)
	local create_time = shaco.now()//1000--os.date("%Y-%m-%d %X", shaco.now()//1000)
	local log_name =os.date("x_log_create_%Y%m%d", shaco.now()//1000)
	shaco.sendum(CTX.logdb, "S.insert",{name = "x_log_create",fields = {roleid = roleid,create_time = create_time}})
end

function user:card_log(__type,PriceType,cardv)
	local roleid = self.base.roleid
	local buy_type = ""
	if __type == BUY_SINGLE then --coin buy
		if PriceType == 0 then
			buy_type = "single_coin"
		elseif PriceType == 1 then --single gold buy 
			buy_type = "single_gold"
		end
	elseif __type == BUY_TEN then -- ten
		buy_type = "ten_gold"
	end
	local tb = {}
	local cards = ""
	for i =1,#cardv do
		table.insert(tb,string.format("%s",cardv[i]))
		cards =table.concat(tb,",")
	end
	local create_time = shaco.now()//1000--os.date("%Y-%m-%d %X", shaco.now()//1000)
	shaco.sendum(CTX.logdb, "S.insert",{name = "x_log_card",fields = {roleid = roleid,buy_type = buy_type,cards = cards,create_time = create_time}})
end

function user:item_log(itemid,itemcnt)
	local roleid = self.base.roleid
	local create_time = shaco.now()//1000 --os.date("%Y-%m-%d %X", shaco.now()//1000)
	shaco.sendum(CTX.logdb, "S.insert",{name = "x_log_item",fields = {itemid = itemid,roleid = roleid,itemcnt = itemcnt,create_time = create_time}})
end

function user:log_in_out_log(in_out)
	if not self.base then
		return
	end
	local roleid = self.base.roleid
	local cur_time = shaco.now()//1000 ---os.date("%Y-%m-%d %X", shaco.now()//1000)
	local login_time = ""
	local logout_time = ""
	local login_state 
	if in_out == 1 then  ---login
		login_state = "login"
	else
		login_state = "logout"
	end
	shaco.sendum(CTX.logdb, "S.insert",{name = "x_log_in_out",fields = {login_state = login_state,roleid = roleid,create_time = cur_time}})
end

function user:log_gm_log(name)
	if not self.base then
		return
	end
	local roleid = self.base.roleid
	local cur_time = shaco.now()//1000 ---os.date("%Y-%m-%d %X", shaco.now()//1000)
	shaco.sendum(CTX.logdb, "S.insert",{name = "x_log_gm",fields = {gm_name = name,roleid = roleid,create_time = cur_time}})
end

function user:get_max_atrribute()
	local verify_value = 0
	local battle_value = self.attribute:get_battle_value(self.base.tpltid)
	local partner_pos,partner_battle = card_container.get_max_partner_battle(self)
	if partner_battle > battle_value then
		verify_value = self.cards.__card.__attributes[partner_pos]:compute_verify()
	else
		verify_value = self.attribute:compute_verify()
	end
	return verify_value
end

function user:x_log_role_cheat(ectypeid,clubid,robotid,opponent_battle)
	if not self.base then
		return
	end
	local roleid = self.base.roleid
	local cur_time = shaco.now()//1000--os.date("%Y-%m-%d %X", shaco.now()//1000)
	local battle_value = self.attribute:get_battle_value(self.base.tpltid)
	local verify_value = self.attribute:compute_verify()
	local bag = self:getbag(BAG_EQUIP)
	local role_weapon = ""
	local partners = self.cards.__partner
	local card__attributes = self.cards.__card.__attributes
	local pos_level_breakthrough_guarantee = ""
	for i =1,2 do
		if partners[i].pos > 0 then
			local card = card_container.get_target(self, partners[i].pos)
			if not card then
				shaco.trace(sfmt("partner info error pos ==  %d !!! ", partners[i].pos))
				break
			end
			local card_battle_value = card__attributes[partners[i].pos]:compute_battle(card.cardid)
			pos_level_breakthrough_guarantee = pos_level_breakthrough_guarantee.."pos="..partners[i].pos..",id="..card.cardid..",lvl="..card.level..",breakth="..card.break_through_num..",battle="..card_battle_value..";"
		end
	end
	local fields = {}
	fields.roleid = roleid ; fields.ectypeid = ectypeid;fields.battle_value = battle_value;fields.pos_level_breakthrough_guarantee = pos_level_breakthrough_guarantee
	fields.clubid = clubid ; fields.opponent_battle = opponent_battle; fields.robot_id = robotid; fields.create_time = cur_time
	shaco.sendum(CTX.logdb, "S.insert",{name = "x_log_role_cheat",fields = fields})
end

function user:x_log_recharge(recharge)
	if not self.base then
		return
	end
	local roleid = self.base.roleid
	local cur_time = shaco.now()//1000--os.date("%Y-%m-%d %X", shaco.now()//1000)
	local fields = {}
	fields.roleid = roleid ; fields.florderid = recharge.florderid;fields.orderid = recharge.orderid;fields.cardno = recharge.cardno
	fields.productid = recharge.productid ; fields.merpriv = recharge.merpriv; fields.amount = tonumber(recharge.amount); fields.cardstatus = tonumber(recharge.cardstatus);fields.ret = tonumber(recharge.ret);fields.create_time = cur_time
	shaco.sendum(CTX.logdb, "S.insert",{name = "x_log_recharge",fields = fields})
end

function user:weapon_intensify(rate,tp)
	self.attribute:weapon_intensify(rate,tp)
end

function user:change_role_battle_value()
	self.battle_value = self.attribute:get_battle_value(self.base.tpltid) + card_container.get_partner_battle(self)
    checkchange_battle_value(self)

	task.set_task_progress(self,25,self.battle_value,0)
	task.refresh_toclient(self, 25)
	self:sync_role_data()
end

function user:add_vip_exp(exp)
	local vip = self.info.vip
	if not vip then
		vip = vip_gen()
	end
	local front_level = vip.vip_level
	local index = vip.vip_level + 1
	vip.vip_exp = vip.vip_exp + exp
	while true do
        local tp = tpvip[index]
        if tp then
            if vip.vip_exp >= tp.exp then 
                vip.vip_level = vip.vip_level + 1
                index = index + 1
                vip.vip_exp = vip.vip_exp - tp.exp
				vip.buy_flag = 0
            else
                break
            end
        else
            break
        end
    end
	self.info.vip = vip
	if front_level == 0 and exp > 0 then
		task.finsh_vip_task(self)  -- update_daily_task(self)
	end
	self:send(IDUM_SYNCVIPINFO,{vip=vip})
	if front_level < vip.vip_level then
		card_container.add_card_bag_container(self,front_level + 1,vip.vip_level)
	end
end

function user:deal_with_recharge(rechargev)
	local flag = recharge.check_order(self,rechargev.orderid)
	if not flag then
		return
	end
	local status = tonumber(rechargev.cardstatus)
	if rechargev.ret == "1" then
		local index = tonumber(rechargev.amount)
		local tp = tprecharge[index]
		if not tp then
			return
		end
		local got = tp.Reward + tp.SpecialReward
        self.info.rmb = self.info.rmb + got
        self.info.rmb_last_time = shaco.now()//1000
		self:add_vip_exp(tp.Reward)
		self:gold_got(got)
		self:x_log_recharge(rechargev)
		self:sync_role_data()
		self:db_tagdirty(self.DB_ROLE)
		self:send(IDUM_NOTICERECHARGESTATUS,{status=status,ret = eRecharge_Success})
	else
		self:send(IDUM_NOTICERECHARGESTATUS,{status=status,ret = eRecharge_Fail})
	end
	recharge.delete_order(self,rechargev.orderid)
end

function user:delete_order(order)
	recharge.delete_order(self,order)
end

function user:get_power_reward()
	local vip = self.info.vip
	local level = 0
	if vip then
		level = vip.vip_level
	end
	local tp = tpvip[level + 1]
	if not tp then
		return 0
	end
	local index = math.random(1,4)
	--print("---------------index ========= "..index)
	return tp.power_reward[index]
end

function user:get_vip_value(_type)
	local vip = self.info.vip
	local level = 0
	if vip then
		level = vip.vip_level
	end
	local tp = tpvip[level + 1]
	if not tp then
		return 0
	end
	local value = 0
	if _type == VIP_MYSTERY_T then 
		value = tp.mystery_shop_time
	elseif _type == VIP_NORMAL_T then
		value = tp.normal_shop
	elseif _type == VIP_BUY_LADDER_T then
		value = tp.pay_Ladder
	elseif _type == VIP_CLUB_REFRESH_T then
		value = tp.club_refresh
	elseif _type == VIP_ENDLESS_TOWER_T then
		value = tp.EndlessTower
	elseif _type == VIP_EXP_TOWER_T then
		value = tp.ExpTower
	elseif _type == VIP_MONEY_TOWER_T then
		value = tp.MoneyTower
	elseif _type == VIP_BUY_POWER_T then
		value = tp.pay_power
	elseif _type == VIP_BUY_CARD_BAG_T then
		value = tp.card_bag
	elseif _type == VIP_GOLD_WASH_T then
		value = tp.Wash
    elseif _type == VIP_BUYGOLD_T then
        value = tp.buygold
	elseif _type == VIP_MOPUP_TICKET_T then
		value = tp.clearall_card
	end
	return value
end

function user:set_task_progress(method,progress,progress2)
	task.set_task_progress(self,method,progress,progress2)
end

function user:check_red_point()
	if self.club.challengecnt > 0 then
		if ((self.red_point >> CLUB_POINT) & 1) == 0 then
			self.red_point = self.red_point + 2^CLUB_POINT
		end
	end
	if self.ladder.challengecnt > 0 then
		if ((self.red_point >> LADDER_POINT) & 1) == 0 then
			self.red_point = self.red_point + 2^LADDER_POINT
		end
	end
	if self.ladder.last_rank > 0 then
		if ((self.red_point >> LADDER_POINT) & 1) == 0 then
			self.red_point = self.red_point + 2^LADDER_POINT
		end
	end
end

function user:getrmb()
    return self.info.rmb
end

function user:gm_recharge(index)
	local tp = tprecharge[index]
	if not tp then
		return
	end
	local got = tp.Reward + tp.SpecialReward
    self.info.rmb = self.info.rmb + got
    self.info.rmb_last_time = shaco.now()//1000
	self:add_vip_exp(tp.Reward)
	self:gold_got(got)
	self:sync_role_data()
	local act = self.activity
	local flag = false
	if act.charge1th_award == 0 then
		act.charge1th_award = 1
		flag = true
	end
	for i = 1,3 do
		local daily_charge = act.daily_charge1th_list[i]
		if daily_charge.reward_state == 0 then
			daily_charge.reward_state = 1
			flag = true
			break
		end
	end
	if flag and ((self.bit_value >> REQ_ACTIVITY_MAIN) & 1) ~= 0 then
		self:send(IDUM_NOTICEOPENACTIVITYINFO, {own_activity = act})
	end
	--tbl.print(act.daily_charge1th_list,"-------------- act.daily_charge1th_list ==== ")
--	if self.activity.daily_charge1th_award ~= 2 then
--		self.activity.daily_charge1th_award = 1
	--end
	print(" self.info.rmb === "..self.info.rmb)
	self:db_tagdirty(self.DB_ACTIVITY)
	self:db_tagdirty(self.DB_ROLE)
	self:send(IDUM_NOTICERECHARGESTATUS,{status=0,ret = eRecharge_Success})
end

function user:compute_equip_attribute(equip)
	return equip_attributes.compute_equip_attribute(equip)
end

return user
