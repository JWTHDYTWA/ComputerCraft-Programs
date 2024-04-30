local chat = peripheral.find('chatBox')
local me = peripheral.find('meBridge')

local function displayItemAmount(name)
    local result = me.getItem({name = name})
    if result then
        local message = {
            {text = 'Found ' .. result.amount .. ' '},
            {text = '[' .. result.displayName .. ']', color = 'blue'}
        }
        chat.sendFormattedMessage(textutils.serialiseJSON(message), 'TechPerv ME')
    else
        local message = {
            {text = name .. ' is not found'}
        }
        chat.sendFormattedMessage(textutils.serialiseJSON(message), 'TechPerv ME')
    end
end

while true do
    local event, player, msg, uuid = os.pullEvent('chat')
    if string.sub(msg, 1, 3) == 'tp>' then
        displayItemAmount(string.gsub(string.sub(msg, 4, -1), ' ', ''))
    end
end