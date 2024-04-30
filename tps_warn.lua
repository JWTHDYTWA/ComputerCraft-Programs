local u = require('utils')
local chat = peripheral.find('chatBox')

while true do
    local measure = u.tps(10)
    if measure < 10 then
        local message = {
            {
                text = "The tps is currently "
            },
            {
                text = "10",
                color = measure < 5 and "red" or measure < 7.5 and "gold" or "yellow"
            },
            {
                text = ". If you have heavy machinery or farms, please optimize it."
            }
        }
        chat.sendFormattedMessage(textutils.serialiseJSON(message), 'Conscience')
    end
    sleep(300)
end