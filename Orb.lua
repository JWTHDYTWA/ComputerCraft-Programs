-- #region VARIABLES AND WRAPS --

local orb = peripheral.find('powah:energizing_orb')
local orbName = peripheral.getName(orb)

local storage = peripheral.find('minecraft:barrel')
local storageName = peripheral.getName(storage)

local maxX, maxY = term.getSize()
local button1_x, button1_y = maxX-4, 2    -- Switch button position
local button1_width, button1_height = 3, 2   -- Switch button size
local semaphoreRender = true
local enabled = true

local systemMessage = ""

local recipes = {
    ["powah:steel_energized"] = {
        {"minecraft:iron_ingot", 1},
        {"minecraft:gold_ingot", 1}
    },
    ["powah:blazing_crystal"] = {{"minecraft:blaze_rod", 1}},
    ["powah:niotic_crystal"] = {{"minecraft:diamond", 1}},
    ["powah:spirited_crystal"] = {{"minecraft:emerald", 1}},
    ["powah:nitro_crystal"] = {
        {"minecraft:redstone_block", 2},
        {"powah:blazing_crystal_block", 1},
        {"minecraft:nether_star", 1}
    },
    ["powah:uraninite"] = {{"powah:uraninite_raw", 1}}
}

--#endregion

-- #region FUNCTIONS --

local function write(text, x, y, col, bgcol)
    if x and y then term.setCursorPos(x, y) end
    if col then term.setTextColor(col) end
    if bgcol then term.setBackgroundColor(bgcol) end
    term.write(text)
end

local function orbIsEmpty()
    for i = 2, 7, 1 do
        if orb.getItemDetail(i) then
            return false
        end
    end
    return true
end

local function getStock()
    local temp = {}
    for key, value in pairs(storage.list()) do
        if temp[value.name] then
            temp[value.name] = temp[value.name] + value.count
        else
            temp[value.name] = value.count
        end
    end
    -- print(textutils.serialize(temp))
    return temp
end

local function sendItem(name, amount)
    for key, value in pairs(storage.list()) do
        if value.name == name then
            -- print('Items to send: ' .. amount)
            amount = amount - storage.pushItems(orbName, key, amount)
            if amount == 0 then
                return true
            end
        end
    end
end

local function processRecipe()
    local stock = getStock()
    for item, recipe in pairs(recipes) do
        local isAvailable = true
        for i, ingredient in ipairs(recipe) do
            if stock[ingredient[1]] then
                if stock[ingredient[1]] < ingredient[2] then
                    isAvailable = false
                    break
                end
            else
                isAvailable = false
                break
            end
        end
        if isAvailable then
            systemMessage = "Attempting to craft" .. item
            semaphoreRender = true

            for i, ingredient in ipairs(recipe) do
                sendItem(ingredient[1], ingredient[2])
            end
            return true
        end
    end

    systemMessage = "No recipes available"
    semaphoreRender = true
    return false
end

--#endregion

-- #region THREADS --

local function process()
    while true do
        -- Output
        if orb.getItemDetail(1) then
            orb.pushItems(storageName, 1)
        end
        -- Input (if enabled)
        if enabled and orbIsEmpty() then
            processRecipe()
        end
        -- Delay
        sleep(0.5)
    end
end

local function render()
    while true do
        if semaphoreRender then
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            term.clear()

            write('Orb Processing Program', 2,2, colors.orange)
            write('By JWTHDYTWA', 2,3, colors.lightGray)
            write('Toggle:', maxX-12,2)
            write('[E]', maxX-12,3, colors.yellow)
            write(systemMessage, 2,5, colors.white)
            
            term.setBackgroundColor(enabled and colors.red or colors.gray)
            paintutils.drawFilledBox(button1_x, button1_y, button1_x + 2, button1_y + 1)

            semaphoreRender = false
        end
        sleep(0.1)
    end
end

function event_handling()
    while true do
        local event, a, b, c = os.pullEvent()
        -- a = mouse button, b = x coordinate, c = y coordinate
        if event == 'mouse_click' and b >= button1_x and b <= button1_x+button1_width-1 and c >= button1_y and c <= button1_y+button1_height-1 and a == 1 then
            local event_second, mbs, cxs, cys = os.pullEvent('mouse_up')
            if cxs >= button1_x and cxs <= button1_x+button1_width-1 and cys >= button1_y and cys <= button1_y+button1_height-1 and a == 1 then
                enabled = not enabled
                semaphoreRender = true
            end
        -- a = key
        elseif event == 'key' and a == keys.e then
            enabled = not enabled
            semaphoreRender = true
        end
    end
end
--#endregion

-- #region Entry --

-- Draw UI
term.clear()
-- paintutils.drawBox(1,1,maxX,maxY,colors.gray)
-- term.setBackgroundColor(colors.black)
-- term.setCursorPos(3,3)
-- term.setTextColor(colors.lime)
-- term.write('Orb Conveyor')
-- term.setCursorPos(3,5)
-- term.setTextColor(colors.lightGray)
-- term.write('It will push items from the left inventory\'s')
-- term.setCursorPos(3,6)
-- term.write('first 6 slots in parallel as long as all the')
-- term.setCursorPos(3,7)
-- term.write('input slots are empty.')
-- term.setCursorPos(3,9)
-- term.write('It will also extract output items into the')
-- term.setCursorPos(3,10)
-- term.write('right inventory.')
-- term.setCursorPos(8,12)
-- term.write('Enable')
-- term.setCursorPos(8,13)
-- term.write('switch')

parallel.waitForAny(process, render, event_handling)
--#endregion