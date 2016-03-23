package.cpath = package.cpath .. ";../../bin/?.so"

local bytes = require "bytes.c"
local socket = require "socket.c"

local buffer = socket.newbuffer()

local function push(s)
    socket.push(buffer, bytes.str2bytes(s))
end

local function pop(mode)
    if mode == "*1" or mode == "*2" or mode == "*4" then
        local h, err = socket.pop(buffer, mode)
        if h then
            local s, err = socket.pop(buffer, h)
            return s
        end
    else
        local s, err = socket.pop(buffer, mode)
        return s
    end
end

push("1234567890\n1\n2\n3\n4\n5\n")
assert(pop("\n") == "1234567890")
assert(pop("\n") == "1")
assert(pop("\n") == "2")
assert(pop("\n") == "3")
assert(pop("\n") == "4")
assert(pop("\n") == "5")
assert(pop("\n") == nil)

push("1234567890\n\n2\n3\n4\n5\n")
assert(pop("\n") == "1234567890")
assert(pop("\n") == "")
assert(pop("\n") == "2")
assert(pop("\n") == "3")
assert(pop("\n") == "4")
assert(pop("\n") == "5")
assert(pop("\n") == nil)

push("1234567890\n1\n2\n3\n4\n5\n6")
assert(pop("\n") == "1234567890")
assert(pop("\n") == "1")
assert(pop("\n") == "2")
assert(pop("\n") == "3")
assert(pop("\n") == "4")
assert(pop("\n") == "5")
assert(pop("\n") == nil)


push("1234567890end_line1end_line2end_line3end_line4end_line5end_line")
assert(pop("end_line") == "61234567890")
assert(pop("end_line") == "1")
assert(pop("end_line") == "2")
assert(pop("end_line") == "3")
assert(pop("end_line") == "4")
assert(pop("end_line") == "5")
assert(pop("end_line") == nil)

push("1234567890end_lineend_line2end_line3end_line4end_line5end_line")
assert(pop("end_line") == "1234567890")
assert(pop("end_line") == "")
assert(pop("end_line") == "2")
assert(pop("end_line") == "3")
assert(pop("end_line") == "4")
assert(pop("end_line") == "5")
assert(pop("end_line") == nil)

push("1234567890end_line1end_line2end_line3end_line4end_line5end_line")
assert(pop("end_line") == "1234567890")
assert(pop("end_line") == "1")
assert(pop("end_line") == "2")
assert(pop("end_line") == "3")
assert(pop("end_line") == "4")
assert(pop("end_line") == "5")
assert(pop("end_line") == nil)

local function M(s)
    return string.char(bit32.extract(#s,0,8),bit32.extract(#s,8,8)) .. s
end

push(M("1234567890"))
push(M("1"))
push(M("2"))
push(M("3"))
push(M("4"))

assert(pop("*2") == "1234567890")
assert(pop("*2") == "1")
assert(pop("*2") == "2")
assert(pop("*2") == "3")
assert(pop("*2") == "4")

local s = M("1234567890")
for i=1, #s do
    push(string.sub(s,i,i))
end
assert(pop("*2") == "1234567890")
assert(pop("*2") == nil)

push("")
