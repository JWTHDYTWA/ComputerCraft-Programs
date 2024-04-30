local utils = require('utils')
local args = utils.argParse(...)
args.delay = args.delay or 5

local detector = peripheral.find('playerDetector')

local function cPrint(text, color)
    local _col = term.getTextColor()
    term.setTextColor(color)
    print(text)
    term.setTextColor(_col)
end

while true do
    local list = detector.getOnlinePlayers()
    local registry = {}
    local error_registry = {}
    for key, value in pairs(list) do
        if not pcall(function ()
            local raw = detector.getPlayerPos(value)
            local dim = raw.dimension:gsub('%w+:', '')
            local entry = {value .. '  ', raw.x, raw.z, raw.y}
            local col
            if key % 2 == 0 then
                col = colors.lightGray
            else
                col = colors.white
            end
            if not registry[dim] then
                registry[dim] = { col, entry }
            else
                table.insert(registry[dim], col)
                table.insert(registry[dim], entry)
            end
        end) then
            table.insert(error_registry, value)
        end
    end

    term.clear()
    term.setCursorPos(1,2)
    cPrint(string.format('Tracking all online players, delay=%d:', args.delay), colors.yellow)
    for key, value in pairs(registry) do
        cPrint('\n' .. string.upper(key), colors.magenta)
        textutils.tabulate(
            colors.orange, {'Name', 'X', 'Z', 'Y'},
            table.unpack(value)
        )
    end
    if #error_registry > 0 then
        cPrint('\nNOT FOUND', colors.red)
        print(table.concat(error_registry, '\n'))
    end
    sleep(args.delay)
end