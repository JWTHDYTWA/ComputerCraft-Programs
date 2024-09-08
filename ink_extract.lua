-- Barrel can be replaced with any inventory block
local Barrel = peripheral.find('sophisticatedstorage:barrel')
local Router = peripheral.find('modularrouters:modular_router')

local nBarrel = peripheral.getName(Barrel)

------------
-- Config --
------------

local link = 'right' -- The side at which the redstone link to the Router is

local toTrack = {
    { 'irons_spellbooks:common_ink', 'Common' },
    { 'irons_spellbooks:uncommon_ink', 'Uncommon' },
    { 'irons_spellbooks:rare_ink', 'Rare' },
    { 'irons_spellbooks:epic_ink', 'Epic' },
    { 'irons_spellbooks:legendary_ink', 'Legendary' }
}
local toUpgrade = { -- Pairs of some Ink (4) and a reagent (1)
    { 'irons_spellbooks:common_ink', 'minecraft:copper_ingot' },
    { 'irons_spellbooks:uncommon_ink', 'minecraft:iron_ingot' },
    { 'irons_spellbooks:rare_ink', 'minecraft:gold_ingot' },
    { 'irons_spellbooks:epic_ink', 'minecraft:amethyst_shard' },
}

local modes = { 'Auto', 'Recycle', 'Upgrade' } -- Used for the buttons
local colorMap = { -- Dictionary of aliases to colors
    Idle = colors.lightGray,
    Recycle = colors.yellow,
    Upgrade = colors.lightBlue,
    Auto = colors.lime,
    Common = colors.lightGray,
    Uncommon = colors.green,
    Rare = colors.lightBlue,
    Epic = colors.purple,
    Legendary = colors.orange
}

local bottleMin = 64
local bottleGood = 512

-------------
-- Globals --
-------------

local operation = 'Idle'
local mode = 'Auto'
local buttons = {}

-------------------------
-- Primitive Functions --
-------------------------

local function getItems()
    return Barrel.list()
end

-- local function getItemsNBT()
--     return Reader.getBlockData().storageWrapper.contents.inventory.Items
-- end

local function pulse(len)
    redstone.setOutput(link, true)
    sleep(len)
    redstone.setOutput(link, false)
    sleep(0.2)
end

local function pulses(len, times)
    for i = 1, times do
        pulse(len)
    end
end

local function findItem(id)
    local Items = getItems()
    for key, value in pairs(Items) do
        if value.name == id then
            return key
        end
    end
end

local function getCount(id)
    local Items = getItems()
    local count = 0
    for key, value in pairs(Items) do
        if value.name == id then -- id
            count = count + value.count
        end
    end
    return count
end

local function switchMode()
    for index, value in ipairs(modes) do
        if mode == value then
            mode = modes[index + 1] or modes[1]
            return mode
        end
    end
    mode = modes[1]
    return mode
end

local function suspend()
    mode = 'Idle'
end

-- The chosen colors will remain after the function is called
local function write(text, x, y, col, bgcol)
    if x and y then term.setCursorPos(x, y) end
    if col then term.setTextColor(col) end
    if bgcol then term.setBackgroundColor(bgcol) end
    term.write(text)
end

---------------------------
-- Application Functions --
---------------------------

-- Dev tips:
-- pullItems(fromName, fromSlot [, limit [, toSlot]])
-- pushItems(toName, fromSlot [, limit [, toSlot]])

local function pullSpell()
    local spell = findItem('irons_spellbooks:scroll')
    if not spell then return false end
    Router.pullItems(nBarrel, spell)
    pulse(0.2)
    return true
end

local function pushInk()
    local bottle = findItem('minecraft:glass_bottle')
    if not bottle then return false end
    Router.pullItems(nBarrel, bottle, 1)
    pulse(0.2)
    local received = Router.getItemDetail(1).name
    if received == 'minecraft:potion' then
        pulse(0.2)
    end
    repeat until Router.pushItems(nBarrel, 1) == 1
    return true
