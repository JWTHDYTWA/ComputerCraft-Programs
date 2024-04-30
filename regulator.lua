local meInterface = peripheral.find('ae2:cable_bus')
local chest = peripheral.find('enderchests:ender_chest.tile')

if not (meInterface and chest) then
    error('Both Ender Chest and ME Interface needed!')
end

term.setTextColor(colors.lightBlue)
print('[Interface regulation]')
term.setTextColor(colors.white)

while true do
    local chestStock = {}
    for key, value in pairs(chest.list()) do
        if not chestStock[value.name] then
            chestStock[value.name] = value.count
        else
            chestStock[value.name] = chestStock[value.name] + value.count
        end
    end
    if not pcall(function ()
        for key, value in pairs(meInterface.list()) do
            if (chestStock[value.name]) then
                meInterface.pushItems(peripheral.getName(chest), key, 64-chestStock[value.name])
            else
                meInterface.pushItems(peripheral.getName(chest), key)
            end
        end
    end) then
        meInterface = peripheral.find('ae2:cable_bus')
    end
    sleep(0.25)
end