-- #region VARIABLES AND WRAPS --

local sphere = peripheral.wrap('top')
local maxX, maxY = term.getSize()
local B1PosX, B1PosY = 4, 12    -- Switch button position
local B1SizeX, B1SizeY = 3, 2   -- Switch button size
local enabled = true
--#endregion

-- #region FUNCTIONS --

local function check()
    if sphere.getItemDetail(2)
    or sphere.getItemDetail(3)
    or sphere.getItemDetail(4)
    or sphere.getItemDetail(5)
    or sphere.getItemDetail(6)
    or sphere.getItemDetail(7) then
        return true
    end
end
--#endregion

-- #region THREADS --

local function process()
    while true do
        -- Output
        if sphere.getItemDetail(1) then
            sphere.pushItems('right', 1)
        end
        -- Input (if enabled)
        if enabled and not check() then
            sphere.pullItems('left', 1, 1)
            sphere.pullItems('left', 2, 1)
            sphere.pullItems('left', 3, 1)
            sphere.pullItems('left', 4, 1)
            sphere.pullItems('left', 5, 1)
            sphere.pullItems('left', 6, 1)
        end
        -- Delay
        -- sleep(0.1)
    end
end

local function gui()
    while true do
        -- Draw button
        term.setBackgroundColor(enabled and colors.red or colors.gray)
        paintutils.drawFilledBox(B1PosX, B1PosY, B1PosX+2, B1PosY+1)
        -- RETURNS: "mouse_click", button, x, y
        local event, mb, cx, cy = os.pullEvent()
        if event == 'mouse_click' and cx >= B1PosX and cx <= B1PosX+B1SizeX-1 and cy >= B1PosY and cy <= B1PosY+B1SizeY-1 and mb == 1 then
            local event_second, mbs, cxs, cys = os.pullEvent('mouse_up')
            if cxs >= B1PosX and cxs <= B1PosX+B1SizeX-1 and cys >= B1PosY and cys <= B1PosY+B1SizeY-1 and mb == 1 then
                enabled = not enabled
            end
        elseif event == 'key' and mb == keys.e then
            enabled = not enabled
        end
    end
end
--#endregion

-- #region Entry --

-- Check for valid set-up
local L, R = peripheral.wrap('left'), peripheral.wrap('right')
if not (L and R and sphere) then
    error('Left inventory, right inventory or/and Energizing Orb not found')
elseif not (L.pushItems and R.pullItems and sphere.pullItems) then
    error('Left inventory, right inventory or/and Energizing Orb not found')
end
L, R = nil, nil

-- Draw UI
term.clear()
paintutils.drawBox(1,1,maxX,maxY,colors.gray)
term.setBackgroundColor(colors.black)
term.setCursorPos(3,3)
term.setTextColor(colors.lime)
term.write('Orb Conveyor')
term.setCursorPos(3,5)
term.setTextColor(colors.lightGray)
term.write('It will push items from the left inventory\'s')
term.setCursorPos(3,6)
term.write('first 6 slots in parallel as long as all the')
term.setCursorPos(3,7)
term.write('input slots are empty.')
term.setCursorPos(3,9)
term.write('It will also extract output items into the')
term.setCursorPos(3,10)
term.write('right inventory.')
term.setCursorPos(8,12)
term.write('Enable')
term.setCursorPos(8,13)
term.write('switch')

sleep(1)
parallel.waitForAny(process, gui)
--#endregion