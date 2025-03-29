
local detector = peripheral.find('playerDetector')
local MAX_X, MAX_Y = term.getSize()
local scan_delay = tonumber(arg[1]) or 5

-- Configuration
local title = 'Multidimensional Tracker by JWTHDYTWA'
local dim_col = {
    ["OVERWORLD"] = colors.lime,
    ["THE_NETHER"] = colors.red,
    ["THE_END"] = colors.purple,
    ["VOID"] = colors.lightBlue,
    ["COMPACT_WORLD"] = colors.cyan,
    ["TWILIGHT_FOREST"] = colors.green }
local p_name, p_hp, p_x, p_z, p_y = 2, MAX_X - 34, MAX_X - 23, MAX_X - 15, MAX_X - 7
local SMALL_SCREEN = MAX_X < 32
if SMALL_SCREEN then
    p_hp, p_x, p_z, p_y = 18, 2, 10, 18
end
local WINDOW_START = 4  -- Начальная координата Y
local WINDOW_SIZE = 16  -- Размер окна
local WINDOW_END = WINDOW_START + WINDOW_SIZE - 1

-- Globals
local reg_buffer, error_buffer = {}, {}, {}
local sem_render = false
local scroll_offset, ln = 0, 0
local players_count = 0

local function cPrint(text, color)
    local _col = term.getTextColor()
    term.setTextColor(color)
    term.write(text)
    term.setTextColor(_col)
end

local function borderedPrint(text, color, line)
    if line >= WINDOW_START and line <= WINDOW_END then
        cPrint(text, color)
    end
end

local function thread_tracker()
    while true do
        local list = detector.getOnlinePlayers()
        local registry = {}
        local error_registry = {}

        for i, player_name in ipairs(list) do
            if not pcall(function()
                    local raw = detector.getPlayer(player_name)
                    -- Remove dimension modname prefix using regex
                    local dim = raw.dimension:gsub('%w+:', ''):upper()
                    local entry = { (#player_name > 12) and string.format('%.9s...', player_name) or player_name,
                        string.format('%d/%d', raw.health, raw.maxHealth),
                        raw.x,
                        raw.z,
                        raw.y }

                    if not registry[dim] then
                        registry[dim] = { entry }
                    else
                        table.insert(registry[dim], entry)
                    end
                end) then
                table.insert(error_registry, player_name)
            end
        end

        reg_buffer = registry
        error_buffer = error_registry
        players_count = #list
        sem_render = true
        sleep(scan_delay)
    end
end

local function thread_render()
    while true do
        if sem_render then
            term.clear()
            term.setCursorPos(2, 2)
            cPrint(title, colors.blue)

            ln = WINDOW_START + scroll_offset
            for dimension, players in pairs(reg_buffer) do
                term.setCursorPos(2, ln)
                borderedPrint(dimension, dim_col[dimension] or colors.yellow, ln)
                ln = ln + 1

                term.setCursorPos(p_name, ln)
                borderedPrint('Name', colors.orange, ln)
                term.setCursorPos(p_hp, ln)
                borderedPrint('HP', colors.red, ln)
                if SMALL_SCREEN then ln = ln + 1 end
                term.setCursorPos(p_x, ln)
                borderedPrint('X', colors.orange, ln)
                term.setCursorPos(p_z, ln)
                borderedPrint('Z', colors.orange, ln)
                term.setCursorPos(p_y, ln)
                borderedPrint('Y', colors.orange, ln)
                ln = ln + 1

                for i, v in ipairs(players) do
                    term.setCursorPos(p_name, ln)
                    borderedPrint(v[1], (i % 2 == 0) and colors.lightGray or colors.white, ln)
                    term.setCursorPos(p_hp, ln)
                    borderedPrint(v[2], (i % 2 == 0) and colors.lightGray or colors.white, ln)
                    if SMALL_SCREEN then ln = ln + 1 end
                    term.setCursorPos(p_x, ln)
                    borderedPrint(v[3], (i % 2 == 0) and colors.lightGray or colors.white, ln)
                    term.setCursorPos(p_z, ln)
                    borderedPrint(v[4], (i % 2 == 0) and colors.lightGray or colors.white, ln)
                    term.setCursorPos(p_y, ln)
                    borderedPrint(v[5], (i % 2 == 0) and colors.lightGray or colors.white, ln)
                    ln = ln + 1
                end

                -- Add a separator between dimensions
                ln = ln + 1
            end

            if #error_buffer > 0 then
                ln = ln + 1
                term.setCursorPos(2, ln)
                borderedPrint('\nNOT FOUND', colors.red, ln)
                for _, value in ipairs(error_buffer) do
                    ln = ln + 1
                    term.setCursorPos(2, ln)
                    borderedPrint(value, colors.gray, ln)
                end
            end
            sem_render = false
        end
        sleep(0.1)
    end
end

local function thread_input()
    while true do
        local event, a1, a2, a3, a4 = os.pullEvent()
        -- a1 = scroll direction
        if event == 'mouse_scroll' then
            scroll_offset = scroll_offset - a1
            if scroll_offset > 0 then scroll_offset = 0 end
            local max_scroll = -(((SMALL_SCREEN) and (players_count * 2) or (players_count)) + (#reg_buffer * 2) + #error_buffer + 4)
            if scroll_offset < max_scroll then scroll_offset = max_scroll end
            sem_render = true
        end
    end
end

parallel.waitForAny(thread_tracker, thread_render, thread_input)