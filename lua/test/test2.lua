--package.path = package.path .. ";./?.lua"
--package.cpath = package.cpath .. ";./?.dll"

local lpeg = require "lpeg"
--require "luasocket"

function err_func()
	print("----err function react")
end 

function main()
	print("-----hello my first lua test")
	
	-- matches a word followed by end-of-string
	p = lpeg.R"az"^1 * -1

	print(p:match("hello"))        --> 6
	print(lpeg.match(p, "hello"))  --> 6
	print(p:match("1 hello"))      --> nil

end 

local ret = xpcall(main, err_func)
if ret==false then
	print("----ret:1")
end
local a = {"hello","ll"}
local f = string.find
local b,c = f(a[1],a[2])
--unpack(a))
print(b.." --- "..c)
function newcounter()
    local i = 0
    return function ()
        print("i === "..i)
        i = i + 1
        return i
    end
end
local c1 = newcounter()
print("c1 ==== "..c1())
print("c1 ====="..c1())
c2 = newcounter()
print("c2 == "..c2())
print("c1 == "..c1())
print("c2 == "..c2())

function newtest()
    local i = 0
    i = i + 1
    print("i ===== --== "..i)
    return i
end

c3 = newtest()
print("c3 == "..c3)
print("c3 ==== "..c3)
print("c3 ==== "..c3)

co = coroutine.create(function() print("hello coroutine") end)
print(co)
print(coroutine.status(co))
coroutine.resume(co)
print(coroutine.status(co))
print(coroutine.status(co))
print(coroutine.status(co))

function permgen(a,n)
    if n == 0 then
        coroutine.yield(a)
    else
        for i = 1,n do
            a[n],a[i] = a[i],a[n]
            permgen(a,n -1)
            a[n],a[i] = a[i],a[n]
        end
    end
end
function perm(a)
    local n = #a
   --[[ local co = coroutine.create(function() permgen(a,n) end )
    return function()
        local code,res = coroutine.resume(co)
        return res
    end]]
    return coroutine.wrap(function() permgen(a,n) end)
end
function printResult(a)
    for i,v in ipairs(a) do
        io.write(v," ")
    end
    io.write("\n")
end

for p in perm{"a","b","c"} do
    printResult(p)
end
--host = "www.w3.org"
--file = "/TR/REC-html32..html"
--c = assert(socket.connet(host,80))
--c:send("GET"..file.."HTTP/1.0\r\n\r\n")
--c:close()

--local f = io.open("lua_test.txt","r") 
--buff = f:read("*all")

--print("hello world"..buff)
--buff = buff.."addwd"
--print(buff)
--f:write(buff)
--f:close()
buff = ""
for line in io.lines("lua_test.txt") do
    buff = buff..line.."\n"
    print("buff ===  "..buff)
    if line == "m" then
        break
    end
end
--print("buff == "..buff)
--
--
math.randomseed(os.time())
local p = {}
for i = 1,10 do
    p[i] = math.random(100)
end
table.insert(p,1,100)
for k,v in ipairs(p) do
    print("v ===== "..v)
end
local a = {}
a[1] = 12
a[2] = 1
a[3] = 3
a[10] = 5
a[11] = 6
a[20] = 11
local date = "17/12/1002"
_,_,d,m,y = string.find(date,"(%d+)/(%d+)/(%d+)")
print(d,m,y)

