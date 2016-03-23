local shaco = require "shaco"
local rcall = shaco.callum

local find = string.find
local sub = string.sub
local len = string.len
local sfmt = string.format
local tbl = require "tbl"


local code = {}

local function Split(szFullString, szSeparator)
	local nFindStartIndex = 1
	local nSplitIndex = 1
	local nSplitArray = {}
	while true do
		local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
		if not nFindLastIndex then
			nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
			break
		end
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
		nFindStartIndex = nFindLastIndex + string.len(szSeparator)
		nSplitIndex = nSplitIndex + 1
	end
	return nSplitArray
end

function code.scode()
	local f = io.open(".code.tmp", "a+")
	local string_list = f:read("*a")
	if string_list == "" then
	
	else
		local result = Split(string_list,";")
		--tbl.print(result, "=============init self. result", shaco.trace)
		local batchid = tonumber(result[1])
		local code_type = tonumber(result[2])
		local gift_treasure = result[3]
		local use_level = tonumber(result[4])
		local effective_time = result[5]
	--daily_time = tonumber(result[1])
	--local record = Split(result[2],";")
		for i =1,#result do
			if result[i] ~= "" and i > 5 then
				local fields = {}
				fields.batchid = batchid
				fields.code_type = code_type
				fields.gift_treasure = gift_treasure
				fields.use_level = use_level
				fields.effective_time = effective_time
				fields.code = result[i]
				shaco.sendum(CTX.db, "S.code",{name = "exchange_code",fields = fields})
			end
		end
	end
	f:close()
end


return code
