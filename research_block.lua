local reader = peripheral.find('blockReader')

local data = reader.getBlockData()
local item
if data.item then
    item = data.item
elseif data.Items then
    item = data.Items[0]
else
    error("Reader target has no items")
end

local i = 1
while fs.exists('research/res_' .. i) do
    i = i + 1
end

local file = fs.open('research/res_' .. i, 'w')
file.write(textutils.serialise(item))
file.close()

local OC = term.getTextColor()
term.setTextColor(colors.yellow)
textutils.slowWrite('Research data saved as ')
term.setTextColor(colors.lime)
textutils.slowWrite('res_' .. i)
term.setTextColor(colors.yellow)
textutils.slowWrite(' in ')
term.setTextColor(colors.lime)
textutils.slowPrint('/research')
term.setTextColor(OC)