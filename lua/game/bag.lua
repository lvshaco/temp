local shaco = require "shaco"
local warn = shaco.warn
local ipairs = ipairs
local pairs = pairs
local tpitem = require "__tpitem"
local tbl = require "tbl"
local sfmt = string.format
local mfloor = math.floor
local mrandom = math.random
local tpgamedata = require "__tpgamedata"

local initfunc

local function item_gen()
    return {
        tpltid = 0,
        pos = 0,
        stack = 0,
    }
end

local function item_init(item, tp, tpltid, pos, stack,hole_cnt,wash_cnt)
    item.tpltid = tpltid 
    item.pos = pos
    item.stack = stack
    if initfunc then
		if tp.itemType == ITEM_EQUIP then
			initfunc(item, tp,hole_cnt,wash_cnt)
		else
			initfunc(item, tp)
		end
    end
end

local UP_LOAD = 0
local UP_UP  = 1
local UP_ADD = 2

local function max_stack(tp)
    return tp.overLap >= 1 and tp.overLap or 65535
end

local function tag_up(self, i, flag)
    self.__flags[i] = flag
end

local bag = {}

function bag.sethandler(inititemfunc)
    initfunc = inititemfunc
end

local function hole_position_gen(i)
	return {
		state = 0,
		gemid = 0,
		indx = 0,
	}
end

local function  additional_attribute_gen()
	return {
		attribute_type = 0,
		attribute_value = 0,
		attribute_indx = 0,
	}
end

local function additional_atrribute_gen(additional)
	return {
		attack = additional.attack or 0,
	    defense = additional.defense or 0,
	    magic = additional.magic or 0,
	    magicdef = additional.magicdef or 0,
	    hp = additional.hp or 0,
	    atk_crit = additional.atk_crit or 0,
	    mag_crit = additional.mag_crit or 0,
	    atk_res = additional.atk_res or 0,
	    mag_res = additional.mag_res or 0,
	    block = additional.block or 0,
	    dodge = additional.dodge or 0,
	    mp_reply = additional.mp_reply or 0,
	    block_value = additional.block_value or 0,
	    hits = additional.hits or 0,
	    hp_reply = additional.hp_reply or 0,
	}
end

function bag.new(type, size, itemv, initfunc)
    if size <= 0 then
        size = 1
    end
    local items = {}
    local flags = {}
    local pos
    for k, v in ipairs(itemv) do
        pos = v.pos
        if v.tpltid == 0 then
            warn("itemid tpltid zero")
        elseif pos <= 0 or pos > size then
            warn("item pos invalid")
        else
            local item = items[pos] 
            if item then
                warn("item pos repeat")
            else
                items[pos] = v
                flags[pos] = UP_LOAD
				local tp = tpitem[v.tpltid]
				--items[pos].info.hole = {}
				if tp and tp.itemType == ITEM_EQUIP then
					local indx = 0
					for i = 1,#v.info.hole do
						local __hole = v.info.hole[i]
						local hole_info = hole_position_gen()
						hole_info.state = __hole.state
						hole_info.gemid = __hole.gemid
						hole_info.indx = __hole.indx
						items[pos].info.hole[i] = hole_info
						indx = indx + 1
					end
					if indx == 0 and tp.equipPart == EQUIP_WEAPON then
						items[pos].info.hole = {}
						for i = 1,4 do
							local hole_info = hole_position_gen()
							hole_info.indx = i
							items[pos].info.hole[i] = hole_info
						end
					end
					local additional_flag = 0
					for i = 1,#v.info.addition do
						local __addition = v.info.addition[i]
						local addition_info = additional_attribute_gen()
						addition_info.attribute_type = __addition.attribute_type
						addition_info.attribute_value = __addition.attribute_value
						addition_info.attribute_indx = __addition.attribute_indx
						items[pos].info.addition[i] = addition_info
						additional_flag = additional_flag + 1
					end
					if additional_flag == 0 and tp.equipPart ~= EQUIP_WEAPON and tp.level >= tpgamedata.Required_Level then
						items[pos].info.addition = {}
					end
				end
            end
        end
    end
    for i=1, size do
        if not items[i] then
            items[i] = item_gen()
        end
    end 
    local self = {
        __type  = type,
        __items = items,
        __flags = flags
    }
    setmetatable(self, bag)
    bag.__index = bag
	
    return self
end