end

--------------------
-- Core functions --
--------------------

local function recycleSpell()
    if not pullSpell() then return false end
    operation = 'Recycle'
    sleep(6)
    repeat until pushInk()
    operation = 'Idle'
    return true
end

local function upgradeInk()
    for index, value in ipairs(toUpgrade) do
        local ink = getCount(value[1])
        local reagent = getCount(value[2])
        if ink > 3 and reagent > 0 then
            operation = 'Upgrade'
            for i = 1, 4 do
                if Router.pullItems(nBarrel, findItem(value[1]), 1) == 0 then
                    error('The ink is gone, figure it out')
                end
                pulse(0.2)
                if Router.pushItems(nBarrel, 1) == 0 then
                    error('The Barrel is full')
                end
            end
            Router.pullItems(nBarrel, findItem(value[2]), 1)
            pulse(0.2)
            sleep(6)
            repeat until Router.pullItems(nBarrel, findItem('minecraft:glass_bottle'), 1) == 1
            pulse(0.2)
            repeat until Router.pushItems(nBarrel, 1) == 1
            operation = 'Idle'
            return true
        end
    end
    return false
end

local function renderScreen()
    local Counts = {}
    for index, value in ipairs(toTrack) do
        Counts[value[1]] = getCount(value[1])
    end
    Counts.Scrolls = getCount('irons_spellbooks:scroll')
    Counts.Bottles = getCount('minecraft:glass_bottle')
    local bottleStatus = colors.red
    if Counts.Bottles >= bottleMin then
        if Counts.Bottles >= bottleGood then
            bottleStatus = colors.green
        else
            bottleStatus = colors.yellow
        end
    end
    term.clear()
    -- Title
    write('Iron\'s Spells and Spellbooks: ', 2, 2, colors.lightGray)
    write('Ink Factory', nil, nil, colors.magenta)
    -- Operation
    write('Operation: ', 24, 4, colors.lightGray)
    write(operation, nil, nil, colorMap[operation])
    -- Mode
    write('Mode: ', 24, 6, colors.lightGray)
    local lb, tb = term.getCursorPos()
    write(' ' .. mode .. ' ', nil, nil, colors.black, colorMap[mode])
    term.setBackgroundColor(colors.black)
    local rb = term.getCursorPos()
    buttons.mode = { l = lb, t = tb, r = rb, b = tb, lmb = switchMode, rmb = suspend }
    -- Statistics
    for index, value in ipairs(toTrack) do
        write(value[2] .. ':', 2, 3 + index, colorMap[value[2]])
        write(Counts[value[1]], 14, 3 + index)
    end
    write('Bottles:', 2, 10, colors.white)
    write(Counts.Bottles, 12, 10, bottleStatus)
    write('Scrolls:', 2, 11, colors.yellow)
    write(Counts.Scrolls, 12, 11)
end

-------------
-- Threads --
-------------

local function threadMain()
    while true do
        if mode == 'Auto' then
            local ___ = recycleSpell() or upgradeInk()
        elseif mode == 'Recycle' then
            recycleSpell()
        elseif mode == 'Upgrade' then
            upgradeInk()
        end
        sleep(0.05)
    end
end

local function threadRender()
    while true do
        renderScreen()
        sleep(0.1)
    end
end

local function threadInput()
    while true do
        local event, side, x, y = os.pullEvent()
        if event == 'mouse_click' then
            for key, value in pairs(buttons) do
                if x >= value.l and y >= value.t and x <= value.r and y <= value.b then
                    if side == 1 and value.lmb then
                        value.lmb()
                        renderScreen()
                        break
                    elseif side == 2 and value.rmb then
                        value.rmb()
                        renderScreen()
                        break
                    end
                end
            end
        end
    end
end

-----------------
-- Entry point --
-----------------

parallel.waitForAll(threadMain, threadRender, threadInput)