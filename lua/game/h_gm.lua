local GM = require "gm"
local string = string
local table = table
local shaco = require "shaco"
local sfmt = string.format
local REQ = {}

REQ[IDUM_GM] = function(ur, v)
	if ur.gm_level < 1 then
		return
	end
    local args = {}
    for v in string.gmatch(v.command, "[%w_]+") do
        table.insert(args, v)
    end
    if #args >= 1 then
        local f = GM[args[1]]
        if f then
            f(ur, args)
        end
    end
end

return REQ
