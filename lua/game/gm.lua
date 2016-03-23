local shaco = require "shaco"
local tonumber = tonumber
local floor = math.floor
local tbl = require "tbl"
local REQ = require "req"
local CTX = require "ctx"
local scene = require "scene"
local task = require "task"
local itemop = require "itemop"
local card_container = require "card_container"
local mystery = require "mystery"
local club = require "club"
local ladder  = require "ladder"
local mail_fast = require "mail_fast"
local task_fast = require "task_fast"
local tpclub = require "__tpclub"
local tptask = require "__tptask"
local attribute = require "attribute"
local ladder_fast = require "ladder_fast"
local sfmt = string.format
local find = string.find
local sub = string.sub
local len = string.len
local GM = {}
local md5 = require"md5"
local cjson = require "cjson"
local mail = require "mail"
local code = require "save_code"
local code_fast = require "code_fast"
local endless_fast = require "endless_fast"
local spectype = require"spcial_ectype"
local broad_cast = require "broad_cast"
local rcall = shaco.callum
local activity_fast = require "activity_fast"
local itemdrop = require "itemdrop"
local rank_fight = require "rank_fight"
local gift_reward = require "gift_reward"
local tpgamedata = require "__tpgamedata"
local crypt = require "crypt.c"

GM.help = function(ur)
    local t = {}
    for k, _ in ipairs(GM) do
        table.insert(t, k)
    end
    local content = table.concat(t, "\r\n")
    return true
end

GM.getitem = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
    if #args < 3 then
        return false
    end
    local tpltid = tonumber(args[2])
    local count  = tonumber(args[3])
    if itemop.gain(ur, tpltid, count) > 0 then
        itemop.refresh(ur)
        ur:db_tagdirty(ur.DB_ITEM)
    end
    return true
end

GM.getequip = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
    if #args < 5 then
        return false
    end
    local tpltid = tonumber(args[2])
    local count  = tonumber(args[3])
	local hole_cnt = tonumber(args[4])
	local wash_cnt = tonumber(args[5])
    if itemop.gain(ur, tpltid, count,hole_cnt,wash_cnt) > 0 then
        itemop.refresh(ur)
        ur:db_tagdirty(ur.DB_ITEM)
    end
    return true
end

GM.itemlist = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
    if #args < 4 then
        return false
    end
    local pkg = ur.package
    local min_id = tonumber(args[2])
    local max_id  = tonumber(args[3])
	local count  = tonumber(args[4])
	for i = min_id,max_id do
		itemop.gain(ur, i, count)
	end
	itemop.refresh(ur)
    ur:db_tagdirty(ur.DB_ITEM)
end

GM.getcoin = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
	
    if #args < 2 then
        return false
    end
    local count = tonumber(args[2])
    if ur:coin_got(count) ~= 0 then
        ur:db_tagdirty(ur.DB_ROLE)
    end
	ur:sync_role_data()
    return true
end

GM.getgold = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
    if #args < 2 then
        return false
    end
    local count = tonumber(args[2])
    if ur:gold_got(count) ~= 0 then
        ur:db_tagdirty(ur.DB_ROLE)
    end
	ur:sync_role_data()
    return true
end

GM.clearmoney = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	ur.info.coin = 1
	ur.info.gold = 1
	ur:db_tagdirty(ur.DB_ROLE)
	ur:sync_role_data()
end

GM.changescene = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
    if #args < 2 then
        return false
    end
    local tpid = tonumber(args[2])
    scene.enter(ur, tpid)
    return true
end

GM.move = function(ur, args)
    if  ur.gm_level < 2 then
		return false
	end
    if #args < 3 then
        return false
    end
    local x = tonumber(args[2])
    local y = tonumber(args[3])
    scene.move(ur, {posx=x,posy=y})
    return true
end

GM.stop = function(ur, args)
    if  ur.gm_level < 2 then
		return false
	end
    if #args < 3 then
        return false
    end
    local x = tonumber(args[2])
    local y = tonumber(args[3])
    scene.movestop(ur, {posx=x,posy=y})
    return true
