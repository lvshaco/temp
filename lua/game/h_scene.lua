local shaco = require "shaco"
local scene = require "scene"
local tpscene = require "__tpscene"
local itemdrop = require "itemdrop"
local tpgamedata = require "__tpgamedata"
local tpmonster = require "__tpmonster"
local task = require "task"
local tbl = require "tbl"
local sfmt = string.format
local floor = math.floor
local ectype_fast = require "ectype_fast"
local REQ = {}

local function is_copy(tp)
	if tp.type == SCENE_COPY or tp.type == SCENE_BOSS then
		return true
	end
	return false
end


local function verify_battle(ur,cheat,ectypeid)
	local tp = tpmonster[cheat]
	if not tp then
		return
	end
	local oppent_value = tp.hp/ math.max(tp.phyAtk + tp.magAtk - tp.phyDef - tp.magDef,1)
	local verify_value = ur:get_max_atrribute()
	if verify_value*1.5/oppent_value >= 1 then
		ur.battle_verify = true
	else
		ur.battle_verify = false
	end
end

REQ[IDUM_SCENEENTER] = function(ur, v)
    local mapid = v.mapid
	local tp = tpscene[mapid]
	if not tp then
		return
	end
	if not ur.info.physical or ur.info.physical < tp.physicalNeed then
		return SERR_PYSICAL_NOT_ENOUGH
	end
    local ok = scene.enter(ur, mapid)
    if ok then
        ur.info.map_entertime = shaco.now()//1000;
		local randomcnt = 0
        if is_copy(tp) then
			local drop_list = itemdrop.random_ectype_drop(mapid,0)
			ur.info.drops = drop_list 
			
			ur:send(IDUM_ITEMDROPLIST, {list = ur.info.drops,coin = tp.gold_drop})
			itemdrop.compute_copy_result(ur,mapid)
			if tp.physicalNeed > 0 then
				ur.info.physical = ur.info.physical - 1
			end
			if tpgamedata.PhysicalMax > ur.info.physical then
				ur.info.physical_time = shaco.now()//1000
			end
			ur:sync_role_data()
			verify_battle(ur,tp.cheat,mapid)
			ur:db_tagdirty(ur.DB_ROLE)
		end
    end
    ur:db_tagdirty(ur.DB_ROLE_DELAY)
end

REQ[IDUM_MOVEREQ] = function(ur, v)
    scene.move(ur, v)
end

REQ[IDUM_MOVESTOP] = function(ur, v)
    scene.movestop(ur, v)
end

REQ[IDUM_REQECTYPERECORD] = function (ur, v)
    local recordv = ectype_fast.query(v.mapid)
    shaco.debug('req', v.mapid, tostring(recordv))
    if recordv then
        ur:send(IDUM_ACKECTYPERECORD, {record = recordv})
    end
end

return REQ
