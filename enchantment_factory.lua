-- Enchantment Factory v1.0 --

local utils = require('utils')
local gl = require('gl')
local inv = require('inventory')
local com = require('cc.completion')

------------
-- Config --
------------

local config
if fs.exists('config/ench') then
    config = utils.load('config/ench')
else
    utils.saveRaw('config/ench',
        '{\n' ..
        '    storage = "minecraft:barrel_1",\n' ..
        '    inserter = "modularrouters:modular_router_1",\n' ..
        '    -- Redstone control over inserter is on left\n' ..
        '    -- Redstone control over activator is on right\n' ..
        '    dropper = "modularrouters:modular_router_3",\n' ..
        '    -- Redstone control over dropper is on back\n' ..
        '    -- Route redstone using some Redstone Links\n' ..
        '    applicator = "industrialforegoing:enchantment_applicator_0"\n' ..
        '    extractor = "industrialforegoing:enchantment_extractor_0"\n' ..
        '}')
    print('Created config/ench, you should edit it before running this program again.')
    return
end

local storage = peripheral.wrap(config.storage)
local inserter = peripheral.wrap(config.inserter)
local dropper = peripheral.wrap(config.dropper)
local applicator = peripheral.wrap(config.applicator)
local extractor = peripheral.wrap(config.extractor)
if not (storage and inserter and dropper and applicator and extractor) then
    error('Some peripherals are missing. Checks your config file.')
end
local maxX, maxY = term.getSize()

-------------
-- Globals --
-------------

-- GUI
local gui = 1  -- 1: Select book, 2: Select an action to do with book
local cursors = { book = 1, action = 1, enhance = 1, level = 1, item = 1 }
local glX, glY = 1, 1
local coordinates = {}
local bounds = {}
local printMode = 0
-- Items
local books = {}
local items = {}
local itemNames = {}
local itemMap = {}
local bookSelected = 0
local actionSelected = 0
-- Thread synchronization
local semUpdate = true -- Non-blocking
local semRender = true
local queRender = false -- Blocking
local semDrawLevel = true
local semDrawItem = true
-- Status
local enhancementStatus = 0
local enhancementLevel = 0

-------------
-- Objects --
-------------

local actions = { 'Enhance', 'Copy' }

---------------
-- Functions --
---------------

local function condBrackets(x, y, str, bool, brackets, space, color1, color2)
    if bool then
        x, y = gl.fastWrite(x, y, string.sub(brackets,1,1), color2)
        x = space and x + 1 or x
    else
        x = x + 1
    end
    x, y = gl.fastWrite(x, y, str, color1)
    if bool then
        x = space and x + 1 or x
        gl.fastWrite(x, y, string.sub(brackets,2,2), color2)
    end
    return x + 2, y
end

local function mkBounds(l, t, r, b)
    return { l = l, t = t, r = r, b = b }
end

local function ensBounds(bounds, x, y)
    return x >= bounds.l and x <= bounds.r and y >= bounds.t and y <= bounds.b
end

local function drawInteface()
    if semRender then
        term.clear()
        gl.fastWrite(2, 2, 'Enchantment Factory', colors.purple)
        if gui == 1 then
            gl.fastWrite(2, 4, 'Select Enchanted Book:', colors.yellow)
            for index, value in ipairs(books) do
                glX, glY = 2, 5 + index
                condBrackets(glX, glY, value.display, index == cursors.book, '[]', false, colors.magenta, colors.lime)
            end
        elseif gui == 2 then
            gl.fastWrite(2, 4, 'Select an action:', colors.yellow)
            glX, glY = 2, 6
            for index, value in ipairs(actions) do
                glX, glY = condBrackets(glX, glY, value, index == cursors.action, '[]', false, colors.magenta, colors.orange)
            end
        elseif gui == 3 and actionSelected == 1 then
            glX, glY = gl.fastWrite(2, 4, 'Desired level:', colors.lime)
            coordinates.level = { x = glX + 2, y = glY }
            if semDrawLevel then
                condBrackets(glX + 2, glY, tostring(cursors.level), cursors.enhance == 1, '<>', true, colors.magenta, colors.lime)
            end
            glX, glY = gl.fastWrite(2, 6, 'Item medium:', colors.lime)
            coordinates.item = { x = glX + 2, y = glY }
            if semDrawItem then
                condBrackets(glX + 2, glY, tostring(itemNames[cursors.item]), cursors.enhance == 2, '<>', true, colors.yellow, colors.orange)
            end
            glX, glY = condBrackets(3, 8, 'Start', cursors.enhance == 3, '[]', false, colors.yellow, colors.orange)
        end
    end
end

local function pulseInserter()
    redstone.setOutput('left', true)
    sleep(0.1)
    redstone.setOutput('left', false)
    sleep(0.1)
end

local function pulseActivator()
    redstone.setOutput('right', true)
    sleep(0.1)
    redstone.setOutput('right', false)
    sleep(0.1)
end

local function toggleDropper(bool)
    redstone.setOutput('back', bool)
end

