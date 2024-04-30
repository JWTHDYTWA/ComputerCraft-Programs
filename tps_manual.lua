local u = require('utils')
local chat = peripheral.find('chatBox')

while true do
    local event, user, message, uuid, hidden = os.pullEvent('chat')
    if message == 'check tps' then
        local msr = u.tps(5)
        msr = msr > 20 and 20 or msr
        local asnwer = {
            {
                text = "Measured TPS: "
            },
            {
                text = string.format('%.2f', msr),
                color = msr > 19 and "aqua" or msr > 15 and 'green' or msr > 10 and 'yellow' or msr > 5 and 'gold' or 'red'
            }
        }
        chat.sendFormattedMessage(textutils.serialiseJSON(asnwer), 'J-Bot')
    end
end