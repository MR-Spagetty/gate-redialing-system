local comp = require('component')
local sides = require('sides')
local event = require('event')
os = require("os")
local sg = comp.stargate
local rs = comp.redstone
local serialization = require('serialization')
sg.disengageGate()
rs.setOutput(sides.posy, 0)
gateAddress = {}
processingLoop = true
event.listen("interrupted", function() processingLoop = false end)
gateOpened = event.listen("stargate_open", function (nam, add, call, me)
    if me then
        gateAddress = serialization.unserialize(sg.dialedAddress:gsub(", ", "\",\""):gsub("%[", "{\""):gsub("%]", "\"}"))
    end
end)

function dial()
    rs.setOutput(sides.posy, 0)
    print("Dialing")
    for i,v in ipairs(gateAddress) do print(i,v) end
    print()
    loop = true
    function dialNext(dialed)
        glyph = gateAddress[dialed + 1]
        print("Engaging "..glyph.."... ")
        sg.engageSymbol(glyph)
    end
    function cancelEvents()
        event.cancel(eventEngaged)
        event.cancel(openEvent)
        event.cancel(failEvent)
        print("Cancelled all event listeners")
        loop = false
    end
    eventEngaged = event.listen("stargate_spin_chevron_engaged", function(evname, add, caller, num, lock, glyph)
        os.sleep(0.5)
        if lock then
            print("Engaging...")
            sg.engageGate()
        else
            dialNext(num)
        end
    end)
    dialNext(0)
    openEvent = event.listen("stargate_open", function()
        print("Stargate opened successfully")
        cancelEvents()
    end)
    failEvent = event.listen("stargate_failed", function()
        print("Stargate failed to open")
        cancelEvents()
    end)
    while loop do os.sleep(0.1) end
end
event.pull('stargate_wormhole_closed_fully')
rs.setOutput(sides.posy, 15)
function checkNDial(nam, add, side, old, new)
    if new > 0 and sg.getGateStatus() == "idle" and gateAddress then
        dial()
    end
end
gateClose = event.listen("stargate_wormhole_closed_fully", function()
    if gateAddress then
        rs.setOutput(sides.posy, 15)
    end
end)
while processingLoop do
    local nam, add, side, old, new = event.pull('redstone_changed')
    checkNDial(nam, add, side, old, new)
end
event.cancel(gateClose)
event.cancel(gateOpened)
event.cancel(eventEngaged)
event.cancel(openEvent)
event.cancel(failEvent)
print("Cancelled all event listeners")