local utils = require('utils')
local args = utils.argParse(...)
local machine

-- Finding compatible compressor if not specified
if args.s then
    machine = peripheral.wrap(args.s)
    if not (machine and machine.getPressure) then
        error('There is no compatible peripheral on the selected side!')
    end
else
    local directions = {
        'top',
        'bottom',
        'back',
        'front',
        'left',
        'right'
    }
    for index, value in ipairs(directions) do
        machine = peripheral.wrap(value)
        if machine and machine.getPressure then
            args.s = value
            break
        end
    end
    if not machine then
        error('No compatible machines found!')
    end
end

args.p = args.p or machine.getDangerPressure() - 1

-- Display
term.clear()
term.setCursorPos(2,2)
term.setTextColor(colors.lime)
term.write('Performing pressure control')
term.setCursorPos(2,3)
term.write('with following parameters:')

term.setCursorPos(2,5)
term.setTextColor(colors.orange)
print(' Side: ' .. args.s)

term.setCursorPos(2,6)
term.setTextColor(colors.lightBlue)
print(' Pressure setting: ' .. args.p)
term.setTextColor(colors.white)

-- Work loop
while true do
    local pressure = machine.getPressure()
    if pressure < args.p then
        redstone.setOutput(args.s, true)
    else
        redstone.setOutput(args.s, false)
    end
    sleep(0)
end