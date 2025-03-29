local u = require("utils")
local b = peripheral.find("blockReader")

local data = b.getBlockData()
local items = u.findTable(data, "Items")

print('Items: ' .. #items)

for index, value in ipairs(items) do
    if value.tag and value.tag.map then
        print('\n Map: '.. value.tag.map)
        local deco = value.tag.Decorations
        for i, v in ipairs(deco) do
            print('X: ' .. v.x .. ' Y: ' .. v.z)
        end
    end
end