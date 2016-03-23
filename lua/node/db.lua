local shaco = require "shaco"
local sfmt = string.format
local mysql = require "mysql"
local REQ = require "req"
REQ.__REG {
    "h_game"
}

local conn

local function fini_db()
    conn:close()
end

local function ping()
    while true do
        conn:ping()
        shaco.info("gamedb ping")
        shaco.sleep(1800*1000)
    end
end

shaco.start(function()
    shaco.dispatch("um", function(source, session, name, v)
        local h = REQ[name]
        if h then
            h(conn, source, session, v)
        else
            shaco.warn(sfmt("db recv invalid msg %s", name))
        end
    end)    
--    shaco.uniquemodule("game", false)
    conn = assert(mysql.connect{
        host = shaco.getenv("gamedb_host"), 
        port = shaco.getenv("gamedb_port"),
        db = shaco.getenv("gamedb_name"), 
        user = shaco.getenv("gamedb_user"), 
        passwd = shaco.getenv("gamedb_passwd"),
    })
    shaco.info("gamedb connect ok")
--    shaco.publish("db")  
    shaco.fork(ping)
end)
