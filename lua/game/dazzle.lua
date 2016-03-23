--local shaco = require "shaco"
local shaco = require "shaco"
local pb = require "protobuf"
local tbl = require "tbl"
local sfmt = string.format
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local tpskill = require "__tpskill"
local tpdazzle = require "__tpdazzle"
local tpdazzle_fragment = require "__tpdazzle_fragment"
local dazzles = {}

local function dazzle_fragment_gen()
	return {
		fragment_type = 0,
		fragment_level = 0,
		fragment_pos = 0,
		exp = 0,
	}
end

local function dazzle_gen()
	return {
		dazzle_type = 0,
		dazzle_level=0,
		fragment = {},
		dazzle_use =0,
		dazzle_have=0,
	}
end

local function create_dazzle()
	local dazzle_list = {}
	for i =1,5 do
		for k, v in pairs(tpdazzle) do
			if v.Type == i and v.Level == 0 then
				local dazzle = dazzle_gen()
				dazzle.dazzle_type = v.Type
				dazzle.dazzle_level = v.Level
				for i = 1,6 do
					local info = dazzle_fragment_gen()
					local tp = tpdazzle_fragment[v["Need_dazzle"..i]]
					if tp then
						info.fragment_type = tp.type
						info.fragment_level = tp.Level
						info.fragment_pos = tp.position
						dazzle.fragment[#dazzle.fragment + 1] = info
					end
				end
				dazzle_list[#dazzle_list + 1] = dazzle
				break
			end
		end
	end
	return dazzle_list
end

function dazzles.new(dazzlev) 
    local dazzles = {}
    local idx = 1
    for k, v in ipairs(dazzlev) do
        if v.dazzle_type == 0 then
            shaco.warn("dazzle dazzle_type zero")
        else
            if dazzles[idx] then
                shaco.warn("dazzle_type repeat")
           	else
				local dazzle = dazzle_gen()
				dazzle.dazzle_type = v.dazzle_type
				dazzle.dazzle_level = v.dazzle_level
				dazzle.dazzle_use = v.dazzle_use or 0
				dazzle.dazzle_have = v.dazzle_have or 0
				--dazzle.fragment = v.fragment
				for i =1,#v.fragment do
					local data = v.fragment[i]
					local info = dazzle_fragment_gen()
					info.fragment_type = data.fragment_type or 0
					info.fragment_level = data.fragment_level or 0
					info.fragment_pos = data.fragment_pos or 0
					info.exp = data.exp or 0
					dazzle.fragment[#dazzle.fragment + 1] = info
				end
                dazzles[idx] = dazzle
            end	
        end
		idx = idx + 1
    end
	if #dazzles == 0 then
    	dazzles = create_dazzle()
    end
	return dazzles
end

function dazzles.get_dazzle(ur,dazzle_type,dazzle_level)
	local dazzles = ur.info.dazzles
	for i =1,#dazzles do
		local dazzle = dazzles[i]
		if dazzle.dazzle_type == dazzle_type and dazzle.dazzle_level == dazzle_level then
			return dazzle
		end
	end
end

function dazzles.get_next_dazzle(ur,dazzle_type,dazzle_level)
	for k, v in pairs(tpdazzle) do
		if v.Type == dazzle_type and v.Level == dazzle_level then
			return v
		end
	end
end 

function dazzles.clear_use(ur)
	local dazzles = ur.info.dazzles
	for i =1,#dazzles do
		local dazzle = dazzles[i]
		if dazzle.dazzle_use == 1  then
			dazzle.dazzle_use = 0
		end
	end
end

function dazzles.get_front_cur_dazzle(ur,dazzle_type,dazzle_level)
	local front_id = 0
	local cur_id = 0
	for k, v in pairs(tpdazzle) do
		if v.Type == dazzle_type and v.Level == dazzle_level then
			cur_id = v.Id
		elseif v.Type == dazzle_type and v.Level == (dazzle_level - 1) then
			front_id = v.Id
		end
	end
	return front_id,cur_id
end 

return dazzles
