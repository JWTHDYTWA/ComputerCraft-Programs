local valid_sides = {
    'top', 'bottom', 'left', 'right', 'back', 'front'
}

local compressor, side
for i, value in ipairs(valid_sides) do
    local p = peripheral.wrap(value)
    if p and peripheral.getType(p):match('pneumaticcraft:[%w_]+compressor') then
        compressor = p
        side = value
        break
    end
end
if not compressor then
    error('No compatible machines found!')
end

local max_pressure = tonumber(arg[1]) or compressor.getDangerPressure() - 1

-- Display
term.clear()
term.setCursorPos(2,2)
term.setTextColor(colors.lime)
term.write('Pressure control system')

term.setCursorPos(2,4)
term.setTextColor(colors.lightBlue)
print('Max pressure: ' .. max_pressure)
term.setTextColor(colors.white)

-- Work loop
while true do
    local pressure = compressor.getPressure()
    if pressure < max_pressure then
        redstone.setOutput(side, true)
    else
        redstone.setOutput(side, false)
    end
    sleep(0.05)
end