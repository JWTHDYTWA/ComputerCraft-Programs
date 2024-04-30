local input = peripheral.wrap('quark:variant_chest_2')
local output = peripheral.wrap('quark:variant_chest_3')
local reader = peripheral.wrap('blockReader_0')

if not (input and output and reader) then
    error('Some of peripheral not found')
end

local Items = reader.getBlockData().Items
for i, j in pairs(Items) do
    if j.tag then
        if j.tag.Affixes then
            input.pushItems('quark:variant_chest_3', i+1)
        end
    end
end