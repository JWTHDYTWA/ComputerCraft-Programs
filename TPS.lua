local args = {...}
local chat = peripheral.find("chatBox")
local json = fs.open("form.json","r")
local raw = json.readAll()

local MEASURE = 5
if #args > 0 then
    MEASURE = tonumber(args[1])
end

local measure = function()
    chat.sendMessage("Starting measuring...","Probe")
    local stamp = os.epoch("utc")
    sleep(MEASURE)
    local sec = (os.epoch("utc") - stamp) / 1000
    
    local tps = MEASURE / sec * 20
    local color = "green"
    if tps < 15 then
        if tps < 10 then
            if tps < 5 then
                color = "red"
            else
                color = "gold"
            end
        else
            color = "yellow"
        end
    end
    
    local SUB = {tps = string.format("%.2f",tps), col = color}
    chat.sendFormattedMessage(string.gsub(raw,"%$(%w+)",SUB),"Probe")
end

term.clear()
term.setCursorPos(4,2)
term.setTextColor(colors.yellow)
term.write("TPS Probe Program")
term.setCursorPos(2,4)
term.setTextColor(colors.white)
term.write("Chat commands:")
term.setCursorPos(2,5)
term.setTextColor(colors.lightBlue)
term.write("!tps")
term.setTextColor(colors.lightGray)
term.write(" - get TPS probe")

while true do
    local event, player, msg = os.pullEvent("chat")
    if msg == "!tps" then
        measure()
    elseif msg == "!menu" then
        chat.sendFormattedMessage("[{\"text\":\"[Say Hello]\", \"color\": \"blue\", \"clickEvent\":{\"action\":\"run_command\", \"value\":\"Hello!\"}, \"hoverEvent\": {\"action\":\"show_text\", \"contents\":\"Hello!\"}}]")
    end
end