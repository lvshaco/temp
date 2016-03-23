local shaco = require "shaco"
local itemop = require "itemop"
local tpitem = require "__tpitem"
local tbl = require "tbl"
local tpgamedata = require "__tpgamedata"
local tpgift_treasure = require "__tpgift_treasure"
local card_container = require "card_container"
local club = require "club"
local sfmt = string.format
local code_fast = require "code_fast"
local REQ = {}

REQ[IDUM_USEEXCHANGECODE] = function(ur, v)
	--tbl.print(v,"v=============================  ")
    local result = code_fast.exchage_code(ur,v.code)
    if result == 1 then
		return SERR_CODE_USED
    elseif result == 2 then
		return SERR_CODE_TYPE_EXCHANGED
    elseif result == 3 then
		return SERR_CODE_LEVEL_ENOUGH
    elseif result == 4 then
		return SERR_CODE_OUT_OF_DATE
    elseif result == 5 then 
		return SERR_CODE_NOT_EXIST
	elseif result == 6 then 
		return SERR_ERROR_LABEL
   end
end

return REQ
