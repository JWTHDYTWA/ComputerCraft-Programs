
local args = { ... }
if not args[1] then
    args[1] = 'left'
end
if not args[2] then
    local tmp = args[1]:lower()
    if tmp == 'right' then
        args[2] = 'back'
    else
        args[2] = 'right'
    end
end

local tank = peripheral.wrap( args[1] )
local target = peripheral.wrap( args[2] )

while true do
    local tank_t = tank.tanks()[1]
    local target_t = target.tanks()[1]
    if target_t then
        if target_t.amount < 5000 then
            tank.pushFluid(args[2], 5000 - target_t.amount, 'minecraft:lava')
        elseif target_t.amount > 5000 then
            tank.pullFluid(args[2], target_t.amount - 5000, 'minecraft:lava')
        end
    end
    sleep(1)
end