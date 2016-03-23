-------------------interface---------------------
--function task_check_state(task, task_type, parameter1, parameter2)
--function task_accept(task,id)
-------------------------------------------------
local shaco = require "shaco"
local tptask = require "__tptask"
local bit32 = require"bit32"
local tbl = require "tbl"
local ipairs = ipairs
local sfmt = string.format
local sfind = string.find
local sub = string.sub
local len = string.len
local task_fast = require "task_fast"
local tpgamedata = require "__tpgamedata"
local itemop = require "itemop"
local tpskill = require "__tpskill"
local tpitem = require "__tpitem"
local tpgodcast = require "__tpgodcast"
local task = {}
--math.randomseed(os.time())

local vip_task_id = 30063000

local function task_base_gen()
    return {
        taskid = 0,
		finish = 0,
		taskprogress = 0,
		taskprogress2 = 0,
		previd = 0,
    }
end

local function old_task_gen()
	return {
		old_id = 0,
	}
end

local function pass_ectype_gen()
	return {
		ectypeid = 0,
		star = 0,
	}
end

local function check_state(taskv, task_type)
	local tasks = {}
	local flag = false
	for k, v in ipairs(taskv) do
        local t = tptask[v.taskid]
		if t and t.method == task_type and t.condition1 <= v.taskprogress and v.finish ~= 1 then
			tasks[#tasks + 1] = v.taskid
			flag = true
		end
	end
	return flag,tasks
end


function task.new(type, taskv)
	local task = {}
	local tasks = taskv
	if tasks then
		if not tasks.list or #tasks.list == 0 then
			tasks.list = {}
		end
		if not tasks.old_task or #tasks.old_task == 0 then
			tasks.old_task = {}
		end
		local task_list = {}
		for i = 1,#tasks.list do
			local info = tasks.list[i]
			if info.taskid > 0 then
				task_list[#task_list + 1] = info
			end
		end
		
		task = {
			tasks = task_list,
			old_tasks = tasks.old_task
		}
	else
		task = {
			tasks = {},
			old_tasks = {}
		}
	end
--	tbl.print(task,"-----------task")
	return task
	--[[local __task = taskv
	__task.list = __task.list or {}
    local task_list = {}
    for i = 1,#__task.list do
        local info = __task.list[i]
        if info.taskid > 0 then
            task_list[#task_list + 1] = info
        end
    end
   -- tbl.print(__task.list,"-----------__task.list ==== ")
   -- tbl.print(task_list,"-----------task_list")
    __task.list = task_list
	if #__task.old_task == 0 then
		__task.old_task = {}
	end
    taskslocal task = {
        tasks = __task.list,
		old_tasks = __task.old_task
    }
    return task]]
end

function task.init_old_task(ur)
	local old_task = ur.task.old_tasks
	local old_task_info = old_task_gen()
	old_task_info.old_id = 1
	old_task[#old_task + 1] = old_task_info
end

function task.taskclear(ur,taskid)
	local old_task = ur.task.old_tasks
	for i = 1,#old_task do
		if old_task[i].old_id == taskid then
			old_task[i].old_id = 0
		end
	end
end

local function check_exsit(ur,id)
	local tp = tptask[id]
	if tp and tp.type ~= DAILY_TASK then
		local old_task = ur.task.old_tasks
		local tasks = ur.task.tasks
		for i = 1,#old_task do
			if old_task[i].old_id == id then
				--shaco.warn("------------------the task already finish  taskid === "..id)
				return SERR_TASK_ALREADY_FINISH
			end
		end
		for i = 1,#tasks do
			if tasks[i].taskid == id then
				--shaco.warn("----------------------the task already exsit  taskid === "..id)
				return SERR_TASK_ID_IS_EXSIT
			end
		end
	end
	return 1
end

local function check_previd_state(tasks,previd)
	for i = 1,#tasks do
		if tasks[i].taskid == previd then
			return previd
		end
	end
	return 0
end

function task.accept(ur,id)
	local task = task_base_gen()
	local tasks = ur.task.tasks
	local previd = 0
	local tp = tptask[id]
	if not tp then
		shaco.warning("the ask not exsit") 
		return SERR_TASK_ID_NOT_EXSIT,task
	end
	
	previd = check_previd_state(tasks,tp.previd)
	
	local state = check_exsit(ur,id)
	if (tp.occup == 0 or tp.occup == ur.base.race) and state == 1 and ur.base.level >= tp.level and ur.base.level <= tp.maxlevel then
		local flag = false
		--[[for i=1, #tasks do
			if tasks[i].taskid == 0 then
				tasks[i].taskid = id
				tasks[i].finish = 0
				tasks[i].taskprogress = 0
				flag = true
				
				break
			end
		end]]
		
		if flag == false then
			task.taskid = id
			task.finish = 0
			task.taskprogress = 0
			task.previd = previd
			tasks[#tasks +1] = task
		end
	else
		return state,task
	end	
	ur.task.tasks = tasks	
	return 1,task
end

local function get_next_task(taskid,race)
	local task_array = {}
	for k, v in pairs(tptask) do
		if v.previd == taskid then
			local flag = false
			if v.occup > 0 then
				if v.occup == race then
					flag = true
				end
			else
				flag = true
			end
			if flag then
				task_array[#task_array + 1] = k
			end
		end
	end
	return task_array
end

local function check_log(old_task,id)
	local next_task = 0
	local flag = false
	if old_task then
		for k,v in ipairs(tptask) do
			if v.previd == id then
				next_task = v.id
			end
		end
		for i = 1,#old_task do
			local info = old_task[i]
			if info.old_id == next_task then
				flag = true
			end
		end
	end
	if flag then
		--tbl.print(old_task,"  ------- read Default Values error old_task ==== ")
	end
end

local function accept_next_task(ur,id)
	local old_task = ur.task.old_tasks
	local old_task_info = old_task_gen()
	old_task_info.old_id = id
	check_log(old_task,id)
	old_task[#old_task + 1] = old_task_info
	local task_array = get_next_task(id,ur.base.race)
	for i =1,#task_array do
		task.accept_task(ur, task_array[i])
	end
end

function task.finish(ur,id)
	local tp = tptask[id]
	if not tp then
		return false
	end
	local tasks = ur.task.tasks
	for i = 1,#tasks do
		if tasks[i].taskid == id then
			tasks[i].finish = 1
			if tp.type ~= DAILY_TASK then
				accept_next_task(ur,id)
			end
			return true
		end
	end
	return false
end

local function get_card_max_level(ur)
	local cards = ur.cards.__card.__cards
	local max_level =  0
    for i =1, #cards do
    	local card = cards[i] 
		if card.cardid > 0 and card.level > max_level then
			max_level = card.level
		end
    end
	return max_level
end

local function get_skill_level(ur)
	local max_level = 0
	local skill = ur.info.skills
	for i = 1,#skill do
		local tp = tpskill[skill[i].skill_id]
		if tp.level > max_level then
			max_level = tp.level
		end
		for j =1,#skill[i].gift do
			local gift_info = skill[i].gift[j]
			if gift_info.level > max_level then
				max_level = gift_info.level
			end
		end
	end
	return max_level
end

local function get_refine_cnt(itemid)
	local indx = 0
	for k,v in pairs(tpgodcast) do
		if v.equipID == itemid then
			for i =1,10 do
				if #v["star"..i] > 0 then
					indx = indx + 1
				end
			end
		end
	end
	return indx
end

local function get_weapon_godcast_num(ur)
	local max_star = 0
	local cards = ur.cards.__card.__cards
	for i =1, #cards do
    	local card = cards[i] 
		local bag = card.equip
		if bag and card.cardid > 0 then
			local item = itemop.get(bag, EQUIP_WEAPON)
			if item then
				local star = get_refine_cnt(item.tpltid)
				if star > max_star then
					max_star = star
				end
			end
		end
	end
	local bag = ur:getbag(BAG_EQUIP)
	if bag then
		local item = itemop.get(bag,EQUIP_WEAPON)
		if item then
			local star = get_refine_cnt(item.tpltid)
			if star > max_star then
				max_star = star - item.info.refinecnt
			end
		end
	end
	return max_star
end

local function get_card_max_break_through(ur)
	local cards = ur.cards.__card.__cards
	local max_num =  0
    for i =1, #cards do
    	local card = cards[i]
		if card.cardid > 0 then
			if card.break_through_num > max_num then
				max_num = card.break_through_num
			end
		end
    end
	return max_num
end

local function get_weapon_quality(ur)
	local quality = 0
	local cards = ur.cards.__card.__cards
	for i =1, #cards do
    	local card = cards[i] 
		local bag = card.equip
		if bag and card.cardid > 0 then
			local item = itemop.get(bag, EQUIP_WEAPON)
			if item then
				local tp_item = tpitem[item.tpltid]
				if tp_item.quality > quality then
					quality = tp_item.quality
				end
			end
		end
	end
	local bag = ur:getbag(BAG_EQUIP)
	if bag then
		local item = itemop.get(bag,EQUIP_WEAPON)
		if item then
			local tp_item = tpitem[item.tpltid]
			if tp_item.quality > quality then
				quality = tp_item.quality
			end
		end
	end
	return quality
end

local function check_task_finish(ur,taskid)
	local flag = false
	local tp = tptask[taskid]
	local condition1 = tp.condition1
	if tp.method == 1 then
		local ectype_list = ur.info.ectype
		for i = 1,#ectype_list do
			if ectype_list[i].ectypeid == condition1 then
				flag = true 
			end
		end
	--elseif tp.method == 3 then
	--	local level = ur.base.level 
	--	if level >= condition1 then
	--		flag = true
	--	end
	elseif tp.method == 4 then
		local own_cards = ur.cards.__own_cards
		if #own_cards >= condition1 then
			flag = true
		end
	elseif tp.method == 5 then
		local bag = ur:getbag(BAG_EQUIP)
		if bag then
			local item = itemop.get(bag,EQUIP_WEAPON)
			if item then
				if item.info.level >= condition1 then
					flag = true
				end
			end
		end
	elseif tp.method == 22 then
		local max_num = get_card_max_break_through(ur)
		if max_num >= condition1 then
			flag = true
		end
	elseif tp.method == 24 then
		local quality = get_weapon_quality(ur)
		if quality >= condition1 then
			flag = true
		end
	elseif tp.method == 25 then
		if ur.battle_value >= condition1 then
			flag = true
		end
	elseif tp.method == 27 then
		local level = get_card_max_level(ur)
		if level >= condition1 then
			flag = true
		end
	elseif tp.method == 47 then
		local max_level = get_skill_level(ur)
		if max_level >= condition1 then
			flag = true
		end
	elseif tp.method == 53 then
		local max_star = get_weapon_godcast_num(ur)
		if max_star >= condition1 then
			flag = true
		end
	elseif tp.method == 55 then
        local max_floor = ur.spectype.max_floor
        if max_floor > condition1 then
            flag = true
        end
	end
	return flag
end

function task.accept_task(ur, taskid)
    local update = 0
    local taskv = {}
    update,taskv = task.accept(ur,taskid)
    if update ~= 1 then
    	return 
    end 
	local flag = check_task_finish(ur,taskid)
	if flag == true then
		task.finish(ur,taskid)
		ur:send(IDUM_SYNCTASKLIST, {info = ur.task.tasks})
	else
		ur:send(IDUM_UPDATETASK, {taskid = taskv.taskid})
	end
    ur:db_tagdirty(ur.DB_TASK)
end

local function check_refresh_time(ur)
	local updatetime = 3
	local time = os.time()
	local curtime=os.date("*t",time)
	local refresh_time = shaco.now()//1000--ur.info.refresh_time
	local lasttime=os.date("*t",refresh_time)
	if curtime.year > lasttime.year then
		return true
	else	
		if curtime.month > lasttime.month then
			return true
		else
			if curtime.day > lasttime.day and curtime.hour >= updatetime then
				return true
			end
		end
	end
	
	return false
end

local function clear_daily(ur)
	local newtasks = {}
	local tasks = ur.task.tasks
	for k, v in ipairs(tasks) do
		local tp = tptask[v.taskid]
		if tp and tp.type == DAILY_TASK then
			--print("-------------------------- taskid == "..v.taskid)
			v.taskid = 0
			v.finish = 0
			v.taskprogress = 0
		end
		--if v.tasktype ~= 2 then
		--	newtasks[#newtasks + 1] = v
		--end
	end
	--ur.task.tasks = newtasks
end

function task.daily_update(ur)
	if ur.base.level < tpgamedata.dayTaskLevel then
		return false
	end
	
	local flag,daily_list = task_fast.update_daliy(ur.base.level)
	if flag == false then
		return false
	end
	clear_daily(ur)
	for i=1,#daily_list do
		task.accept(ur,daily_list[i])
 	end
 	return true
end

local function get_new_daily_task(level,previous_level)
	local task_list = {}
	local cur_daily = task_fast.get_daily_info(level)
	local previous_daily = task_fast.get_daily_info(previous_level)
	for i = 1,#cur_daily do
		local cur_id = cur_daily[i]
		local cur_tp = tptask[cur_id]
		local flag = false
		--for j =1,#previous_daily do
			--local pre_id = previous_daily[i]
			--local pre_tp = tptask[pre_id]
			--if cur_tp.method == pre_tp.method then
				--flag = true
			--	break
			--end	
		--end
		if not flag then
			task_list[#task_list + 1] = cur_id
		end
	end
	return task_list
end

function task.update_daily(ur,previous_level)
	local level = ur.base.level
	local tasks = ur.task.tasks
	local new_task = {}	
	local daily_list = {}
	local flag = 1
	if level < tpgamedata.dayTaskLevel then
		return false
	end
	
	if previous_level >= tpgamedata.dayTaskLevel then
		for i =1,5 do

			if i < 5 then
				if previous_level <= tpgamedata["LevelgroupEnd"..i] and level >= tpgamedata["LevelgroupStart"..(i + 1)] then
					daily_list = get_new_daily_task(level,previous_level)
				end
			end
		end
	else	
		daily_list = task_fast.get_daily_info(level)
	end
	for i=1,#daily_list do
		local taskid = daily_list[i]
		if check_exsit(ur,taskid)  == 1 then
			local update,taskv = task.accept(ur,taskid)
			--print("update === "..update.."  taskid == "..taskid)
			if update == 1 then
				local function new_task_gen()
					return {
						taskid = 0,
					}
				end
				local new_task_info = new_task_gen()
				new_task_info.taskid = taskid
				new_task[#new_task + 1] = new_task_info
				flag = 2
			end
		end
	end
	if flag == 2 then
		ur:send(IDUM_SYNCNEWTASK, {tasks = new_task})
		ur:db_tagdirty(ur.DB_TASK)
	end
end

function task.refresh_toclient(ur, task_type,parameter1,parameter2)
	--[[local tasks = ur.task.tasks
	
	if not tasks then
		return
	end
	local flag,taskv = check_state(tasks, task_type)
	--if not flag then
	--	return
	--end
	for i = 1,#taskv do
		task.finish(ur,taskv[i])
	end
	ur:db_tagdirty(ur.DB_TASK)
	ur:send(IDUM_TASKLIST, {info = tasks})]]
end

function task.first_accept(ur)
	for k, v in pairs(tptask) do
		if v.previd == 0 and (v.type == 1 or v.type == 2) and v.level <= ur.base.level and v.maxlevel >= ur.base.level then
			task.accept(ur,k)
		end
	end
end

function task.change_task_progress(ur,method,flag,cnt)
	local tasks = ur.task.tasks or {}
	for k, v in ipairs(tasks) do
		local tp = tptask[v.taskid]
		if tp and tp.method == method then
			if flag == 1 then
				v.taskprogress = v.taskprogress + cnt
			else
				v.taskprogress = 0
			end
			if tp.method == method and tp.condition1 <= v.taskprogress and v.finish ~= 1 then
				v.finish = 1
				accept_next_task(ur,v.taskid)
			end
			ur:db_tagdirty(ur.DB_TASK)
			ur:send(IDUM_SYNCTASKPROGRESS, {task_info = v})
		end
	end
end

function task.set_task_progress(ur,method,progress,progress2)
	local tasks = ur.task.tasks
	for k, v in ipairs(tasks) do
		local tp = tptask[v.taskid]
		if tp and tp.method == method then
			v.taskprogress = progress
			if tp.method == method and tp.condition1 <= v.taskprogress and v.finish ~= 1 then
				v.finish = 1
				accept_next_task(ur,v.taskid)
				ur:db_tagdirty(ur.DB_TASK)
			end
			ur:send(IDUM_SYNCTASKPROGRESS, {task_info = v})
		end
	end
end

local function check_vip_task(ur)
	if ur.info.vip.vip_level > 0 then
		task.accept(ur,vip_task_id)
		task.finish(ur,vip_task_id)
	end
end

function task.finsh_vip_task(ur)
	check_vip_task(ur)
	--[[]local tasks = ur.task.tasks
	for k, v in ipairs(tasks) do
		if v.taskid == vip_task_id then
			ur:send(IDUM_SYNCTASKPROGRESS, {task_info = v})
		end
	end]]
	ur:send(IDUM_TASKLIST, {info = ur.task.tasks})
	ur:db_tagdirty(ur.DB_TASK)
end

function task.update_daily_task(ur)
	if ur.base.level < tpgamedata.dayTaskLevel then
		return true
	end
	local daily_list = task_fast.get_daily_info(ur.base.level)
	--tbl.print(daily_list, "=============init daily_list", shaco.trace)
	clear_daily(ur)
	--tbl.print(ur.task.tasks, "=============init ur.task.tasks", shaco.trace)
	
	for i=1,#daily_list do
		task.accept(ur,daily_list[i])
 	end
	check_vip_task(ur)
	--ur:db_tagdirty(ur.DB_ROLE)
    ur:db_tagdirty(ur.DB_TASK)
	ur:send(IDUM_TASKLIST, {info = ur.task.tasks})
	return true
end

function task.accept_daily_task(ur)
	local flag = false
	local tasks = ur.task.tasks
	for k, v in ipairs(tasks) do
		local tp = tptask[v.taskid]
		if tp and tp.type == DAILY_TASK then
			flag = true
			break
		end
	end
	if flag then
		return
	end
	task.update_daily_task(ur)
end

function task.ectype_task_min_level()
	for k, v in pairs(tptask) do
		if v.previd == 0 and v.type == 1 and v.method == 1 then
			return v.level
		end
	end
end

function task.accept_new_task(ur)
	local tasks = ur.task.tasks
	local update = 0
	local taskv = {}
	for k, v in pairs(tptask) do
		if v.previd == 0 and (v.type == 1 or v.type == 2) and v.level <= ur.base.level and v.maxlevel >= ur.base.level then
			local tp = tptask[k]
			if tp then
				if check_exsit(ur,k)  == 1 then
					task.accept_task(ur, k)
				end	
			end
		end
	end
end

function task.check_ectype_task(ur)
	local flag = false
	local tasks = ur.task.tasks
	for k, v in ipairs(tasks) do
		local tp = tptask[v.taskid]
		if tp.method == 1 then
			flag = true
		end
	end
	if not flag then
		local update = 0
		local taskv = {}
		for k, v in pairs(tptask) do
			if v.previd == 0 and v.type == 1 and v.method == 1 then
				if check_exsit(ur,k)  == 1 then
					update,taskv = task.accept(ur,k)
					if update == 1 then
						ur:send(IDUM_UPDATETASK, {taskid = taskv.taskid})
						ur:db_tagdirty(ur.DB_TASK)
						break
					end 
				end	
			end
		end
	end
end

return task