end

GM.taskacc = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
	if #args < 2 then
        return false
    end
    local taskid = floor(tonumber(args[2]))
    local tempv = {taskid = taskid}
	REQ[IDUM_ACCEPTTASK](ur, tempv)
    return true
end

GM.taskclear = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
	if #args < 2 then
        return false
    end
    local taskid = floor(tonumber(args[2]))
	task.taskclear(ur,taskid)
	ur:db_tagdirty(ur.DB_TASK)
    return true
end

GM.taskfinish = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
	if #args < 2 then
        return false
    end
    local taskid = floor(tonumber(args[2]))
    if task.finish(ur,taskid) == true then	
        ur:db_tagdirty(ur.DB_TASK)
        ur:send(IDUM_TASKLIST, {info = ur.task.tasks})
    end
    return true
end

GM.taskreward = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
	if #args < 2 then
        return false
    end
    local taskid = floor(tonumber(args[2]))
    local tempv = {taskid = taskid}
    REQ[IDUM_GETREWARD](ur, tempv)
    return true
end


GM.equipcast = function(ur,args)
	if  ur.gm_level < 2 then
		return false
	end
	if #args < 2 then
        return false
    end
    local itemid = floor(tonumber(args[2]))
    local star = floor(tonumber(args[3]))
    local tempv = {id = itemid, star = star}
    REQ[IDUM_EQUIPGODCAST](ur, tempv)
    return true
end

GM.equipinfy = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
	if #args < 2 then
        return false
    end
    local itemid = floor(tonumber(args[2]))
    local tempv = {itemid = itemid}
    REQ[IDUM_EQUIPINTENSIFY](ur, tempv)
    return true
end

GM.equipforge = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
	if #args < 2 then
        return false
    end
    local itemid = floor(tonumber(args[2]))
    local tempv = {itemid = itemid}
    REQ[IDUM_EQUIPFORGE](ur, tempv)
    return true
end

GM.equipcompose = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
	if #args < 2 then
        return false
    end
    local tempv = {szmaterial = args[2]}
    REQ[IDUM_EQUIPCOMPOSE](ur, tempv)
    return true
end

GM.passectype = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
	if #args < 3 then
        return false
    end
    local ectypeid = floor(tonumber(args[2]))
	local hp = floor(tonumber(args[3]))
	local pass_time = 0
    local tempv = {ectypeid = ectypeid,pass_time = 100,user_hp = hp}
	REQ[IDUM_PASSECTYPE](ur, tempv)
    return true
end


GM.getcard = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
    if #args < 3 then
        return false
    end
    local cards = ur.cards
    local cardid = tonumber(args[2])
	local cardcnt = tonumber(args[3])
    if not card_container.enough(ur,cardcnt) then
    	return false
    end
    if cards:put(ur,cardid,cardcnt) > 0 then
        card_container.refresh(ur)
        ur:db_tagdirty(ur.DB_CARD)
    end
    return true
end

GM.selfequip = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
	if #args < 2 then
        return false
    end
	local itemid = floor(tonumber(args[2]))
	local bag = ur:getbag(BAG_EQUIP)
	if itemop.self_equip(ur,bag,itemid) then
		print(" ------------  SERR_NOT_NEED_OCCUPATION     -------")
	else
		itemop.refresh(ur)
		ur:db_tagdirty(ur.DB_ITEM)
	end
end

GM.equip = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
	if #args < 3 then
        return false
    end
	local __type = floor(tonumber(args[2]))
	local pos = floor(tonumber(args[3]))
	local tempv = {bag_type = __type,pos = pos}
	REQ[IDUM_EQUIP](ur,tempv)
    return true
end

GM.cardequip = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
	if #args < 4 then
        return false
    end
    local bag_type = floor(tonumber(args[2]))
	local itempos = floor(tonumber(args[3]))
	local targetpos = floor(tonumber(args[4]))
	local tempv = {bag_type = bag_type,pos = itempos,card_pos = targetpos}
	REQ[IDUM_EQUIPCARD](ur, tempv)
    return true
