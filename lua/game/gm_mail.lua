--local shaco = require "shaco"
local shaco = require "shaco"
local pb = require "protobuf"
local rcall = shaco.callum
local CTX = require "ctx"
local tbl = require "tbl"
local sfmt = string.format
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local mysql = require "mysql"
local tonumber = tonumber
local userpool = require "userpool"
local mail = require"mail"

local gm_mail = {}
local mail_list = {}
local update_time = 0

local function mail_gen()
	return {
		mail_read_time=0,
		mail_id=0,
		mail_type = 0,
		mail_theme = "",
		mail_content = "",
		mail_gold = 0,
		mail_cion = 0,
		item_info = {},
		read_save = 0, 
		unread = 0,
		send_time = 0,
	}
end

local function mail_item_gen(item)
	return {
		item_type = item.item_type,
		item_id = item.item_id,
		item_cnt = item.item_cnt,
		hole_cnt = item.hole_cnt,
		washcnt = item.washcnt,
	}
end

local function add_gm_mail(mails,mailv)
	local itemid = 0
	local money_type = 0
	local cnt = 0
	
	local mail_list = mailv.data
	
	for i = 1,#mails do
		local _mail = mails[i]
		local mail_info = mail_gen()
		mail_info.mail_id = tonumber(_mail.mail_id)
		mail_info.mail_type = tonumber(_mail.mail_type)
		mail_info.item_info = _mail.mail_tems
		mail_info.unread = 86400000
		mail_info.read_save = 0
		mail_info.mail_theme = _mail.mail_theme
		mail_info.mail_content = _mail.mail_content
		mail_info.mail_content2 = _mail.mail_content2
		mail_info.mail_content3 = _mail.mail_content3
		mail_info.mail_gold = _mail.mail_gold
		mail_info.mail_cion = _mail.mail_cion
		mail_info.send_time = shaco.now()//1000
		mail_list[#mail_list + 1] = mail_info
	end
end

local function check_time(mail_time,now)
local cur_time=os.date("*t",now//1000)

	if mail_time.year == cur_time.year then
		if mail_time.mon == cur_time.month then
			if mail_time.day == cur_time.day then
				if mail_time.hour == cur_time.hour then
					print("--- mail_time.minute === "..mail_time.minute.."-----cur_time.min ==   "..cur_time.min)
					if mail_time.minute <= cur_time.min then
						print("----------------------------  ")
						return true
					end
				elseif mail_time.hour < cur_time.hour then
					return true
				end
			end
		elseif mail_time.mon < cur_time.mon then
			return true
		end
	elseif mail_time.year < cur_time.year then
		return true
	end
	return false
end

function gm_mail.update(now)
	if now//1000 - update_time >= 3000 then
		update_time = now//1000
		shaco.fork( function()
			--[[local conn = assert(mysql.connect{
				host = "192.168.1.220", 
				port = 3306,
				db = "common", 
				user = "jie", 
				passwd = "123456",
			})
			local result = conn:execute(sfmt("select * from x_mail_common"))
			if not result then
				return
			end
			if result.err_code then
				--shaco.warn(sfmt("role str_code == %s \n savefail: message == %s",str_code, result.message))
			else
				--shaco.trace(sfmt("role str_code = = %s save ok",str_code))
			end
			]]
			--local mail_list = {}
			--for i = 1,#result do
			--	local _result = result[i]
			--	if _result.mail_state == '0' then
			--		local _time = _result.mail_time
			--		print("_time ================= ".._time)
			--		local index = {"year","mon","day","hour","minute","sec"}
			--		local time_list = {}
			--		local indx = 1
			--		for w in string.gmatch(_time, "[^/]+") do
			--			time_list[index[indx]] = tonumber(w)
			--			indx = indx + 1
			--		end
				--	_result.mail_time = time_list
				--	if check_time(_result.mail_time,now) then
			--			local items = {}
			--			local index_name = {"item_type","item_id","item_cnt","hole_cnt","washcnt"}
			--			if _result.mail_tems ~= "" then
			--				for w in string.gmatch(_result.mail_tems, "[^;]+") do
			--					local str_list = {}
			--					local j = 1
			--					print("-------w ===== "..w)
				--				for s in string.gmatch(w, "[^,]+") do
				--					str_list[index_name[j]] = tonumber(s)
			--						j = j + 1
			--					end
			--					local item_info = mail_item_gen(str_list)
			--					items[#items + 1] = item_info
			--				end
			--			end
			--			_result.mail_tems = items
			--			mail_list[#mail_list + 1] = _result
			--			--conn:execute(sfmt("update x_mail_common set mail_state=%d where mail_id=%d",1,tonumber(_result.mail_id)))
			--		end
			--	end
		--	end
			--tbl.print(mail_list,"----- mail_list ==== ")
		--[[		tbl.print(mail_list,"----- mail_list ==== ")
				local role_list= rcall(CTX.db, "L.allrole")
				for i = 1,#role_list do
					local roleid = tonumber(role_list[i].roleid)
					local ur = userpool.find_byid(roleid)
					if ur then
						mail.send_gm_mail(ur,mail_list)
					else
						local mail= rcall(CTX.db, "L.ex", {roleid=roleid, name="mail"})
						if mail then
							mail = pb.decode("mail_list", mail)
						else
							mail = {}
							mail.data = {}
							mail.old_info = {}
						end
						-- tbl.print(mail,"-------222222222- v.name ===")
						add_gm_mail(mail_list,mail)
						
						shaco.sendum(CTX.db, "S.ex", {
							name="mail",
							roleid=roleid,
							data=pb.encode("mail_list", {data = mail.data,old_info = mail.old_info}),
						})
					
					end
				end
				
			
			--local role_list = conn:execute(sfmt("select roleid from x_role"))
			--local conn2user = userpool.get_conn2user()
			--for _, ur in pairs(conn2user) do
			--	ur:send(IDUM_NEWNOTICEBROADCAST,{content = str})
			--end
			--tbl.print(role_list,"role_list ==================")]]
		end)
	end
end


return gm_mail
