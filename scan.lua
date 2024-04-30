local detector = peripheral.find('playerDetector')
local range = ...
if range then range = tonumber(range) end
if not range then range = 64 end

local found = detector.getPlayersInRange(range)

write('Players found in ')
term.setTextColor(colors.lightBlue)
write(range)
term.setTextColor(colors.white)
print(' blocks range:')
term.setTextColor(colors.orange)
print(table.concat(found, ', '))
term.setTextColor(colors.white)