local util = {}

local _hour8s = 8*3600
local _hour8ms = _hour8s*1000

function util.second2day(sec)
    return (sec+_hour8s)//86400
end
function util.msecond2day(msec)
    return (msec+_hour8ms)//86400000
end
function util.daybase(sec)
    return util.second2day(sec)*86400-_hour8s
end

return util
