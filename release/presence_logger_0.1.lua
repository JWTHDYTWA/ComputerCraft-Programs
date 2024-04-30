-- Version 0.1.0

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

local function drawInteface(dat)
    term.clear()
    gl.fastWrite(2,2, 'Players registered:', colors.yellow)
    for index, value in ipairs(dat) do
        gl.fastSequentialWrite(2, 3 + index, xMax, yMax,
            { value[1], value[2] },
            { utils.contains(allies, value[1]) and colors.lime or colors.yellow, colors.lightGray },
            {}, ' - ')
    end
end

if not fs.exists('players') then
    utils.save('players', {})
end
local data = utils.load('players')

while true do
    local scanned = pd.getPlayersInRange(range)
    if #scanned > 0 then
        data = utils.load('players')

        for is, vs in ipairs(scanned) do
            local found = false
            for ir, vr in ipairs(data) do
                if vs == vr[1] then
                    found = true
                    data[ir][2] = 'UTC ' .. textutils.formatTime(os.time('utc'), true) .. ' ' .. os.date('%d.%m.%y')
                    break
                end
            end
            if not found then
                table.insert(data, { vs, 'UTC '.. textutils.formatTime(os.time('utc'), true) .. ' ' .. os.date('%d.%m.%y') })
            end
        end

        utils.save('players', data)
    end
    drawInteface(data)
    os.sleep(1)
end