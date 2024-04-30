local u = require('utils')
local c = require('chatboxlib')
c.validate()

--#region Configs
-- Users stores the list of users that can use the controller
-- It's a JSON array containing usernames
local users
if fs.exists('users.json') then
    users = u.loadJson('users.json')
    if type(users) ~= 'table' then
        error('Add at least one user to users.json')
    end
else
    u.saveRaw('users.json',
        '[\n'..
        '    "your_name"\n'..
        ']'
    )
    print('Created users.json, edit it to add users')
end

-- Map stores the mapping of user defined endpoints to their respective devices
-- It's a JSON object containing named objects:
-- "name": ["computer_or_adapter_name(see modem)", "side", "toggle|pulse|tff"]
local MAP
if fs.exists('map.json') then
    MAP = u.loadJson('map.json')
else
    MAP = {}
    u.saveRaw('map.json',
        '{\n'..
        '    "command_name": ["computer", "top", "toggle"]\n'..
        '}'
    )
    print('Created map.json, edit it to add points')
end
local function handles(map)
    for key, value in pairs(map) do
        if type(value[1]) == "string" then
            if value[1] == 'computer' then
                map[key][1] = redstone
            else
                map[key][1] = peripheral.wrap(value[1])
            end
        else
            handles(value)
        end
    end
end
handles(MAP)
--#endregion

local toggleController = {
    on = function (user, com, fi)
        local endpoint = MAP[com[1]]
        for i = 2, fi-1, 1 do
            endpoint = endpoint[com[i]]
        end
        endpoint[1].setOutput(endpoint[2], true)
    end,
    off = function (user, com, fi)
        local endpoint = MAP[com[1]]
        for i = 2, fi-1, 1 do
            endpoint = endpoint[com[i]]
        end
        endpoint[1].setOutput(endpoint[2], false)
    end,
    toggle = function (user, com, fi)
        local endpoint = MAP[com[1]]
        for i = 2, fi-1, 1 do
            endpoint = endpoint[com[i]]
        end
        if endpoint[1].getOutput(endpoint[2]) then
            endpoint[1].setOutput(endpoint[2], false)
        else
            endpoint[1].setOutput(endpoint[2], true)
        end
    end
}

local pulseController = {
    activate = function (user, com, fi)
        local endpoint = MAP[com[1]]
        for i = 2, fi-1, 1 do
            endpoint = endpoint[com[i]]
        end
        endpoint[1].setOutput(endpoint[2], true)
        sleep(0.2)
        endpoint[1].setOutput(endpoint[2], false)
    end
}

-- T-flipflop controller acts just like pulse controller, but it's supposed to be used with an analog T-flipflop outside of the computer
local tffController = {
    toggle = function (user, com, fi)
        local endpoint = MAP[com[1]]
        for i = 2, fi-1, 1 do
            endpoint = endpoint[com[i]]
        end
        endpoint[1].setOutput(endpoint[2], true)
        sleep(0.2)
        endpoint[1].setOutput(endpoint[2], false)
    end
}

local MODEL = {}

local function assembleModel(map, model, indent, name)
    if name ~= 'root' then
        print(indent .. name .. ':')
        indent = indent .. '  '
    end
    for key, value in pairs(map) do
        if value[3] == 'toggle' then
            model[key] = toggleController
            print(indent .. key..': Toggle')
        elseif value[3] == 'pulse' then
            model[key] = pulseController
            print(indent .. key..': Pulse')
        elseif value[3] == 'tff' then
            model[key] = tffController
            print(indent .. key..': T-flipflop')
        else
            model[key] = {}
            assembleModel(map[key], model[key], indent, key)
        end
    end
end

print('Commands for Toggle controller: toggle, on, off')
print('Commands for Pulse controller: activate')
print('Commands for T-flipflop controller: toggle\n')

-- Assign a controller to each user defined endpoint
assembleModel(MAP, MODEL, '  ', 'root')

c.properties.debug = false
while true do
    c.run(MODEL, users)
    sleep(0.05)
end