-- Version 1.0.0

local utils = require('utils')
local gl = require('gl')
local pd = peripheral.find('playerDetector')
local xMax, yMax = term.getSize()

--#region Pre-checks
if gl.version < '0.1.0' then
    error('Wrong version of gl')
end
if not pd then
    error('No Player Detector found')
end
--#endregion

--#region Arguments
local range = arg[0] and tonumber(arg[0]) or 16
local allies = {}
for i = 2, #arg, 1 do
    table.insert(allies, arg[i])
end
--#endregion

--#region Variables
local cursor = 1
local semaphoreScan = true
local semaphoreRender = false
--#endregion

if not fs.exists('players') then
    utils.save('players', {})
end
local data = utils.load('players')

--#region Functions
local function drawInteface(dat)
    term.clear()
    local x, y
    gl.fastWrite(2,2, 'Security System', colors.green)
    gl.fastWrite(2,4, 'Players detected:', colors.lightGray)
    for index, value in ipairs(dat) do
        x, y = gl.fastSequentialWrite(2, 5 + index, xMax, yMax,
            { value[1], value[2] },
            { utils.contains(allies, value[1]) and colors.lime or colors.yellow, colors.lightGray },
            {}, ' - ')
        if index == cursor then
            gl.fastWrite(x, y, ' <<', colors.orange)
        end
    end
end

local function getTimeString()
    return 'UTC ' .. textutils.formatTime(os.time('utc'), true) .. ' ' .. os.date('%d.%m.%y')
end
--#endregion

--#region Threads
local threadScan = function()
    while true do
        if semaphoreScan then
            local scanned = pd.getPlayersInRange(range)
            if #scanned > 0 then
                data = utils.load('players')
                
                for is, vs in ipairs(scanned) do
                    local found = false
                    for ir, vr in ipairs(data) do
                        if vs == vr[1] then
                            found = true
                            data[ir][2] = getTimeString()
                            break
                        end
                    end
                    if not found then
                        table.insert(data,
                            { vs, getTimeString() })
                    end
                end
                
                utils.save('players', data)
                if #data < cursor then
                    cursor = #data
                end
                semaphoreRender = true
            end
        end
        os.sleep(1)
    end
end

local threadInput = function()
    local hotkeys = {
        [keys.up] = function()
            cursor = cursor == 1 and #data or cursor - 1
        end,
        [keys.down] = function()
            cursor = cursor == #data and 1 or cursor + 1
        end,
        [keys.delete] = function()
            semaphoreScan = false
            table.remove(data, cursor)
            utils.save('players', data)
            semaphoreScan = true
            if #data < cursor then
                cursor = #data
            end
        end
    }
    while true do
        local event, key, held = os.pullEvent('key')
        if hotkeys[key] and not held then
            hotkeys[key]()
            semaphoreRender = true
        end
    end
end

local threadRender = function()
    while true do
        if semaphoreRender then
            drawInteface(data)
            semaphoreRender = false
        end
        os.sleep(0.05)
    end
end
--#endregion

parallel.waitForAny(threadScan, threadInput, threadRender)