function bag:put(id, num,hole_cnt,wash_cnt)
    if id <= 0 or num <= 0 then
        return 0
    end
    local tp = tpitem[id]
    if not tp then
        return 0
    end
    local max = max_stack(tp)
    local remain = num
    local items = self.__items
	local posv = {}
    -- 优先堆叠
    for i=1, #items do
        local item = items[i]
        if item.tpltid == id then
            if item.stack < max then
                local diff = max - item.stack
                tag_up(self, i, UP_UP)
                if remain > diff then
                    item.stack = max
                    remain = remain-diff
                else
                    item.stack = item.stack+remain
                    remain = 0
                    break
                end
            end
        end
    end
    -- 然后空格
    if remain > 0 then
        for i=1, #items do
            local item = items[i]
            if item.tpltid == 0 then
                tag_up(self, i, UP_ADD)
                if remain > max then
					if tp.itemType == ITEM_EQUIP then
						posv[#posv + 1] = i
						item_init(items[i], tp, id, i, max,hole_cnt,wash_cnt)
					else
						item_init(items[i], tp, id, i, max)
					end
                    remain = remain-max 
                else
					if tp.itemType == ITEM_EQUIP then
						posv[#posv + 1] = i
						item_init(items[i], tp, id, i, remain,hole_cnt,wash_cnt)
					else
						item_init(items[i], tp, id, i, remain)
					end
                    remain = 0
                    break
                end
            end
        end
    end
    return num-remain,posv
end

function bag:put_bypos(id, num, pos,hole_cnt,wash_cnt)
    if id <= 0 or num <= 0 or
       pos < 1 or pos > #self.__items then
       return 0
    end
   local tp = tpitem[id]
    if not tp then
        return 0
    end
    local max = max_stack(tp)
    local item = self.__items[pos]
    if item.tpltid == 0 then
        tag_up(self, pos, UP_ADD)
        if max >= num then
			if tp.itemType == ITEM_EQUIP then
				item_init(item, tp, id, pos, num,hole_cnt,wash_cnt)
			else
				item_init(item, tp, id, pos, num)
			end
            return num
        else
            item_init(item, tp, id, pos, max)
            return max
        end
    else
        local remain = max-item.stack
        tag_up(self, pos, UP_UP) 
        if remain >= num then
            item.stack = item.stack+num
            return num
        else
            item.stack = max
            return remain
        end
    end
end

function bag:remove(id, num)
    if id <= 0 or num <= 0 then
        return 0
    end
    local remain = num 
    for i, item in ipairs(self.__items) do
        if item.tpltid == id then
            tag_up(self, i, UP_UP)
            if remain > item.stack then
                remain = remain - item.stack
                item.tpltid = 0
                item.stack = 0
            elseif remain == item.stack then
                remain = 0
                item.tpltid = 0
                item.stack = 0 
                break
            else
                item.stack = item.stack - remain
                remain = 0
                break
            end
        end
    end
    return num - remain
end

function bag:remove_bypos(pos, num)
    if num < 0 or pos < 1 or pos > #self.__items then
        return 0
    end
    local item = self.__items[pos]
    if num == 0 then
        num = item.stack
    end
    local old  = item.stack
    tag_up(self, pos, UP_UP)
    if old > num then
        item.stack = old-num
        return num
    else
        item.tpltid = 0
        item.stack = 0
		item.info = nil
        return old
    end
end

function bag:space()
    local n = 0 
    for _, item in ipairs(self.__items) do
        if item.tpltid == 0 then
            n = n + 1
        end
    end
    return n
end

-- dinums: { {id,num},{id,num}, ... }
function bag:space_enough(idnums)
    -- 归类
    local fix = {}
    local n = 0
    for i, one in ipairs(idnums) do
        local id = one[1]
        if id > 0 then
            local num = one[2]
            local old = fix[id]
            if old then
                old[1] = old[1] + num
            else
                local tp = tpitem[id]
                if tp then
                    fix[id] = { num, max_stack(tp)}
                    n = n+1
                end
            end
        end
    end
    if n == 0 then
        return false
    end
    local need = 0
    -- 扣除可堆叠数量
    local items = self.__items
    for id, v in pairs(fix) do
        local stack, max_stack = table.unpack(v)
        for _, item in ipairs(items) do
            if item.tpltid == id then
                if item.stack < max_stack then
                    local can_stack = max_stack - item.stack
                    if stack > can_stack then
                        stack = stack-can_stack
                    else
                        stack = 0
                        break
                    end
                end
            end
        end
        if stack > 0 then
            need = mfloor(need + (stack+max_stack-1)/max_stack)
        end
    end
    -- 剩余判断空格
    local space = self:space()
	--print("space == ",space)
    if space >= need then
        return true
    end
end

function bag:count(id)
    if id <= 0 then
        return 0
    end
    local n = 0
    for _, item in ipairs(self.__items) do
        if item.tpltid == id then
            n = n + item.stack
        end
    end
    return n
end

function bag:enough(id, num)
    if id <= 0 or num <=0 then
        return false
    end
    local n = 0
    for _, item in ipairs(self.__items) do
        if item.tpltid == id then
            n = n + item.stack
            if n >= num then
                return true
            end
        end
    end
	
    return false
end

function bag:get(pos)
    if pos >=1 and pos <= #self.__items then
        local item = self.__items[pos]
		
        if item.tpltid > 0 then
            return item
        end
    end 
end

function bag:clr(pos)
    if pos >= 1 and pos <= #self.__items then
        local item = self.__items[pos]
        if item.tpltid ~= 0 then
            local pos = item.pos
            item = item_gen()
            item.pos = pos
            self.__items[pos] = item
            tag_up(self, pos, UP_UP)
            return true
        end
    end
end

function bag:set(pos, item)
    if pos >= 1 and pos <= #self.__items then
        local old = self.__items[pos]
        item.pos = pos
        self.__items[pos] = item
        tag_up(self, pos, UP_UP)
        return old
    end
end

function bag:update(pos)
    if pos >= 1 and pos <= #self.__items then
        tag_up(self, pos, UP_UP)
    end
end

function bag:find_slot()
    for i, item in ipairs(self.__items) do
        if item.tpltid == 0 then
            return i
        end
    end
end

function bag:refresh_up(cb, ...)
    local flags = self.__flags
    local items = self.__items
    for i, flag in pairs(flags) do
        if flag then
            local item = items[i]
            if item then
                cb(item, flag, ...)
            end
            flags[i] = nil
        end
    end
end

function bag:get_gem_list()
	local gem_list = {}
	 for _, item in ipairs(self.__items) do
		local tp = tpitem[item.tpltid]
		if tp then
			if tp.itemType == ITEM_GEM then
				gem_list[#gem_list + 1] = item
			end
		end
    end
	return gem_list
end

function bag:get_equip_list()
	local equip_list = {}
	 for _, item in ipairs(self.__items) do
		local tp = tpitem[item.tpltid]
		if tp then
			if tp.itemType == ITEM_EQUIP  then
				equip_list[#equip_list + 1] = item
			end
		end
    end
	return equip_list
end

return bag
