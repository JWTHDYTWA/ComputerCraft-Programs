local side_tank = arg[1]
local side_redstone = arg[2]

if not (arg[1] and arg[2]) then
    term.setTextColor(colors.orange)
    print('Please specify operational sides:')
    term.setTextColor(colors.lightGray)
    term.write('> ')
    term.setTextColor(colors.yellow)
    print('boiler_control bottom top')
    term.setTextColor(colors.orange)
    term.write('where ')
    term.setTextColor(colors.yellow)
    term.write('bottom')
    term.setTextColor(colors.orange)
    print(' is the tank side')
    term.setTextColor(colors.orange)
    term.write('and ')
    term.setTextColor(colors.yellow)
    term.write('top')
    term.setTextColor(colors.orange)
    print(' is the redstone output side')
    return
end

local tank = peripheral.wrap(side_tank)

local capacity
local getLevel

if tank.getBufferFluidCapacity then
    capacity = tank.getBufferFluidCapacity()
    getLevel = tank.getBufferFluidFilledPercentage
elseif tank.tanks then
    capacity = tonumber(arg[3])
    getLevel = function()
        return tank.tanks()[1] and tank.tanks()[1].amount / capacity or 0
    end
else
    error('Compatible tank not found.')
end

local thMin, thMax = 0.2, 0.8
local barPos, barWidth = 2, 30

local render_sem = true
local hist = false
local level = 0

local function render()
    while true do
        if render_sem then
            local barFilled = math.floor(level * (barWidth+1) + 0.5)
            term.clear()

            term.setCursorPos(2,2)
            term.setTextColor(colors.lightBlue)
            term.write('[@]')

            term.setCursorPos(6,2)
            term.setTextColor(colors.lightGray)
            term.write('Boiler controller')
            

            paintutils.drawFilledBox(barPos, 6, barPos+barWidth, 7, colors.gray)
            if barFilled > 0 then
                paintutils.drawFilledBox(barPos, 6, barPos+barFilled-1, 7, colors.white)
            end
            term.setBackgroundColor(colors.black)

            paintutils.drawLine(barPos, 4, barPos+barWidth, 4, hist and colors.orange or colors.gray)
            term.setBackgroundColor(colors.black)

            term.setTextColor(colors.red)
            term.setCursorPos(barPos+thMin*30, 8)
            term.write('^')

            term.setTextColor(colors.lime)
            term.setCursorPos(barPos+thMax*30, 8)
            term.write('^')

            render_sem = false
        else
            sleep(0.5)
        end
    end
end

local function control()
    while true do
        level = getLevel()
        if not hist and level < thMin then
            redstone.setOutput(side_redstone, true)
            hist = true
        elseif hist and level >= thMax then
            redstone.setOutput(side_redstone, false)
            hist = false
        end
        render_sem = true
        sleep(0.5)
    end
end

parallel.waitForAny(render, control)