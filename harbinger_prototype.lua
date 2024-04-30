local utils = require('utils')
local chat = require('chatboxlib')

local side = arg[1] or 'top'
local trigger = utils.split('spawn harbinger')

term.clear()
term.setCursorPos(2,2)
term.setTextColor(colors.yellow)
term.write('Running Spawner control on')
term.setCursorPos(2,4)
term.setTextColor(colors.orange)
term.write('[spawn harbinger]')
term.setTextColor(colors.yellow)
term.write(' command...')

while true do
    local event, user, msg, uuid, hidden = chat.read()
    local command = utils.split(msg)
    if utils.table_eq(command, trigger) then
        chat.chatbox.sendMessageToPlayer("Spawning Harbinger in a moment...", user)
        redstone.setOutput(side, true)
        sleep(4)
        redstone.setOutput(side, false)
    end
end