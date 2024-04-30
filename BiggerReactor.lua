---@diagnostic disable: undefined-global, undefined-field
local R = peripheral.find("BiggerReactors_Reactor")
if not R then
    error("Reactor not found")
end
local B = R.battery()
local Hyst = false
local Flag = false

local THR1 = function()
    repeat
        local Fullness = 100 * B.stored() / B.capacity()
        if not Hyst then
            if Fullness < 10 then
                Hyst = true
            else
                R.setActive(false)
            end
        else
            if Fullness > 90 then
                Hyst = false
            else
                R.setActive(true)
            end
        end

        -- GUI
        term.clear()
        term.setCursorPos(2,2)
        term.write("Reactor battery: "..B.stored().."/"..B.capacity().." ("..math.floor(Fullness).."%)")
        term.setCursorPos(2,3)
        term.write("Generating: " .. B.producedLastTick())
        term.setCursorPos(2,5)
        term.write("Current state: "..(Hyst and "Charge" or "Discharge"))
        term.setCursorPos(2,7)
        term.write("Controls:")
        term.setCursorPos(2,8)
        term.write("F............................Flip state (10..90%)")
        term.setCursorPos(2,9)
        term.write("Backspace...................................Close")
        
        -- Delay
        sleep(0.1)
    until Flag
end

local THR2 = function()
    repeat
        local _, key, hold = os.pullEvent("key")
        if not hold then
            if key == keys.f then
                if Hyst then
                    Hyst = false
                else
                    Hyst = true
                end
            elseif key == keys.backspace then
                Flag = true
            end
        end
    until Flag
end

parallel.waitForAll(THR1,THR2)
R.setActive(false)
term.clear()
term.setCursorPos(1,1)