local side_tank = arg[1]
local side_redstone = arg[2]
local limit = arg[3]
local fluid = arg[4]

if not (arg[1] and arg[2] and arg[3]) then
    term.setTextColor(colors.orange)
    print('Syntax:')
    term.setTextColor(colors.white)
    print('tank_comparator bottom top 1000 minecraft:water')
    term.setTextColor(colors.lightGray)
    print('where')
    print('bottom : tank side')
    print('top : signal output side')
    print('1000 : expected tank capacity')
    print('[minecraft:water] : the fluid to observe')
    term.setTextColor(colors.white)
    return
end

local tank = peripheral.wrap(side_tank)

local capacity = tonumber(arg[3])

if not tank.tanks then
    error('Compatible tank not found.')
end

-- Interface
local barPosX, barPosY = 2, 6
local barWidth, barHeight = 30, 1

if fluid then barPosY = barPosY + 2 end
local indicatorPosY = barPosY - 2

local render_sem = true

-- Logic
local thMin, thMax = 0.5, 0.9
local hist = false
local level = 0

local function fluidAmount(fluid_name)
    local acc = 0
    for key, value in pairs(tank.tanks()) do
        if not fluid_name then
            acc = acc + value.amount
        elseif value.name == fluid then
            acc = acc + value.amount
        end
    end
    return acc
end

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
            term.write('Tank Comparator:')
            if fluid then
                term.setCursorPos(2,4)
                term.write(fluid)
            end
            

            paintutils.drawFilledBox(barPosX, barPosY, barPosX+barWidth, barPosY+barHeight, colors.gray)
            if barFilled > 0 then
                paintutils.drawFilledBox(barPosX, barPosY, barPosX+barFilled-1, barPosY+barHeight, colors.white)
            end
            term.setBackgroundColor(colors.black)

            paintutils.drawLine(barPosX, indicatorPosY, barPosX+barWidth, indicatorPosY, hist and colors.orange or colors.gray)
            term.setBackgroundColor(colors.black)

            term.setTextColor(colors.red)
            term.setCursorPos(barPosX+thMin*30, barPosY+barHeight+2)
            term.write('^')

            term.setTextColor(colors.lime)
            term.setCursorPos(barPosX+thMax*30, barPosY+barHeight+2)
            term.write('^')

            render_sem = false
        else
            sleep(0.5)
        end
    end
end

local function control()
    while true do
        level = fluidAmount(fluid) / capacity
        if level > 1 then level = 1 end
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