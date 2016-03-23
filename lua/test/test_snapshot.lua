local snapshot = require "snapshot"

local s1 = snapshot()
local tmp = {}
local s2 = snapshot()

for k, v in pairs(s2) do
    if s1[k] == nil then
        print(k)
        print(v)
        --print(k, v)
    end
end
