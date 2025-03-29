
local ID = os.getComputerID()

local config = {}
if fs.exists('config/terminal.cfg') then
    local f = fs.open('config/terminal.cfg', 'r')
    config = textutils.unserialize(f.readAll())
    f.close()
else
    config.side = 'top'
    config.protocol = 'WRT'
    config.term_key = 'default'
    config.commands = {}
    local f = fs.open('config/terminal.cfg', 'w')
    f.write(textutils.serialize(config))
    f.close()
    print('Generated new config file, running with default settings.')
end

local functions = {}
for key, value in pairs(config.commands) do
    functions[key] = require(value)
end

while true do
    local msg = rednet.receive(config.protocol)
end