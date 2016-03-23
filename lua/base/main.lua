local shaco = require "shaco"

shaco.start(function()
    local db = assert(shaco.uniqueservice("db"))
    shaco.register("db", db)

    local logdb = assert(shaco.uniqueservice("dblog"))
    shaco.register("logdb", logdb)

    local billing = assert(shaco.uniqueservice("billing"))
    shaco.register("billing", billing)

    local game = assert(shaco.uniqueservice("game"))
    shaco.register("game", game)

    local gate = assert(shaco.uniqueservice("gate"))
    shaco.register("gate", gate)

    shaco.call(billing, 'lua', 'open', {
        address = assert(shaco.getenv("billinghost")),
        request_handle = game,
    })

    shaco.call(game, 'lua', 'open', {
        gate = gate,
        logdb = logdb,
        db = db,
    })

    shaco.call(gate, 'lua', 'open', {
        address=shaco.getenv("gateaddress"),
        request_handle=game,
        maxclient=tonumber(shaco.getenv("clientmax")), 
        livetime=tonumber(shaco.getenv("clientlive")), 
        rlimit=tonumber(shaco.getenv("clientrlimit")),
        slimit=tonumber(shaco.getenv("clientslimit"));
    })
end)
