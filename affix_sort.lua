local u = require("utils")
local gl = require("gl")
local firstrun = false

if u.version < '0.2.0' then
    error('Requires utils 0.2.0 or newer')
end
if gl.version < '0.1.0' then
    error('Requires gl 0.1.0 or newer')
end

--#region Config
local config
if fs.exists('affix_sort.config') then
    local f = fs.open('affix_sort.config', 'r')
    config = textutils.unserialize(f.readAll())
    f.close()
else
    local f = fs.open('affix_sort.config', 'w')
    f.write([[
{
    -- Input inventory name
    input = 'minecraft:barrel_0',
    -- Match inventory name
    match = 'minecraft:barrel_1',
    -- Mismatch inventory name
    mismatch = nil,
    -- Gem match inventory name
    gem_match = nil,
    -- Gem mismatch inventory name
    gem_mismatch = nil
    -- Junk inventory name
    junk = nil
}
]])
    f.close()
    firstrun = true
    print('Created affix_sort.config, edit it before running.')
end
--#endregion

--#region Rarities
local rarities
if fs.exists('rarities') then
    local f = fs.open('rarities', "r")
    rarities = textutils.unserialize(f.readAll())
    f.close()
else
    local f = fs.open('rarities', "w")
    f.write([[
{
    -- Available rarities:
    -- apotheosis:common, apotheosis:uncommon, apotheosis:rare,
    -- apotheosis:epic, apotheosis:mythic, apotheosis:ancient,
    -- apotheotic_additions:artifact
    gems = {
        'apotheosis:epic',
        'apotheosis:mythic',
        'apotheosis:ancient',
        'apotheotic_additions:artifact'
    },
    gear = {
        'apotheosis:ancient',
        'apotheotic_additions:artifact'
    }
}
]])
    f.close()
    print('Created "rarities" filter file, edit it before running.')
    firstrun = true
end
--#endregion

--#region Junk
local junk
if fs.exists('junk') then
    local f = fs.open('junk', "r")
    junk = textutils.unserialize(f.readAll())
    f.close()
else
    local f = fs.open('junk', "w")
    f.write([[
{
    -- Accepts patterns
    -- Junk filters:
    id = {
        -- Example: 'minecraft:leather_[%w_]+'
    },
    tag = {
        -- Not implemented due to peripheral constraints
    }
}
]])
    f.close()
    print('Created "junk" filter file, edit it before running.')
    firstrun = true
end
--#endregion

if firstrun then
    return
end

--#region Initialization

local input = peripheral.wrap(config.input)
local reader = peripheral.find('blockReader')

if not (input) then
    error(
        'Input inventory is required.\n' ..
        'Check peripheral list with <peripherals> command\n' ..
        'and edit affix_sort.config.\n' ..
        '!!! Input, Match and Mismatch inventories must be\n' ..
        'connected to the common Modem network,\n' ..
        'not directly to the computer !!!')
end

if not (reader) then
    error(
        'Block Reader peripheral is missing.\n'
    )
end

--#endregion

--#region Rendering

local rarityColors = {
    common = colors.lightGray,
    uncommon = colors.lime,
    rare = colors.lightBlue,
    epic = colors.purple,
    mythic = colors.orange,
    ancient = colors.yellow,
    artifact = colors.brown
}
term.setPaletteColour(colors.brown, 0xE9976A)
local gearRPairs = { sub = {}, col = {} }
local gemRPairs = { sub = {}, col = {} }
for index, value in ipairs(rarities.gear) do
    local _sub = string.gsub(value, '^.+:', '')
    table.insert(gearRPairs.sub, _sub)
    table.insert(gearRPairs.col, rarityColors[gearRPairs.sub[index]] or colors.white)
end
for index, value in ipairs(rarities.gems) do
    local _sub = string.gsub(value, '^.+:', '')
    table.insert(gemRPairs.sub, _sub)
    table.insert(gemRPairs.col, rarityColors[gemRPairs.sub[index]] or colors.white)
end

local function render(al_l, al_t, al_r, al_b)
    term.clear()
    gl.fastWrite(al_l, al_t, 'Affix Sort by JWTHDYTWA', colors.lightBlue)
    local x, y = al_l, al_t + 2
    local lastX, lastY
    if config.match or config.mismatch then
        gl.fastWrite(x, y, 'Matching gear rarity:', colors.white)
        lastX, lastY = gl.fastSequentialWrite(x, y + 1, al_r, al_b, gearRPairs.sub, gearRPairs.col, {}, ', ')
        y = lastY + 2
    end
    if config.gem_match or config.gem_mismatch then
        gl.fastWrite(x, y, 'Matching gem rarity:', colors.white)
        gl.fastSequentialWrite(x, y + 1, al_r, al_b, gemRPairs.sub, gemRPairs.col, {}, ', ')
    end
end

--#endregion

render(2, 2, term.getSize())
while true do
    local data = reader.getBlockData()
    local items = data.Items or data.storageWrapper.contents.inventory.Items
    for key, value in pairs(items) do
        if value.tag and value.tag.affix_data then
            if value.tag.gem then
                if u.contains(rarities.gems, value.tag.affix_data.rarity) then
                    if config.gem_match then
                        input.pushItems(config.gem_match, value.Slot + 1, 64)
                    end
                else
                    if config.gem_mismatch then
                        input.pushItems(config.gem_mismatch, value.Slot + 1, 64)
                    end
                end
            else
                if u.contains(rarities.gear, value.tag.affix_data.rarity) then
                    if config.match then
                        input.pushItems(config.match, value.Slot + 1, 64)
                    end
                else
                    if config.mismatch then
                        input.pushItems(config.mismatch, value.Slot + 1, 64)
                    end
                end
            end
        else
            if config.junk then
                if u.matchPatternFromTable(junk.id, value.id) then
                    input.pushItems(config.junk, value.Slot + 1, 64)
                end
            end
        end
    end
    sleep(0.05)
end