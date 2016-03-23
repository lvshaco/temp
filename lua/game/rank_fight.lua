local shaco = require "shaco"
local pb = require "protobuf"
local tbl = require "tbl"

local rank_fight = {}

local _rank = {}
local _role2rank = {}
local role2rank = {}
local need_list = {}

local function gen_rankrole(roleid, fight,name)
    return {roleid=roleid, fight=fight,name = name}
end

local function gen_rankindo(rank, fight,name,roleid)
    return {rank=rank, fight=fight,name = name,roleid = roleid,flag = 0}
end

 local function cmp(v1, v2)
    if v1.fight ~= v2.fight then
        return v1.fight > v2.fight
    else
        return v1.roleid <  v2.roleid
    end
end

function rank_fight.load(result)
    --shaco.debug("rank_fight:", #result)
    for k,v in ipairs(result) do
        --shaco.debug(v.roleid, v.info)
        local roleid = tonumber(v.roleid)
        local fight
        if v.info then
            local rinfo = pb.decode("role_info", v.info)
            fight = rinfo.battle_value
        else
            fight = 0
        end
		local name
		if v.base then
			local rbase = pb.decode("role_base", v.base)
			name = rbase.name
		else
			name = ""
		end
        table.insert(_rank, gen_rankrole(roleid, fight,name))
    end
   
    table.sort(_rank, cmp)
    for k, v in ipairs(_rank) do
        _role2rank[v.roleid] = k
		local rank_info = gen_rankindo(k,v.fight,v.name,v.roleid)
		role2rank[#role2rank + 1] = rank_info
		if k <= 50 then
			need_list[#need_list + 1] = rank_info
		end
    end
	--tbl.print(role2rank,"role2rank ----------========== ")
    --tbl.print(_rank, "role", shaco.debug)
    --tbl.print(role2rank, "role", shaco.debug)

    --local ur = {
    --    base = {roleid=10},
    --    info = {battle_value=2000}
    --}
    --rank_fight.change_fight(ur)

    --tbl.print(_rank, "role", shaco.debug)
    --tbl.print(_role2rank, "role", shaco.debug)
end

function rank_fight.get_need_rank_list()
	return need_list
end

function rank_fight.get_rank_list()
	return role2rank
end

function rank_fight.get_own_rank_info(roleid)
	for i = 1,#role2rank do
		local rank = role2rank[i]
		if rank.roleid == roleid then
			return rank
		end
	end
end

function rank_fight.get_rolerank(roleid)
    return _role2rank[roleid]
end

function rank_fight.get_rankinfo(rank)
    return _rank[rank]
end

function rank_fight.get_lastrank()
    return #_rank
end

function rank_fight.get_all_rank()
    return _rank
end

local function check_battle_value(fight)
	for i = 1,#need_list do
		local info = need_list[i]
		if info.fight < fight then
			return true
		end
	end
	return false
end

function rank_fight.change_fight(ur)
	local original_rank = 0
	local cur_rank = 0
	local my_name = ur.base.name 
    local my_roleid = ur.base.roleid
    local my_fight = ur.info.battle_value
    local my_info = rank_fight.get_own_rank_info(my_roleid)--_role2rank[my_roleid]
    local my_rank = 0
    if not my_info then
        my_rank = #_rank + 1
        table.insert(_rank, gen_rankrole(my_roleid, my_fight,my_name))
        _role2rank[my_roleid] = my_rank
        --my_info = _rank[my_rank]
		my_info = gen_rankindo(my_rank,my_fight,my_name,my_roleid)
		role2rank[#role2rank + 1] = my_info
		if my_rank <= 50 then
			need_list[#need_list + 1] = my_info
		end
    else
		--tbl.print(my_info,"my_info  ==11111== ")
       -- my_info = _rank[my_rank]
        my_info.fight = my_fight
    end
	original_rank = my_info.rank
	local function cmp(v1, v2)
        if v1.fight ~= v2.fight then
            return v1.fight > v2.fight
        else
            return v1.roleid <  v2.roleid
        end
    end
    table.sort(role2rank, cmp)
	my_info = rank_fight.get_own_rank_info(my_roleid)
	--tbl.print(my_info,"my_info  ==== ")
	if original_rank ~= my_info.rank then
		local flag = false
		if my_info.rank > 50 and check_battle_value(my_fight) then
			need_list = {}
			for k, v in ipairs(role2rank) do
				if k <= 50 then
					need_list[#need_list + 1] = v
				end
			end
			flag = true
		elseif my_info.rank <= 50 then
			flag = true
		end
		if flag then
			ur:send(IDUM_ACKBATTLERANK, {ranks ={},own_rank = my_info})
		else
			ur:send(IDUM_ACKBATTLERANK, {ranks = need_list,own_rank = my_info})
		end
	end
end

function rank_fight.sync_update_rank_info()
	table.sort(_rank, cmp)
	_role2rank = {}
	role2rank = {}
	need_list = {}
    for k, v in ipairs(_rank) do
        _role2rank[v.roleid] = k
		local rank_info = gen_rankindo(k,v.fight,v.name,v.roleid)
		role2rank[#role2rank + 1] = rank_info
		if k <= 50 then
			need_list[#need_list + 1] = rank_info
		end
    end
end

return rank_fight