local function enhanceBook(bookSlot, mediumSlot, level)
    local initialLevel = bookSelected.level
    local currentLevel = bookSelected.level

    while currentLevel < level do
        if currentLevel == initialLevel then
            local mediumDelivered = inv.transferEnsured(storage, inserter, 1, 10, true, mediumSlot, 1)
            if mediumDelivered ~= 1 then return false end
            local bookDelivered = inv.transferEnsured(storage, dropper, 1, 10, true, bookSlot, 1)
            if bookDelivered ~= 1 then
                if inv.transferEnsured(inserter, storage, 1, 10, true, 1, nil) ~= 1 then
                    error('Operation aborted and failed to return medium.')
                end
            end
        else
            
        end

        -- Pulsing inserter to insert medium
        pulseInserter()

        -- Toggling dropper to drop book
        toggleDropper(true)
        sleep(0.5)

        -- Pulsing activator to start enchanting
        pulseActivator()

        -- Waiting for enchanter to read the book
        sleep(2)

        -- Toggling dropper to pick up book
        toggleDropper(false)
        sleep(0.5)
        inv.transferEnsured(dropper, applicator, 1, 10, true, 1, 4)

        local enchantingWd = os.startTimer(120)
        parallel.waitForAny(function()
            while true do
                local event, id = os.pullEvent('timer')
                if id == enchantingWd then
                    error('Enchanting timed out.')
                    break
                end
            end
        end, function()
            local mediumReturned = 0
            while mediumReturned == 0 do
                pulseInserter()
                mediumReturned = inv.transferEnsured(inserter, applicator, 1, 10, true, 1, 3)
            end
        end)
        os.cancelTimer(enchantingWd)

        sleep(5)
        
    end


end

-------------
-- Threads --
-------------

local function threadRender() -- Done
    while true do
        if queRender then
            drawInteface()
            queRender = false
        end
        sleep(0.01)
    end
end

local function threadMain() -- Much to do
    while true do
        local event, a1, a2, a3 = os.pullEventRaw()
        if gui == 1 then -- Select book
            if event == 'key' then
                if a1 == keys.up then
                    cursors.book = cursors.book <= 1 and #books or cursors.book - 1
                elseif a1 == keys.down then
                    cursors.book = cursors.book >= #books and 1 or cursors.book + 1
                elseif a1 == keys.enter then
                    bookSelected = books[cursors.book]
                    gui = 2
                end
            end
        elseif gui == 2 then -- Select an action
            if event == 'key' then
                if a1 == keys.left then
                    cursors.action = cursors.action <= 1 and #actions or cursors.action - 1
                elseif a1 == keys.right then
                    cursors.action = cursors.action >= #actions and 1 or cursors.action + 1
                elseif a1 == keys.enter then
                    actionSelected = cursors.action
                    gui = 3
                elseif a1 == keys.backspace then
                    gui = 1
                end
            end
        elseif gui == 3 and actionSelected == 1 then -- Enhance
            if event == 'key' then
                if a1 == keys.up then
                    cursors.enhance = cursors.enhance <= 1 and 3 or cursors.enhance - 1
                elseif a1 == keys.down then
                    cursors.enhance = cursors.enhance >= 3 and 1 or cursors.enhance + 1
                elseif a1 == keys.left then
                    if cursors.enhance == 1 then
                        cursors.level = cursors.level <= 1 and 1 or cursors.level - 1
                    elseif cursors.enhance == 2 then
                        cursors.item = cursors.item <= 1 and #items or cursors.item - 1
                    end
                elseif a1 == keys.right then
                    if cursors.enhance == 1 then
                        cursors.level = cursors.level + 1
                    elseif cursors.enhance == 2 then
                        cursors.item = cursors.item >= #items and 1 or cursors.item + 1
                    end
                elseif a1 == keys.enter then
                    if cursors.enhance == 1 then
                        semDrawLevel = false
                        queRender = true
                        sleep(0.1)
                        semRender = false
                        term.setCursorPos(coordinates.level.x, coordinates.level.y)
                        cursors.level = tonumber(read(nil, nil, nil, tostring(cursors.level))) or 1
                        semDrawLevel = true
                        semRender = true
                    elseif cursors.enhance == 2 then
                        semDrawItem = false
                        queRender = true
                        sleep(0.1)
                        semRender = false
                        term.setCursorPos(coordinates.item.x, coordinates.item.y)
                        cursors.item = tonumber(itemMap[read(
                            nil, nil,
                            function (t)
                                return com.choice(t, itemNames)
                            end)]) or cursors.item
                        semDrawItem = true
                        semRender = true
                    elseif cursors.enhance == 3 then
                        actionSelected = cursors.enhance
                        gui = 3
                    end
                elseif a1 == keys.backspace then
                    gui = 2
                end
            end
        end

        if event == 'key' then
            queRender = true
        end
    end
end

local function threadUpdate() -- Done
    while true do
        if semUpdate then
            local booksTmp = {}
            local itemsTmp = {}
            local fail = false
            for index, value in pairs(storage.list()) do
                if value.name == 'minecraft:enchanted_book' then
                    local detail = storage.getItemDetail(index)
                    if not detail then
                        fail = true
                        break
                    end
                    local display = detail.enchantments[1].displayName
                    for i = 2, #detail.enchantments do
                        display = display .. ' + ' .. detail.enchantments[i].displayName
                    end
                    table.insert(booksTmp, {slot = index, enchantments = detail.enchantments, display = display})
                else
                    local detail = storage.getItemDetail(index)
                    local display = detail.displayName
                    table.insert(itemsTmp, {slot = index, display = display})
                end
            end
            if not fail and not (utils.similar(books, booksTmp) and utils.similar(items, itemsTmp)) then
                books = booksTmp
                items = itemsTmp
                itemNames = {}
                itemMap = {}
                for i2, v2 in ipairs(items) do
                    table.insert(itemNames, v2.display)
                    itemMap[v2.display] = i2
                end
                queRender = true
            end
        end
        os.sleep(0.2)
    end
end

----------
-- Main --
----------

parallel.waitForAny(threadRender, threadMain, threadUpdate)