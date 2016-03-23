local shaco = require "shaco"
local tbl = require "tbl"
local tpscene = require "__tpscene"
local sfmt = string.format
local uid_scenes = {}
local tpid_scenes = {}
local uid_alloc = 0
local scene = {}

local function is_city(tp)
    return tp.type == SCENE_CITY
end

local function scene_single(tp)
    return tp.type ~= SCENE_CITY and
           tp.type ~= SCENE_BOSS
end

local function scene_gen(uid, tpid)
    return {
        __uid = uid,
        __tpid = tpid,
        __lines = {},
        __chanid = nil,
        __iscity = false,
    }
end

local function scene_obj_gen(obj)
    return {
        name = obj.base.name,
        tpltid = obj.base.tpltid,
        oid = obj.info.oid,
        posx = obj.info.posx,
        posy = obj.info.posy,
    }
end

local function test_scene_obj_gen()
    return {
        name = "12345622qq",
        tpltid = 1,
        oid = 10100,
        posx = 300,
        posy = 100,
    }
end

local function select_line(s)
    local lines = s.__lines
    if s.__chanid then
        local idx
        local li_limit = 50
        local li_max = -1 
        for i, v in ipairs(lines) do
            if v.__nobj < li_limit and v.__nobj > li_max then
                li_max = v.__nobj
                idx = i
            end
        end
        if not idx then
            table.insert(lines, {__chanid = s.__chanid.."#"..(#lines+1), __nobj=0, __objs={}})
            idx = #lines
        end
        return idx
    else
        if #lines==0 then
            lines[1] ={__chanid = nil, __nobj=0, __objs={}}
        end
        return 1
    end
end

function scene.enter(obj, tpid)
    local tp = tpscene[tpid]
    if not tp then
        shaco.warn(sfmt("scene %u not found", tpid))
        return
    end
    local s = tpid_scenes[tpid]
    if s == nil then
        uid_alloc = uid_alloc + 1
        while uid_scenes[uid_alloc] ~= nil do
            uid_alloc = uid_alloc + 1
        end
        s = scene_gen(uid_alloc, tpid)
        if scene_single(tp) then
            s.__chanid = nil
        else
            s.__chanid = "S"..uid_alloc
        end
        if is_city(tp) then
            s.__iscity = true
        end
        uid_scenes[uid_alloc] = s
        tpid_scenes[tpid] = s
    end
    if obj.scene then
        scene.exit(obj)
    end
    local oid = obj.info.oid 
    --assert(s.__objs[oid] == nil)

    local lineid = select_line(s)
    local line = s.__lines[lineid]
    obj.info.mapid = tpid
    if s.__iscity and
       (obj.info.lastx ~= 0 or obj.info.lasty ~= 0) then
        obj.info.posx = obj.info.lastx
        obj.info.posy = obj.info.lasty
        --shaco.trace("-----enter city and moveto last:", obj.info.posx, obj.info.posy)
    else
        obj.info.posx = tp.reviveX
        obj.info.posy = tp.reviveY
        --shaco.trace("-----enter revive:", obj.info.posx, obj.info.posy)
    end
    obj.scene = s
    obj.lineid = lineid
    shaco.trace(sfmt("scene %u:%u#%u enter obj %u", tpid, s.__uid, lineid, oid))

    obj:send(IDUM_SCENECHANGE, {mapid=tpid, 
        posx=obj.info.posx, posy=obj.info.posy})
    if line.__chanid then
        for _, o in pairs(line.__objs) do
            local so = scene_obj_gen(o)
            obj:send(IDUM_OBJECTAPPEAR, {info=so})
        end
        local so = scene_obj_gen(obj)
        obj:chan_publish(line.__chanid, IDUM_OBJECTAPPEAR, {info=so})
        obj:chan_subscribe(line.__chanid)
    end 
    line.__objs[oid] = obj
    line.__nobj = line.__nobj+1
    return true
end

function scene.addrobot(ur,cnt)
	for i =1,cnt do
		local so = test_scene_obj_gen()
		so.oid = so.oid + i
		so.posx = so.posx + math.random(0,200)
		so.posy = so.posy + math.random(0,200)
		so.name = so.name..tostring(i)
		ur:send(IDUM_OBJECTAPPEAR, {info=so})
	end
end

local function _get_scene(obj)
    local s = obj.scene
    if s then
        return s, s.__lines[obj.lineid]
    end
end

function scene.exit(obj)
    local s, line = _get_scene(obj)
    assert(s ~= nil)
    assert(line ~= nil)

    if s.__iscity then
        obj.info.last_city = s.__tpid
        obj.info.lastx = obj.info.posx
        obj.info.lasty = obj.info.posy
    end

    local oid = obj.info.oid
    if line.__objs[oid] ~= obj then
        shaco.error(sfmt("obj:%d %d dismatch", obj.base.roleid, tostring(obj.info.oid)), line.__objs[oid])
        error(false)
    end
    shaco.trace(sfmt("scene %u:%u#%u exit obj %u", s.__tpid, s.__uid, obj.lineid, oid))
    line.__objs[oid] = nil
    line.__nobj = line.__nobj-1
    obj.scene = nil
    obj.lineid = 0

    if line.__chanid then
        local v = {oid=oid}
        for _, o in pairs(line.__objs) do
            obj:send(IDUM_OBJECTDISAPPEAR, v)
        end 
        obj:chan_publish(line.__chanid, IDUM_OBJECTDISAPPEAR, v)
        obj:chan_unsubscribe(line.__chanid)
    end
end

function scene.move(obj, v)
    local s, line = _get_scene(obj)
    if line==nil then return end

    local oid = obj.info.oid
    obj.info.posx = v.posx
    obj.info.posy = v.posy
    local v = {
        oid = oid,
        posx = v.posx,
        posy = v.posy,
        speed = v.speed,
        dirx = v.dirx,
        diry = v.diry,
    }
    shaco.trace(sfmt("scene %u:%u#%u move obj %u", s.__tpid, s.__uid, obj.lineid, oid))

    if line.__chanid then
        obj:chan_publish(line.__chanid, IDUM_MOVESYNC, v)
    else
        obj:send(IDUM_MOVESYNC, v)
    end
end

function scene.movestop(obj, v)
    local s, line = _get_scene(obj)
    if line==nil then return end
    
    local oid = obj.info.oid
    obj.info.posx = v.posx
    obj.info.posy = v.posy
    local v = {
        oid = oid,
        posx = v.posx,
        posy = v.posy,
    }
    shaco.trace(sfmt("scene %u:%u#%u movestop obj %u", s.__tpid, s.__uid, obj.lineid, oid))
    if line.__chanid then
        obj:chan_publish(line.__chanid, IDUM_MOVESTOPSYNC, v)
    else
        obj:send(IDUM_MOVESTOPSYNC, v)
    end
end

return scene


--[[
local shaco = require "shaco"
local tbl = require "tbl"
local tpscene = require "__tpscene"
local sfmt = string.format
local uid_scenes = {}
local tpid_scenes = {}
local uid_alloc = 0
local scene = {}

local function is_city(tp)
    return tp.type == SCENE_CITY
end

local function scene_single(tp)
    return tp.type ~= SCENE_CITY and
           tp.type ~= SCENE_BOSS
end

local function scene_gen(uid, tpid)
    return {
        __uid = uid,
        __tpid = tpid,
        __lines = {},
        __chanid = nil,
        __iscity = false,
    }
end

local function scene_obj_gen(obj)
    return {
        name = obj.base.name,
        tpltid = obj.base.tpltid,
        oid = obj.info.oid,
        posx = obj.info.posx,
        posy = obj.info.posy,
    }
end

local function test_scene_obj_gen()
    return {
        name = "12345622qq",
        tpltid = 1,
        oid = 10100,
        posx = 300,
        posy = 100,
    }
end

local function select_line(s)
    local lines = s.__lines
    if s.__chanid then
        local idx
        local li_limit = 50
        local li_max = -1 
        for i, v in ipairs(lines) do
            if v.__nobj < li_limit and v.__nobj > li_max then
                li_max = v.__nobj
                idx = i
            end
        end
        if not idx then
            table.insert(lines, {__chanid = s.__chanid.."#"..(#lines+1), __nobj=0, __objs={}})
            idx = #lines
        end
        return idx
    else
        if #lines==0 then
            lines[1] ={__chanid = nil, __nobj=0, __objs={}}
        end
        return 1
    end
end

function scene.enter(obj, tpid)
    local tp = tpscene[tpid]
    if not tp then
        shaco.warn(sfmt("scene %u not found", tpid))
        return
    end
    local s = tpid_scenes[tpid]
    if s == nil then
        uid_alloc = uid_alloc + 1
        while uid_scenes[uid_alloc] ~= nil do
            uid_alloc = uid_alloc + 1
        end
        s = scene_gen(uid_alloc, tpid)
        if scene_single(tp) then
            s.__chanid = nil
        else
            s.__chanid = "S"..uid_alloc
        end
        if is_city(tp) then
            s.__iscity = true
        end
        uid_scenes[uid_alloc] = s
        tpid_scenes[tpid] = s
    end
    if obj.scene then
        scene.exit(obj)
    end
    local oid = obj.info.oid 
    --assert(s.__objs[oid] == nil)

    local lineid = select_line(s)
    local line = s.__lines[lineid]
    obj.info.mapid = tpid
    if s.__iscity and
       (obj.info.lastx ~= 0 or obj.info.lasty ~= 0) then
        obj.info.posx = obj.info.lastx
        obj.info.posy = obj.info.lasty
        --shaco.trace("-----enter city and moveto last:", obj.info.posx, obj.info.posy)
    else
        obj.info.posx = tp.reviveX
        obj.info.posy = tp.reviveY
        --shaco.trace("-----enter revive:", obj.info.posx, obj.info.posy)
    end
    obj.scene = s
    obj.lineid = lineid
    obj.scene_visibles = {}
    obj.scene_version = obj.scene_version+1
    obj.moving = false
    obj.scene_last_update = shaco.now()
    shaco.trace(sfmt("scene %u:%u#%u enter obj %u", tpid, s.__uid, lineid, oid))

    obj:send(IDUM_SCENECHANGE, {mapid=tpid, 
        posx=obj.info.posx, posy=obj.info.posy})
    --if line.__chanid then
    --    for _, o in pairs(line.__objs) do
    --        local so = scene_obj_gen(o)
    --        obj:send(IDUM_OBJECTAPPEAR, {info=so})
    --    end
    --    local so = scene_obj_gen(obj)
    --    obj:chan_publish(line.__chanid, IDUM_OBJECTAPPEAR, {info=so})
    --    obj:chan_subscribe(line.__chanid)
    --end 
    line.__objs[oid] = obj
    line.__nobj = line.__nobj+1
    return true
end

function scene.addrobot(ur,cnt)
	for i =1,cnt do
		local so = test_scene_obj_gen()
		so.oid = so.oid + i
		so.posx = so.posx + math.random(0,200)
		so.posy = so.posy + math.random(0,200)
		so.name = so.name..tostring(i)
		ur:send(IDUM_OBJECTAPPEAR, {info=so})
	end
end

local function _get_scene(obj)
    local s = obj.scene
    if s then
        return s, s.__lines[obj.lineid]
    end
end

function scene.exit(obj)
    local s, line = _get_scene(obj)
    assert(s ~= nil)
    assert(line ~= nil)

    if s.__iscity then
        obj.info.last_city = s.__tpid
        obj.info.lastx = obj.info.posx
        obj.info.lasty = obj.info.posy
    end

    local oid = obj.info.oid
    if line.__objs[oid] ~= obj then
        shaco.error(sfmt("obj:%d %d dismatch", obj.base.roleid, tostring(obj.info.oid)), line.__objs[oid])
        error(false)
    end
    shaco.trace(sfmt("scene %u:%u#%u exit obj %u", s.__tpid, s.__uid, obj.lineid, oid))
    line.__objs[oid] = nil
    line.__nobj = line.__nobj-1
    obj.scene = nil
    obj.lineid = 0

    --if line.__chanid then
    --    local v = {oid=oid}
    --    for _, o in pairs(line.__objs) do
    --        obj:send(IDUM_OBJECTDISAPPEAR, v)
    --    end 
    --    obj:chan_publish(line.__chanid, IDUM_OBJECTDISAPPEAR, v)
    --    obj:chan_unsubscribe(line.__chanid)
    --end
end

function scene.move(obj, v)
    local s, line = _get_scene(obj)
    if line==nil then return end

    if v.posx == obj.info.posx and
        v.posy == obj.info.posy then
        return
    end
    local oid = obj.info.oid
    obj.info.posx = v.posx
    obj.info.posy = v.posy
    obj.scene_version = obj.scene_version+1
    obj.moving = true
    --local v = {
    --    oid = oid,
    --    posx = v.posx,
    --    posy = v.posy,
    --    speed = v.speed,
    --    dirx = v.dirx,
    --    diry = v.diry,
    --}
    shaco.trace(sfmt("scene %u:%u#%u move obj %u", s.__tpid, s.__uid, obj.lineid, oid))

    --if line.__chanid then
    --    obj:chan_publish(line.__chanid, IDUM_MOVESYNC, v)
    --else
    --    obj:send(IDUM_MOVESYNC, v)
    --end
end

function scene.movestop(obj, v)
    local s, line = _get_scene(obj)
    if line==nil then return end
    
    --if v.posx == obj.info.posx and
    --    v.posy == obj.info.posy then
    --    return
    --end

    local oid = obj.info.oid
    obj.info.posx = v.posx
    obj.info.posy = v.posy
    obj.scene_version = obj.scene_version+1
    obj.moving = false
    --local v = {
    --    oid = oid,
    --    posx = v.posx,
    --    posy = v.posy,
    --}
    shaco.trace(sfmt("scene %u:%u#%u movestop obj %u", s.__tpid, s.__uid, obj.lineid, oid))
    --if line.__chanid then
    --    obj:chan_publish(line.__chanid, IDUM_MOVESTOPSYNC, v)
    --else
    --    obj:send(IDUM_MOVESTOPSYNC, v)
    --end
end

local function _getobj(oid, objlist)
    for _, v in ipairs(objlist) do
        if v[1] == oid then
            return v
        end
    end
end

function scene.update(obj)
    local last_visibles = obj.scene_visibles
    local s, line = _get_scene(obj)
    if line==nil then 
        return 
    end
    local myoid = obj.info.oid
    local visibles = {}
    local adds = {}
    local updates = {}
    local objs = line.__objs
    for oid, o in pairs(objs) do
        if oid ~= myoid then
            visibles[#visibles+1] = {oid, o.scene_version}
            local old = _getobj(oid, last_visibles)
            if old then
                if old[2] ~= o.scene_version then
                    --updates[#updates+1] = o
                    updates[#updates+1] = {
                        oid=o.info.oid,
                        posx=o.info.posx,
                        posy=o.info.posy,
                        move=o.moving,
                    }
                end
            else
                --adds[#adds+1] = o 
                adds[#adds+1] = {
                    name = o.base.name,
                    tpltid = o.base.tpltid,
                    oid = o.info.oid,
                    posx = o.info.posx,
                    posy = o.info.posy,
                }
            end
        end
    end
    local dels = {}
    for _, v in ipairs(last_visibles) do
        if not _getobj(v[1], visibles) then
            dels[#dels+1] = v[1]
        end
    end
    obj.scene_visibles = visibles
    if #adds > 0 or 
        #updates > 0 or
        #dels > 0 then
        obj:send(IDUM_SCENEUPDATE,{adds=adds, updates=updates, dels=dels})
        shaco.trace("=========="..obj.base.name.."===============")
        shaco.trace(tbl(adds, "adds"))
        shaco.trace(tbl(updates, "updates"))
        shaco.trace(tbl(dels, "dels"))
    end
end

return scene
]]
