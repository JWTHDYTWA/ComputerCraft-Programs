-- #region VARIABLES AND WRAPS --

-- Initialization of peripherals

local orb = peripheral.find('powah:energizing_orb')
local orbName = peripheral.getName(orb)

local storage
do
    local not_found = true
    for i, p_name in ipairs(peripheral.getNames()) do
        local check_1, check_2 = false, true
        storage = peripheral.wrap(p_name)
        for j, p_type in ipairs({peripheral.getType(storage)}) do
            if p_type == 'inventory' then check_1 = true end
            if p_type == 'powah:energizing_orb' then check_2 = false end
        end
        if check_1 and check_2 then
            not_found = false
            break
        end
    end
    if not_found then
        error('There is no compatible storage inventory!')
    end
end
local storageName = peripheral.getName(storage)

-- General variables

local maxX, maxY = term.getSize()
local button1_x, button1_y = maxX-4, 2    -- Switch button position
local button1_width, button1_height = 3, 2   -- Switch button size
local semaphore_render = true
local enabled = true
local current_recipe = 0

-- Recipes

local recipes = {
    { "powah:steel_energized", {
        {"minecraft:iron_ingot", 1},
        {"minecraft:gold_ingot", 1}
    }, "Energized Steel", colors.yellow},
    { "powah:blazing_crystal", {{"minecraft:blaze_rod", 1}}, "Blazing Crystal", colors.orange },
    { "powah:niotic_crystal", {{"minecraft:diamond", 1}}, "Niotic Crystal", colors.lightBlue },
    { "powah:spirited_crystal", {{"minecraft:emerald", 1}}, "Spirited Crystal", colors.lime },
    { "powah:nitro_crystal", {
        {"minecraft:redstone_block", 2},
        {"powah:blazing_crystal_block", 1},
        {"minecraft:nether_star", 1}
    }, "Nitro Crystal", colors.red},
    { "powah:uraninite", {{"powah:uraninite_raw", 1}}, "Uraninite", colors.green },
    { "powah:uraninite", {{"mekanism:ingot_uranium", 1}}, "Uraninite from Uranium", colors.green },
    { "powah:ender_core", {
        {"powah:capacitor_basic_tiny", 1},
        {"powah:dielectric_casing", 1},
        {"minecraft:ender_eye", 1}
    }, "Ender Core", colors.cyan}
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
    return temp
end

local function sendItem(name, amount)
    for key, value in pairs(storage.list()) do
        if value.name == name then
            amount = amount - storage.pushItems(orbName, key, amount)
            if amount == 0 then
                return true
            end
        end
    end
end

local function processRecipe()
    local stock = getStock()
    for i_recipe, recipe in ipairs(recipes) do
        local isAvailable = true
        for i, ingredient in ipairs(recipe[2]) do
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
            current_recipe = i_recipe
            semaphore_render = true

            for i, ingredient in ipairs(recipe[2]) do
                sendItem(ingredient[1], ingredient[2])
            end
            return true
        end
    end

    current_recipe = 0
    semaphore_render = true
    return false
end

local function render()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()

    write('Orb Processing Program', 2,2, colors.orange)
    write('By JWTHDYTWA', 2,3, colors.lightGray)
    write('Toggle:', maxX-12,2)
    write('[T]', maxX-12,3, colors.yellow)
    write('Available recipes:', 2,5, colors.white)
    for key, value in pairs(recipes) do
        write( (current_recipe == key and "+ " or "  ") .. value[3], 2, 6 + key, value[4])
    end
    
    term.setBackgroundColor(enabled and colors.red or colors.gray)
    paintutils.drawFilledBox(button1_x, button1_y, button1_x + 2, button1_y + 1)
end

--#endregion

-- #region THREADS --

local function thread_main()
    while true do
        -- Output
        if orb.pushItems(storageName, 1) > 0 then
            current_recipe = 0
        end
        -- Input (if enabled)
        if enabled and orbIsEmpty() then
            processRecipe()
            semaphore_render = true
        end
        -- Delay
        sleep(0.5)
    end
end

local function thread_render()
    while true do
        if semaphore_render then
            render()
            semaphore_render = false
        end
        sleep(0.1)
    end
end

local function thread_events()
    while true do
        local event, a, b, c = os.pullEvent()
        -- a = mouse button, b = x coordinate, c = y coordinate
        if event == 'mouse_click' and b >= button1_x and b < button1_x+button1_width and c >= button1_y and c < button1_y+button1_height and a == 1 then
            local event_second, mbs, cxs, cys = os.pullEvent('mouse_up')
            if cxs >= button1_x and cxs < button1_x+button1_width and cys >= button1_y and cys < button1_y+button1_height and a == 1 then
                enabled = not enabled
                semaphore_render = true
            end
        -- a = key
        elseif event == 'key' and a == keys.t then
            enabled = not enabled
            semaphore_render = true
        end
    end
end
--#endregion

-- #region Entry --

parallel.waitForAny(thread_main, thread_render, thread_events)
--#endregion