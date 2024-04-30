local utils = {}
utils.version = '0.3.0'

--#region String utils

-- Parses command line arguments into a table
-- Accepts args as a table or as separate arguments
-- Converts values to numbers/booleans if possible
-- Example: program range=64 delay=20
utils.argParse = function(args, ...)
    if type(args) ~= 'table' then
        args = { args, ... }
    end
    local map = {}
    for key, value in pairs(args) do
        local _eq = string.find(value, '=')
        if _eq then
            if _eq > 1 and _eq < #value then
                map[value:sub(1, _eq - 1)] = utils.auto(value:sub(_eq + 1, -1))
            end
        else
            table.insert(map, utils.auto(value))
        end
    end
    return map
end

-- Converts a string value to the possible type (number/bool > else)
utils.auto = function (val)
    return textutils.unserialize(val) or val
    --[[ Old implementation
    if val:match('^%d+$') or val:match('^%d+%.%d+$') then
        return tonumber(val)
    elseif val == 'true' or val == 'false' then
        return val == 'true' and true or false
    else
        return val
    end
    ]]
end

-- Returns a split string as a table, can accept custom separator
utils.split = function (str, sep)
    sep = sep or ' ';
    local t = {}
    for occ in str:gmatch('[^' .. sep .. ']+') do
        table.insert(t, occ)
    end
    return t
end

-- The same as split, but it automatically converts values
utils.autosplit = function (str, sep)
    local t = utils.split(str, sep)
    for key, value in pairs(t) do
        t[key] = utils.auto(value)
    end
    return t
end

-- Compare with multiple values
utils.cmp = function (obj, ...)
    local args = { ... }
    local match = false
    for key, value in pairs(args) do
        if obj == value then
            match = true
            break
        end
    end
    return match
end

--#endregion

--#region Table utils

-- Checks if the table contains exact value
utils.contains = function (tab, val)
    for key, value in pairs(tab) do
        if value == val then
            return key
        end
    end
    return nil
end

-- Checks two tables for identity
utils.tablesEqual = function (t1, t2)
    for key, value in pairs(t2) do
        if t1[key] ~= value or type(t1[key]) ~= value then
            return false
        end
    end
    return true
end

-- Checks if two values are similar, can be used for table comparison
utils.similar = function(t1, t2)
    if t1 == t2 then
        return true
    elseif type(t1) == "table" and type(t2) == "table" then
        if #t1 ~= #t2 then
            return false
        else
            for key, value in pairs(t1) do
                if not utils.similar(t1[key], t2[key]) then
                    return false
                end
            end
        end
    end
    return true
end

-- Checks if a value matches any pattern in a table, returns the key if found
utils.matchPatternFromTable = function(tab, val)
    for key, pattern in pairs(tab) do
        if string.find(val, pattern) then
            return key
        end
    end
    return nil
end

-- Finds a table in a table recursively, accepts multiple values to search for
utils.findTable = function(tab, ...)
    local val = {...}
    for key, value in pairs(tab) do
        if type(value) == "table" then
            if utils.contains(val, key) then
                return value
            else
                local found = utils.findTable(value, table.unpack(val))
                if found then
                    return found
                end
            end
        end
    end
end

--#endregion

-- Returns the current server TPS
utils.tps = function (time)
    local timestamp = os.epoch('utc')
    sleep(time)
    return 20 * time / ((os.epoch('utc') - timestamp) / 1000)
end

utils.between = function (x, min, max)
    return x >= min and x <= max
end

--#region File utils

-- Loads a file with given name and returns its data
utils.load = function (filename)
    if not fs.exists(filename) then
        error('File not found')
    end
    local file = fs.open(filename, 'r')
    local data = textutils.unserialize(file.readAll())
    file.close()
    return data
end

-- Saves a file with given name and data
utils.save = function (filename, data)
    local file = fs.open(filename, 'w')
    file.write(textutils.serialize(data))
    file.close()
end

-- Loads a file with given name and returns its data
utils.loadJson = function (filename)
    if not fs.exists(filename) then
        error('File not found')
    end
    local file = fs.open(filename, 'r')
    local data = textutils.unserializeJSON(file.readAll())
    file.close()
    return data
end

-- Saves a file with given name and data
utils.saveJson = function (filename, data)
    local file = fs.open(filename, 'w')
    file.write(textutils.serializeJSON(data))
    file.close()
end

utils.saveRaw = function (filename, data)
    local file = fs.open(filename, 'w')
    file.write(data)
    file.close()
end

--#endregion

return utils