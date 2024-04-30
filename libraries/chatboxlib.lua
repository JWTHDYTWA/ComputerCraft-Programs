local utils = require('utils')

local lib = {}
lib.version = '1.0.0'

lib.chatbox = peripheral.find('chatBox')
lib.playerDetector = peripheral.find('playerDetector')
lib.properties = { debug = false }
lib.c = {
    {
        black = 'black',
        dark_blue = 'dark_blue',
        dark_green = 'dark_green',
        dark_aqua = 'dark_aqua',
        dark_red = 'dark_red',
        dark_purple = 'dark_purple',
        gold = 'gold',
        gray = 'gray',
        dark_gray = 'dark_gray',
        blue = 'blue',
        green = 'green',
        aqua = 'aqua',
        red = 'red',
        light_purple = 'light_purple',
        yellow = 'yellow',
        white = 'white'
    }
}

lib.validate = function ()
    if lib.chatbox == nil then
        error('No chatbox found')
    end
end

-- Just a shortcut to pull <chat> event
lib.read = function ()
    return os.pullEvent('chat')
end

-- Executes a command by looking it up in the provided model table.
-- tab: The model table containing command functions.
-- sender: The name of the sender who issued the command.
-- com: The command and arguments as a table.
lib.execute = function(tab, sender, com)
    for index, value in ipairs(com) do
        if type(tab[value]) == 'function' then
            if lib.properties.debug then
                print(index .. ' word: ' .. value .. ', function')
            end
            tab[value](sender, com, index)
            break
        elseif type(tab[value]) == 'table' then
            if lib.properties.debug then
                print(index .. ' word: ' .. value .. ', table')
            end
            tab = tab[value]
        else
            if lib.properties.debug then
                print(index .. ' word, not found')
            end
            break
        end
    end
end

-- Runs the chatbox event loop. Pulls chat events, parses the message into a command,
-- and executes the command by looking it up in the lib.model table.
-- callback: The callback function to call when a player joins the server.
lib.run = function(model, users, callback)
    -- arg1: User name (chat or playerJoin)
    -- arg2: Message (chat) or dimension (playerJoin)
    -- arg3: UUID (chat)
    -- arg4: Hidden (chat)
    local event, arg1, arg2, arg3, arg4 = os.pullEvent()
    if event == 'chat' then
        if type(users) == 'table' then
            if utils.contains(users, arg1) then
                lib.execute( model, arg1, utils.autosplit(arg2) )
            end
        else
            lib.execute( model, arg1, utils.autosplit(arg2) )
        end
    elseif event == 'playerJoin' then
        if type(callback) == 'function' then
            callback(arg1, arg2, arg3, arg4)
        end
    end
end

-- Broadcasts a message to all connected clients.
-- message: The message content to broadcast.
-- prefix: Optional prefix to prepend to the message.
-- brackets: Optional brackets to surround the prefix.
-- bracket_color: Optional color for the brackets.
lib.broadcast = function(message, prefix, brackets, bracket_color)
    lib.chatbox.sendMessage(message, prefix, brackets, bracket_color)
end

-- Broadcasts a message to all connected clients. Accepts multiple
-- arguments which can be strings or tables containing message formatting.
-- Strings are broadcast as plain text. Tables can specify color, formatting, etc.
lib.formattedBroadcast = function(parameters, ...)
    local args = { ... }
    local output = {}
    for index, value in ipairs(args) do
        if type(value) == 'string' then
            table.insert(output, { text = value })
        elseif type(value) == 'table' then
            table.insert(output, value)
        else
            table.insert(output, { text = tostring(value) })
        end
    end
    lib.chatbox.sendFormattedMessage(textutils.serialiseJSON(output), parameters.prefix, parameters.brackets, parameters.bracket_color)
end

-- Sends a formatted chat message to the given username.
-- Accepts message formatting parameters and message content as multiple arguments.
-- The message content can be strings or tables specifying formatting.
-- Serializes the message content to JSON and sends it formatted.
-- Requires the username parameter to be provided.
lib.formattedSend = function(parameters, ...)
    if not parameters.username then error('parameters.username is required.') end
    local args = { ... }
    local output = {}
    for index, value in ipairs(args) do
        if type(value) == 'string' then
            table.insert(output, { text = value })
        elseif type(value) == 'table' then
            table.insert(output, value)
        else
            table.insert(output, { text = tostring(value) })
        end
    end
    lib.chatbox.sendFormattedMessageToPlayer(textutils.serialiseJSON(output), parameters.username, parameters.prefix,
        parameters.brackets, parameters.bracket_color)
end

lib.send = function(message, username, prefix, brackets, bracket_color)
    lib.chatbox.sendMessageToPlayer(message, username, prefix, brackets, bracket_color)
end

return lib