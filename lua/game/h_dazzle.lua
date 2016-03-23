--local shaco = require "shaco"
local shaco = require "shaco"
local pb = require "protobuf"
local tbl = require "tbl"
local sfmt = string.format
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local tpdazzle_fragment = require "__tpdazzle_fragment"
local tpdazzle = require "__tpdazzle"
local dazzles = require "dazzle"
local itemop = require "itemop"
local task = require "task"
local broad_cast = require "broad_cast"
local REQ = {}

local function get_fragment_base(pos,type,level)
	for k,v in pairs(tpdazzle_fragment) do
		if v.type == type and v.Level == level and v.position == pos then
			return v
		end
	end
end

local function get_fragment_indx(dazzle,v)
	for i = 1,#dazzle.fragment do
		local fragment = dazzle.fragment[i] 
		if fragment.fragment_type == v.fragment_type and fragment.fragment_level == v.fragment_level and fragment.fragment_pos == v.fragment_pos then
			return i
		end
	end
	return 0
end

local function fragment_material_gen(tp,num)
	return {
		fragment_type = tp.type,
		fragment_pos = tp.position,
		fragment_level = tp.Level,
		fragment_id = tp.Id,
		fragment_exp = tp.experience,
		fragment_num = num,
	}
end

local function get_fragment_matertial(ur,dazzle,v)
	local take = 0
	local index = get_fragment_indx(dazzle,v)
	local fragment = dazzle.fragment[index]
	local bag = ur:getbag(BAG_MAT)
	--local level = fragment.fragment_level
	local material_list = {}
	for i = 1,#v.material do
		local posv = v.material[i]
		local num = posv.num
		local item = itemop.get(bag, posv.pos)
		if not item  then
			return
		end
		if item.stack < posv.num then
			num = item.stack
		end
		local tp_fragment = tpdazzle_fragment[item.tpltid]
		if tp_fragment then
			--if tp_fragment.type == fragment.fragment_type and tp_fragment.position == fragment.fragment_pos then
			--	if level < tp_fragment.Level then
			--		level = tp_fragment.Level
				--end
			--end
	--	end
			local fragment_info = fragment_material_gen(tp_fragment,num)
			take = take + tp_fragment.Gold * num
			material_list[#material_list + 1] = fragment_info
			itemop.remove_bypos(bag, posv.pos, num)
		end
	end
	return material_list,index,take
end

local function add_fragment_exp(ur,fragment)
	local tp = get_fragment_base(fragment.fragment_pos,fragment.fragment_type,fragment.fragment_level)
	if not tp then
		return 
	end
	if tp.Next_dazzle <= fragment.exp then
		local temp_tp = get_fragment_base(fragment.fragment_pos,fragment.fragment_type,(fragment.fragment_level + 1))
		if not temp_tp then
			return 
		end
		fragment.fragment_level = fragment.fragment_level + 1
		fragment.exp = fragment.exp - tp.Next_dazzle
		fragment = add_fragment_exp(ur,fragment)
	end
	return fragment
end

local function get_fragment_min_level(dazzle)
	local level = dazzle.fragment[1].fragment_level 
	for i = 1,#dazzle.fragment do
		local fragment = dazzle.fragment[i] 
		if fragment.fragment_level < level then
			level = fragment.fragment_level
		end
	end
	return level
end
	
REQ[IDUM_COMPOSEFRAGMENT] = function(ur, v)
	local dazzle = dazzles.get_dazzle(ur,v.dazzle_type,v.dazzle_level)
	if not dazzle then
		return SERR_DAZZLE_NOT_EXSIT
	end
	local material_list,index,take = get_fragment_matertial(ur,dazzle,v)
	if not material_list then
		return SERR_MATERIAL_NOT_EXISIT
	end
	local fragment = dazzle.fragment[index]
	if not fragment then
		tbl.print(dazzle,"-------- dazzle error ====roleid ==  "..ur.base.roleid.." ---index == "..index)
		return
	end
	
	local tp = get_fragment_base(fragment.fragment_pos,fragment.fragment_type,fragment.fragment_level)
	if not tp then
		return 
	end
	if not ur:coin_take(take) then
		return SERR_COIN_NOT_ENOUGH
	end
	local add_exp = 0
	for i = 1,#material_list do
		local material = material_list[i]
		add_exp = add_exp + material.fragment_exp * material.fragment_num
	end
	fragment.exp = fragment.exp + add_exp
	fragment = add_fragment_exp(ur,fragment)
	itemop.refresh(ur)
	ur:sync_role_data()
	local min_lvl = get_fragment_min_level(dazzle)
	dazzle.dazzle_level = min_lvl
	local tp_front = get_fragment_base(v.fragment_pos,v.fragment_type,v.fragment_level)
	if tp_front then
		ur.attribute:remove_dazzle_fragment(ur,tp_front)
		ur.attribute:add_dazzle_fragment(ur,tp)
	end
	ur:change_attribute()
	ur:db_tagdirty(ur.DB_ROLE)
	ur:db_tagdirty(ur.DB_ITEM)
	task.change_task_progress(ur,62,1,1)
	task.refresh_toclient(ur, 62)
	ur:send(IDUM_HANDLEDAZZLERESULT, {success_type = FRAGEMENT_COMPOSE,info = dazzle})
	if min_lvl >= 10 then
		local original_id,cur_id = dazzles.get_front_cur_dazzle(ur,dazzle.dazzle_type,dazzle.dazzle_level)
		local common = {original_id = original_id,cur_id= cur_id}
		broad_cast.set_borad_cast(ur,common,NOTICE_DAZZLE_T)
		--broad_cast.check_dazzle_up(ur,original_id,cur_id)
	end
end

local function check_dazzle_used(ur)
	local dazzles = ur.info.dazzles
	for i =1,#dazzles do
		local dazzle = dazzles[i]
		if dazzle.dazzle_have == 1 then
			return true
		end
	end
	return false
end

REQ[IDUM_USEDAZZLE] = function(ur, v)
	local dazzle = dazzles.get_dazzle(ur,v.dazzle_type,v.dazzle_level)
	if dazzle.dazzle_level < 1 then
		return SERR_DAZZLE_LEVEL_NOT_ENOUGH
	end
	dazzles.clear_use(ur)
	if v.dazzle_state == 1 then
		dazzle.dazzle_use = 1
	else
		dazzle.dazzle_use = 0
	end
	ur:send(IDUM_HANDLEDAZZLERESULT, {success_type = USE_DAZZLE,info = dazzle})
	ur:db_tagdirty(ur.DB_ROLE)
end

REQ[IDUM_REQDAZZLEFRAGMENTCHANGE] = function(ur, v)
	local dazzle = dazzles.get_dazzle(ur,v.dazzle_type,v.dazzle_level)
	local index = get_fragment_indx(dazzle,v)
	local fragment = dazzle.fragment[index]
	local bag = ur:getbag(BAG_MAT)
	local level = fragment.fragment_level
	local item = itemop.get(bag, v.pos)
	if not item then
		return
	end
	local tp_fragment = tpdazzle_fragment[item.tpltid]
	if tp_fragment then
		if tp_fragment.type == fragment.fragment_type and tp_fragment.position == fragment.fragment_pos then
			if level < tp_fragment.Level then
				level = tp_fragment.Level
			end
		end
	end
	fragment.fragment_level = level
	local tp = get_fragment_base(fragment.fragment_pos,fragment.fragment_type,fragment.fragment_level)
	if not tp then
		return 
	end
	itemop.remove_bypos(bag, v.pos, 1)
	local tp_front = get_fragment_base(v.fragment_pos,v.fragment_type,v.fragment_level)
	if tp_front then
		ur.attribute:remove_dazzle_fragment(ur,tp_front)
		ur.attribute:add_dazzle_fragment(ur,tp)
		itemop.gain(ur,tp_front.Id,1)
	end
	ur:change_attribute()
	itemop.refresh(ur)
	local min_lvl = get_fragment_min_level(dazzle)
	dazzle.dazzle_level = min_lvl
	ur:db_tagdirty(ur.DB_ROLE)
	ur:db_tagdirty(ur.DB_ITEM)
	ur:send(IDUM_HANDLEDAZZLERESULT, {success_type = FRAGEMENT_EXCHANGE,info = dazzle})
end

return REQ

