local tbl = require "tbl"
--local f = loadfile("../lua/test/change_db.lua")
local t = {acc = "lqs222",num = 3,name ="",db_name = "",role = "role_info"}
local card = {cardid = 41104,num = 1,operate_type = "delete"}----delete,add,select
local task = {taskid = 10055001,operate_type = "delete" }----delete,select
local club = {operate_type = "select" }----delete,select
local item = {itemid = 70000005,cnt = 100,bag_type = 3,operate_type = "select"}-- delete,select,add
local ladder = {operate_type = "select"}--select,delete
local base = {operate_type = "select"}----select, change"
local info = {vip_level = 15,physical = 100,gold = 10000,coin = 10000, operate_type = "change",ectypeid = 1021 }---select,change
local gm = {operate_type = "change",gm_level = 2} ---- select,change
local db_data

local function select_task()
    local flag = ""
    local taskv
    local tasks = db_data.list
    for _,v in pairs(tasks) do
        if v.taskid == task.taskid then
            flag = "continue"
            taskv = v
        end
     end
    local old_tasks = db_data.old_task
    for _,v in pairs(old_tasks) do
        if v.old_id == task.taskid then
            flag = "old"
            taskv = v
        end
    end
    return flag,taskv
end

local function delete_task() 
    local tasks = db_data.list
    for k,v in pairs(tasks) do
        if v.taskid == task.taskid then
            table.remove(tasks,k)
        end
     end
    local old_tasks = db_data.old_task
    local i = 1
    while old_tasks[i] do
        if old_tasks[i].old_id == task.taskid then
            table.remove(old_tasks,i)
        else
            i = i + 1
        end
    end
end

local function select_card()
    local cards = db_data.list.list
    local card_list = {}
    for _,v in pairs(cards) do
        if card.cardid == v.cardid then
            card_list[#card_List + 1] = v
        end
    end
    return card_list
end

local function delete_card()
    local cards = db_data.list.list
    local i = 1
    while cards[i] do
        if cards[i].cardid == card.cardid then
            table.remove(cards,i)
        else
            i = i + 1
        end
    end
    
end

local function select_item()
    local item_list = {}
    local flag = ""
    local material = db_data.mat
    local equip = db_data.equip

    for _,v in pairs(material) do
        if v.tpltid == item.itemid then
            flag = "material"
            item_list[#item_list + 1] = v
        end
    end
    for _,v in pairs(equip) do
        if v.tpltid == item.itemid then
            flag = "equip"
            item_list[#item_list + 1] = v
        end
    end
    return flag,item_list
end

local function delete_item()
    local package = db_data.package
    local material = db_data.mat
    local equip = db_data.equip
    local i = 1
    while package[i] do
        if package[i].tpltid == item.itemid then
            table.remove(package,i)
        else
            i = i + 1
        end
    end
    local i = 1
    while material[i] do
        if material[i].tpltid == item.itemid then
            table.remove(material,i)
        else
            i = i + 1
        end
    end
    local i = 1
    while equip[i] do
        if equip[i].tpltid == item.itemid then
            table.remove(equip,i)
        else
            i = i + 1
        end
    end
end

db_data = select(2,...)
if db_data then
   -- tbl.print(db_data,"-------db_data ==")
    if t.db_name == "task" then 
        if task.operate_type == "delete" then
            delete_task(db_data)
            return db_data
        elseif task.operate_type == "select" then
           local flag,taskv = select_task(db_data)           
           if flag ~= "" then
               --tbl.print(taskv,"--state =="..flag.."--taksv ==")
            else
                print("taskid == "..task.taskid.." is not exist")
            end
            return
        end
    elseif t.db_name == "card" then
        if card.operate_type == "delete" then
            delete_card(db_data)
            return db_data
        elseif card.operate_type == "select" then
            local card_list = select_data(db_data) 
            --tbl.print(card_list,"------carid == "..card.cardid)
            return
        end
    elseif t.db_name == "club" then
        if club.operate_type == "select" then
            --tbl.print(db_data,"-----club info == ")
            return
        elseif club.operate_type == "delete" then
            db_data.data.challengecnt = 0
            return db_data
        end
    elseif t.db_name == "item" then
        if item.operate_type == "select" then
            local flag,item_list = select_item(db_data)
            --tbl.print(item_list,"-----itemid== "..item.itemid.." in "..flag.." == ")
            return
        elseif item.operate_type == "delete" then
            delete_item(db_data)
            return db_data
        end
    elseif t.db_name == "ladder" then
        if ladder.operate_type == "select" then
            --tbl.print(db_data.ladder_data,"----------ladder info ===")
            return
        end
    elseif t.db_name == "recharge" then
        --tbl.print(db_data.data,"----------recharge info ===")
        return
    elseif t.db_name == "spectype" then
        --tbl.print(db_data.sp_data,"----------spectype info ===")
        return
    end
end
local flag = select(3,...)
if flag == 1 then
    print("----------roleid not exist------in "..t.db_name.."-----------")
    return
end

local role_data = select(4,...)
if db_data then
    if t.role == "role_base" then 
        if base.operate_type == "select" then
            --tbl.print(role_data,"-------- role base ===")
            return
        elseif base.operate_type == "change" then
            if t.level > 0 then
                role_data.level = t.level
                return role_data
            else
                return
            end
        end
    elseif t.role == "role_info" then
        if info.operate_type == "select" then
            --tbl.print(role_data,"-----****----- role_info == ")
            return
        elseif info.operate_type == "change" then
            if info.vip_level > 0 then
                local vip = role_data.vip
                if vip then
                    vip.vip_level = info.vip_level
                end
            end
            role_data.physical = role_data.physical + info.physical
            role_data.gold = role_data.gold + info.gold
            role_data.coin = role_data.coin + info.coin
			if info.ectypeid > 0 then
				local function ectype_data_gen()
					return {
						ectypeid = 0,
						star = 0,
					}
				end
				local ectype_info = ectype_data_gen()
				ectype_info.ectypeid = info.ectypeid
				ectype_info.star = 3
				role_data.ectype[#role_data.ectype + 1] = ectype_info
			end
            return role_data
        end
    elseif t.role == "role_gm" then
        if gm.operate_type == "select" then
            print("role_data ======= "..role_data)
            return
        elseif gm.operate_type == "change" then
            role_data = gm.gm_level
            return role_data
        end
    end
end

return t
