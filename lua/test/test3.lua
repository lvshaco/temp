--mysql_table: 
--x_role = 1 ; x_card = 2 ; x_club_info = 3 ; x_ectype_fast = 4
local f = loadfile("../lua/test/test1.lua")
local t = {name = "断灭英卫",roleid = 168,level = 5,gm_level = 2,}
f(t)


--[[local function foo(...) 
	print("select('#', ...) === "..select('#', ...))
    for i = 1, select('#', ...) do --get the count of the params  
        local arg = select(i, ...) --select the param  
        print("arg", arg)
		if arg == 1 then
		
		else
			print("name == "..arg.name)
		end
    end  
end  
  
 foo(1, t)]]