end

GM.cardup = function(ur, args)
	if  ur.gm_level < 2 then
		return false
	end
	if #args < 5 then
        return false
    end
    local function card_up_gen()
    	return {
    		targetid=0,
   			tarpos=0,	
   			material={},
    	}
    end
    local function material_gen()
    	return {
    		cardid = 0,
    		pos = 0,
    	}
    end
    local targetid = floor(tonumber(args[2]))
    local targetpos = floor(tonumber(args[3]))
    local materials = {}
    local material = material_gen()
    material.cardid = floor(tonumber(args[4]))
    material.pos = floor(tonumber(args[5]))
    materials[#materials+1] = material
    local card_up = card_up_gen()
    card_up.targetid = targetid
    card_up.tarpos = targetpos
    card_up.material = materials
    REQ[IDUM_CARDUP](ur,card_up)
    
end

GM.cardclear = function(ur, args)
	ur.cards:clearcard()
	card_container.refresh(ur)
    ur:db_tagdirty(ur.DB_CARD)
end

GM.cardpartner = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
        return
    end
    local pos = floor(tonumber(args[2]))
    local posv = {}
    posv[#posv + 1] = pos
    REQ[IDUM_CARDPARTNER](ur, {pos = posv})
end

GM.buyitem = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
    if #args < 3 then
        return
    end
    local buy_type = floor(tonumber(args[2]))
    local id = floor(tonumber(args[3]))
    REQ[IDUM_SHOPBUYITEM](ur,{buy_type = buy_type,random_id = id})
end

GM.copydrop = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
    if #args < 2 then
        return
    end
    local mapid = floor(tonumber(args[2]))
    REQ[IDUM_SCENEENTER](ur, {mapid = mapid})
end

GM.dazzlecompose = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	 if #args < 3 then
        return
    end
	local _type = floor(tonumber(args[2]))
	local _level = floor(tonumber(args[3]))
	REQ[IDUM_USEDAZZLE](ur,{dazzle_type = _type,dazzle_level = _level})
end

GM.fraequip = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	 if #args < 4 then
        return
    end
	local _type = floor(tonumber(args[2]))
	local _level = floor(tonumber(args[3]))
	local _id = floor(tonumber(args[4]))
	REQ[IDUM_EQUIPDAZZLEFRAGMENT](ur,{fragmentid = _id,dazzle_type = _type,dazzle_level = _level})
end

GM.fracompose = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 4 then
        return
    end
	local _type = floor(tonumber(args[2]))
	local _level = floor(tonumber(args[3]))
	local _id = floor(tonumber(args[4]))
	REQ[IDUM_COMPOSEFRAGMENT](ur,{dazzle_type = _type,dazzle_level = _level,fragmentid = _id})
end

GM.mysteryitem = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 3 then
		return
	end
	local itemid = floor(tonumber(args[2]))
	local count = floor(tonumber(args[3]))
	REQ[IDUM_REQBUYMYSTERYITEM](ur,{itemid = itemid,cnt = count})
end

GM.refreshmystery = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local _type = floor(tonumber(args[2]))--1是神秘商店7是普通商店
	if ur:gold_take(200) == false then
		return 
	else
		mystery.refresh_mystery_shop(ur,_type)
	end
end

GM.addcardfragment = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 3 then
		return
	end
	local fragmentid = floor(tonumber(args[2]))
	local count = floor(tonumber(args[3]))
	itemop.gain(ur, fragmentid, count)
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
	--club.add_fragment(ur,fragmentid,count)
end
GM.refreshclub = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	local club = club.refresh_club(ur,1)
	ur.club = club
end

GM.enterclub = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local clubid =  floor(tonumber(args[2]))
	REQ[IDUM_REQENTERCLUBSCENE](ur,{clubid = clubid})
end

GM.costscore = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 3 then
		return
	end
	local clubid =  floor(tonumber(args[2]))
	local type = floor(tonumber(args[3]))
	REQ[IDUM_REQEXTRACTREWARD](ur, {clubid = clubid,use_score_type = type})
end

GM.exchangecard = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 4 then
		return
	end
	local cardid =  floor(tonumber(args[2]))
	local buy_type = floor(tonumber(args[3]))
	local card_count = floor(tonumber(args[4]))
	REQ[IDUM_REQEXCHANGECARD](ur, {cardid = cardid,buy_type = buy_type,card_count = card_count})
end

GM.addscore = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local score =  floor(tonumber(args[2]))
	ur.club.score = ur.club.score + score
	ur:db_tagdirty(ur.DB_CLUB)
end

GM.enterladder = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	ladder.enter_ladder(ur,1)
end

GM.addladderscore = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local score =  floor(tonumber(args[2]))
	ladder.add_ladder_score(ur,score)
	local roleid = ur.base.roleid
	local record_info = ladder_fast.get_role_ladder_info(roleid)
	local dirty = false
	if record_info == nil then
		return
	end
	record_info.score = ur.ladder.score
	ladder_fast.update_ranking(ur)
end

GM.reduceladdscore = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local score =  floor(tonumber(args[2]))
	ladder.reduce_ladder_score(ur,score)
end

GM.updaterank = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	ladder.update_ranking(ur)
end

GM.reqrank = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	ladder.req_ladder_rank(ur)
end

GM.openmystery = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	mystery.random_mystery_shop(ur,100)
end

GM.mailinit = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	mail_fast.init()
end

GM.lastrank = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local last_rank =  floor(tonumber(args[2]))
	ladder.changelastrank(ur,last_rank)
end

GM.refreshladder = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	REQ[IDUM_REQBUYCHALLENGECNT](ur, {})
end

GM.opponent = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	REQ[IDUM_REQSEARCHOPPONENT](ur, {})
end

GM.setlevel = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local level =  floor(tonumber(args[2]))
	ur:set_level(level)
end

GM.changeweapon = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local weaponid =  floor(tonumber(args[2]))
	local bag = ur:getbag(BAG_EQUIP)
	itemop.remove_bypos(bag,EQUIP_WEAPON,1)
	itemop.gain_weapon(bag, weaponid)
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
end

GM.addhonor = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local honor =  floor(tonumber(args[2]))
	ladder.add_ladder_honor(ur,honor)
end

GM.items = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	local items = {}
	local cnts = {}
	for i=2,#args do
		if i % 2 == 0 then
			items[#items + 1] = args[i]
		else
			cnts[#cnts + 1] = args[i]
		end
	end
	for i =1,#items do
		itemop.gain(ur, tonumber(items[i]), tonumber(cnts[i]))
	end
	itemop.refresh(ur)
    ur:db_tagdirty(ur.DB_ITEM)
end

GM.test = function(ur,args)
	--if  ur.gm_level < 2 then
	--	return
	--end
	--ur.info.refresh_time = ur.info.refresh_time - 86400
--	task.clear_daily(ur)
	--REQ[IDUM_REQONEKEYUNINSTALLGEM](ur,{})
	--REQ[IDUM_REQONEKEYCOMPOSEALLGEM](ur,{})
--	spectype.set_challenge_cnt(ur)
	--[[local back_value = "133724588631&10000010000000&100000&12295150269929492|100|1|0|xxxxxxxx"
	local p = "&"
	for w in string.gmatch(back_value, "[^&]+") do
     print("w",w)                   
   end 
	for w in string.gmatch(back_value, "[^"..p.."]+") do
     print(w)                   
   end ]]
  -- ur.info.refresh_time = ur.info.refresh_time - 86400
	--ur:db_tagdirty(ur.DB_ROLE)
	--code.scode()
	--spectype.moment_reward(ur,100)
	--activity_fast.req_open_activity_list(ur)
	--[[local activity = ur.activity
	activity.money_difficulty = 1
	activity.money_cnt = 1000000
	ur:db_tagdirty(ur.DB_ACTIVITY_MONEY)
	activity.money_difficulty = 1
	activity.exp_time = 100
	ur:db_tagdirty(ur.DB_ACTIVITY)
	ur:db_tagdirty(ur.DB_ACTIVITY_EXP)]]
	--REQ[IDUM_REQGETWARRESERVE](ur,{})
	--rcall(CTX.db, "L.delete", {roleid=ur.base.roleid, name="activity"})
	--mail.add_activity_mail(ur,1,1,1)
	--activity_fast.provide_strongest_fight_reward()
	
	
	--[[if #args < 3 then
		return
	end
	local toll_gate_type = floor(tonumber(args[2]))
	local difficulty =  floor(tonumber(args[3]))
	REQ[IDUM_REQTOLLGATEECTYPE](ur,{toll_gate_type = toll_gate_type,difficulty =difficulty})]]
	--activity_fast.req_open_activity_list(ur)
	
	
	
	--[[
	for k,v in pairs(md5) do
		print(k)
		--tbl.print(v,"---------------- v==== ")
	end
	local sid = "sid=ssh1game9c76aa0a6b49466b941406ba25cc47271469100ee95ce35197bb31e221574088275611"
	local test_ = md5.sumhexa(sid)
--	for k,v in pairs(crypt) do
		--print(k,v)
	--end
	--local s_in = crypt.dhsecret("sid=abcdefg123456202cb962234w4ers2aaa")
	print(test_)
	--613711383d4d6313
	--091391c3613711383d4d631318674ac8
	--091391c3613711383d4d631318674ac8
	]]
	
end

GM.wood = function(ur, args)
	local function kill_monster_gen()
		return {
			monster_id = 0,
			kill_cnt = 0
		}
	end
	local monster_list = {}
	local first_cnt = floor(tonumber(args[2]))
	for i = 1,first_cnt do
		local monster = kill_monster_gen()
		local gift_index,decimals = math.modf(i/2)
		if decimals == 0 then
			monster.monster_id = 601002
		else
			monster.monster_id = 601003
		end
		monster.kill_cnt = 3
		monster_list[#monster_list + 1] = monster
	end
	REQ[IDUM_REQBALANCEWOODBARREL](ur,{monster_list = monster_list,ectype_type = TOLL_GATE_RANK_OILDRUM_T})
	--[[message kill_monster_data {
	optional uint32 monster_id = 1;//
	optional uint32 kill_cnt = 2;//
}
	repeated kill_monster_data monster_list = 1;//
	optional uint32 ectype_type = 2;//
	IDUM_REQBALANCEWOODBARREL]]
end

GM.ladderover = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	REQ[IDUM_NOTICEBATTLEOVER](ur,{battle_result = 1})
end

GM.setcardlvl = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 3 then
		return
	end
	local tarpos = floor(tonumber(args[2]))
	local level =  floor(tonumber(args[3]))
	card_container.set_level(ur,tarpos,level)
end

GM.setcardlevel = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 3 then
		return
	end
	local cardid = floor(tonumber(args[2]))
	local level =  floor(tonumber(args[3]))
	card_container.set_card_level(ur,cardid,level)
end

GM.addrobot = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	local cnt = floor(tonumber(args[2]))
	scene.addrobot(ur,cnt)
end

GM.setkillcnt = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 3 then
		return
	end
	local ectype_id = floor(tonumber(args[2]))
	local kill_cnt =  floor(tonumber(args[3]))
	REQ[IDUM_NOTICEKILLMONSTERCNT](ur,{ectype_id = ectype_id,kill_cnt = kill_cnt})
	
end

GM.sweep = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 3 then
		return
	end
	local ectype_id = floor(tonumber(args[2]))
	local sweep_type =  floor(tonumber(args[3]))
	REQ[IDUM_REQSWEEPECTYPE](ur,{sweep_type = sweep_type,ectype_id = ectype_id})
end

GM.clearphy = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	ur.info.physical = 0
	ur:sync_role_data()
	ur:db_tagdirty(ur.DB_ROLE)
end

GM.addphy = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	ur.info.physical = ur.info.physical + 100
	ur:sync_role_data()
	ur:db_tagdirty(ur.DB_ROLE)
end

GM.reduceref = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	ur.info.refresh_time = ur.info.refresh_time - 86400
	ur:db_tagdirty(ur.DB_ROLE)
end

GM.addexp = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local exp = floor(tonumber(args[2]))
	ur:addexp(exp)
	ur:sync_role_data()
end

GM.reduceexp = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local exp = floor(tonumber(args[2]))
	local info = ur.info
    info.exp = info.exp - exp
	ur:sync_role_data()
	ur:db_tagdirty(ur.DB_ROLE)
end

GM.scene = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
    if #args < 2 then
    end
    local id = tonumber(args[2])
    print ("scene last:", ur.info.last_city, ur.info.lastx, ur.info.lasty)
    scene.enter(ur, id)
    print ("scene enter:", id, ur.info.posx, ur.info.posy)
    if ur.scene.__iscity then
        ur.info.posx = 100
        ur.info.posy = 200
        print ("--enter city so: xy 100, 200")
    end 
end

GM.recharge = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	local str_order = "51852908-10097-01150503215438609"
	REQ[IDUM_NOTICEORDERID](ur,{str_order = str_order})
	
end


local function get_mail_item()
	if  ur.gm_level < 2 then
		return
	end
	local function mail_item_gen()
		return {
			item_type = 0,
			item_id = 0,
			item_cnt = 0,
		}
	end
	local items = {}
	for i = 1,5 do
		local item_info = mail_item_gen()
		item_info.item_type = 1
		item_info.item_id = 42006120
		item_info.item_cnt = 2
		items[#items + 1] = item_info
	end
	return items
end

GM.addmail = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	 if #args < 4 then
    end
--[[	local function mail_gen()
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
	local mail_info = mail_gen()
	mail_info.mail_type = 1
	mail_info.item_info = get_mail_item()
	mail_info.unread = 86400000
	mail_info.read_save = 0
	mail_info.mail_theme = "奖励"
	mail_info.mail_content = "测试奖励"
	mail.add_new_mail(ur,mail_info)
	ur:db_tagdirty(ur.DB_MAIL)]]
	local id = tonumber(args[2])
	local num = tonumber(args[3])
	local item_type = tonumber(args[4])
	mail.add_new_mail(ur,id,num,0,0,item_type)
end

GM.clearmail = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	local mails = ur.mail
	mails.data = {}	
	mails.old_info = {}
	ur:db_tagdirty(ur.DB_MAIL)
	ur:send(IDUM_MAILLIST,{data = ur.mail.data})
end

GM.showmail = function(ur, args)
	if ur.gm_level < 2 then
		return
	end
	shaco.trace(tbl(ur.mail,"------ ur.mail === "))
end

GM.clearbag = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	
	local bag_type = BAG_MAT
	local bag = ur:getbag(bag_type)
	local package_size = tpgamedata.WarehouseMax
--	print("---------------------------  package_size == "..package_size)
	for i =1,package_size do
		local item = itemop.get(bag, i)
		if item then
			--tbl.print(item, "=============init item", shaco.trace)
			--print("=================  item.stack == "..item.stack)
			itemop.remove_bypos(bag, item.pos, item.stack)
		end
	end
	 itemop.refresh(ur)
     ur:db_tagdirty(ur.DB_ITEM)
end

GM.exchcode = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local code = args[2]
	print("=================  code == "..code)
	code_fast.exchage_code(ur,code)
end

GM.resetclub = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	club.reset_curclub(ur)
end

GM.resetendless = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	spectype.onchangeday(ur)
	spectype.sync_special_ectype(ur)
end

GM.setmaxfloor = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local max_floor = tonumber(args[2])
	spectype.set_max_floor(ur,max_floor)
end

GM.endless = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local max_floor = tonumber(args[2])
	endless_fast.balance_endless_rank(ur,max_floor)
end

GM.clear = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	spectype.clear_state(ur)
end

GM.autoendless = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	spectype.auto_matic_challenge(ur)
end

GM.setvip = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local exp = tonumber(args[2])
	ur:add_vip_exp(exp)
	ur:db_tagdirty(ur.DB_ROLE)
end

GM.moneyrank = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	--local temp = {kill_cnt = 100,drop_coin = 2000}
	--REQ[IDUM_REQCHALLENGEREWARD](ur, temp)
	activity_fast.balance_money_rank(ur,1,200)
end

GM.recharge = function(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local count = tonumber(args[2])
	ur:gm_recharge(count)
end

GM.tollgate = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	REQ[IDUM_REQTOLLGATEECTYPE](ur, {toll_gate_type = 22})
end

GM.clearexp = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	ur.info.exp = 1
	ur:db_tagdirty(ur.DB_ROLE)
	ur:sync_role_data()
end

GM.rankfight = function(ur,args)
	if  ur.gm_level < 2 then
		return
	end
	rank_fight.provide_strongest_fight_reward(ur)
end

--------------外网专属GM------------------------
GM.givemoney = function(ur,args,flag)
	print("----------------------------------- "..ur.gm_level)
    if ur:coin_got(100000) ~= 0 then
        ur:db_tagdirty(ur.DB_ROLE)
    end
	ur:sync_role_data()
	ur:log_gm_log("givemoney")
end

GM.givegold = function(ur, args,flag)
    if ur:gold_got(10000) ~= 0 then
        ur:db_tagdirty(ur.DB_ROLE)
    end
	ur:sync_role_data()
	ur:log_gm_log("givegold")
end

GM.giveexp = function(ur,args,flag)
	ur:addexp(1000)
	ur:db_tagdirty(ur.DB_ROLE)
	ur:sync_role_data()
	ur:log_gm_log("giveexp")
end

GM.givehonor = function(ur,args,flag)
	ladder.add_ladder_honor(ur,1000)
	ladder_fast.enter_ladder(ur)
	ur:log_gm_log("givehonor")
end

GM.givecard = function(ur,args,flag)
	if #args < 2 then
		return
	end
	local card_indx = tonumber(args[2])
	if card_indx > 5 then
		return
	end
	local cards = ur.cards
    local cardid = 10000 * card_indx + 1099
    if not card_container.enough(ur,1) then
    	return
    end
    if cards:put(ur,cardid,1) > 0 then
        card_container.refresh(ur)
        ur:db_tagdirty(ur.DB_CARD)
    end
	ur:log_gm_log("givecard"..card_indx)
end

GM.givevip = function(ur,args,flag)
	ur:add_vip_exp(500)
	--tbl.print(ur.info.vip, "=============init ur.info.vip == ", shaco.trace)
	ur:db_tagdirty(ur.DB_ROLE)
end

GM.testact = function(ur, args, flag)
    if #args < 3 then
        return
    end
    local actid = tonumber(args[2])
    local value = tonumber(args[3])
    local tempv = {activity_id = actid, value=value}
    local r = REQ[IDUM_REQACTIVITYREWARD](ur, tempv)
    shaco.trace("act req result:"..tostring(r))
end

--GM.drop = function(ur, args, flag)
--    for i=1,10000 do
--        local drop_list = itemdrop.random_ectype_drop(1001,1)
--        assert(#drop_list==4)
--        local item1 = drop_list[1]
--        --if item1.itemid ~= 71000001 then
--        --    shaco.trace(i)
--        --    tbl.print(drop_list, "drop_list:", shaco.trace)
--        --    error(false)
--        --end
--        assert(item1.itemid>0)--)--==71000001)
--        assert(item1.cnt>0)--==15)
--        assert(item1.drop_type==1)
--    end
--    shaco.trace("drop ok")
--end

local function delete_oldly(ur,id)
	local tasks = ur.task.tasks
	local taskv = {}
	if not tasks then
		return false
	end
    local i = 1
    while tasks[i] do
        if tasks[i].previd == id then
            tasks[i].previd = 0
        end
        if tasks[i].taskid == id then
            table.remove(tasks,i)
        else
            i = i + 1
        end

    end
	ur:db_tagdirty(ur.DB_TASK)
	ur:send(IDUM_TASKREWARD, {taskid = id,info = tasks})
	--ur:send(IDUM_TASKLIST, {info = taskv})
	return true
end

local tpitem = require "__tpitem"
local function reward_gen()
    return {
        itemid = 0,
		itemcnt = 0,
		hole_cnt = 0,
		wash_cnt = 0,
    }
end

function GM.taskreward(ur, args)
	if  ur.gm_level < 2 then
		return
	end
	if #args < 2 then
		return
	end
	local taskid = tonumber(args[2])
	local update = 0
    local tasks = {}
    local rewardlist = {}
    local reward_list = {}
    local tp = tptask[taskid]
	if not tp then
		shaco.warn("the ask not exsit") 
		return 
	end
	local rewardarray = tp.submitItems
	for j = 1,#rewardarray do
		local templist = reward_gen()
		local id = 0
		id = tonumber(rewardarray[j][1])
    	local num = 0
    	num = tonumber(rewardarray[j][2])
    	templist.itemid = id
    	templist.itemcnt = num
		templist.hole_cnt = tonumber(rewardarray[j][3])
		templist.wash_cnt = tonumber(rewardarray[j][4])
    	reward_list[#reward_list + 1] = templist
    	rewardlist[#rewardlist + 1] = {id,num}
	end
	if itemop.can_gain(ur, rewardlist) then
		for i = 1, #reward_list do
			local item = reward_list[i]
			local item_tp = tpitem[item.itemid]
			if item_tp then
				--print("item_tp.itemType ==== "..item_tp.itemType)
				if  item_tp.itemType == ITEM_BAG then
					--print(" item.itemid === "..item.itemid.."  item.itemcnt == "..item.itemcnt)
					--tbl.print(item_tp.items,"------- item_tp.items ==== ")
					gift_reward.get_gift_reward(ur,item_tp.items,item.itemcnt,0,item.hole_cnt,item.wash_cnt)
					--gift_reward.open_gift_item(ur,item.itemid,item.itemcnt,item.hole_cnt,item.wash_cnt)
				else
					itemop.gain(ur, item.itemid, item.itemcnt,item.hole_cnt,item.wash_cnt)
				end
			end
		end
	end
	local cardreward = tp.submitCards
	local cards = ur.cards
	for j = 1,#cardreward do
		local templist = reward_gen()
		local id = 0
		id = tonumber(cardreward[j][1])
    	local num = 0
    	num = tonumber(cardreward[j][2])
		if not card_container.enough(ur,num) then
			break
		end
		cards:put(ur,id,num)
	end
	if tp.submitPhysical > 0 then
		ur.info.physical = ur.info.physical + tp.submitPhysical
	end
	local submitArms = tp.submitArms
	for i = 1,#submitArms do
		local reward_weapon = submitArms[i]
		local cardid = reward_weapon[1]
		local weapon_id = reward_weapon[2]
		local hole_cnt = reward_weapon[3]
		card_container.add_equip(ur,cardid,weapon_id,hole_cnt)
	end
	--ur.cards.__card.__cards
	card_container.refresh(ur)
    ur:db_tagdirty(ur.DB_CARD)
	ur:addexp(tptask[taskid].submitExp)
	ur:gold_got(tptask[taskid].submitDiamond)
	ur:coin_got(tptask[taskid].submitGold)
	ur:sync_role_data()
	itemop.refresh(ur)
	if delete_oldly(ur,taskid) then
    	--ur:send(IDUM_TASKREWARD, {taskid = taskid})
    end
    ur:db_tagdirty(ur.DB_ITEM)
end

return GM
