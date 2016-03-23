local shaco = require "shaco"
local pb = require "protobuf"
local sfmt = string.format
local bit32 = require"bit32"

local bit={data32={}} 
for i=1,32 do
	bit.data32[i]=2^(32-i)
end

function bit:d2b(arg)
	local   tr={}
	for i=1,32 do
		if arg >= self.data32[i] then
			tr[i]=1
			arg=arg-self.data32[i]
		else
			tr[i]=0
		end
	end
	return   tr 
end

function bit:b2d(arg) 
	 local nr=0
	 for i=1,32 do
	 	if arg[i] ==1 then
	 		nr=nr+2^(32-i)
	 	end
	 end
	 return  nr
end

function bit:_and(a,b)
	--[[local op1=self:d2b(a)
	local op2=self:d2b(b)
	local r={}
	for i=1,32 do
		if op1[i]==1 and op2[i]==1  then
			r[i]=1
		else
			r[i]=0
		end
	end
	local test = self:b2d(r)]]
	local test = bit32.band(a,b)
	shaco.trace(sfmt("------------------------test ======--== %d",test))
	--return  self:b2d(r)
end

function bit:test()
	--bit32.
	self:_and(77,28)
end

return bit