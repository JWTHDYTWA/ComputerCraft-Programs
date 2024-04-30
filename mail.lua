local u = require('utils')
local c = require('chatboxlib')
local p = require('playerDetector')

local queue = {}

local model = {

    mail = {

        send = function(sender, receiver, ...)
            local args = { ... }
            local anon = nil
            if args[1] == '-a' then
                anon = true
                table.remove(args, 1)
            end
            for index, value in ipairs(args) do
                args[index] = tostring(value)
            end
            local message = table.concat(args, ' ')
            local mailbox = fs.open('mailbox.json', 'r')
            local json = textutils.unserialiseJSON(mailbox.readAll())
            mailbox.close()
            local uid = os.epoch('utc')
            local read = u.contains(p.getOnlinePlayers(), receiver)

            if read then
                local notification = {
                    { text = 'Message from ' },
                    { text = anon and 'Anonymous' or sender, color = anon and 'gray' or 'aqua' },
                    { text = ':\n' },
                    {
                        text = message,
                        color = 'gray',
                        clickEvent = { action = 'copy_to_clipboard', value = message },
                        hoverEvent = { action = 'show_text', contents = 'Click to copy' }
                    },
                    { text = '\n' },
                    {
                        text = '[Delete]',
                        color = 'red',
                        clickEvent = { action = 'suggest_command', value = '$mail delete ' .. uid },
                        hoverEvent = { action = 'show_text', contents = uid }
                    }
                }
                if not anon then
                    table.insert(notification,
                        {
                            text = ' '
                        })
                    table.insert(notification,
                        {
                            text = '[Reply]',
                            color = 'blue',
                            clickEvent = { action = 'suggest_command', value = '$mail send ' .. sender .. ' ' },
                            hoverEvent = { action = 'show_text', contents = uid }
                        })
                end
                table.insert(queue, { { username = receiver, prefix = 'J-Mail' }, notification })
            end

            -- Sends a notification to the sender
            local notificationToSender = {
                { text = anon and 'You sent an anonymous message to ' or 'You sent a message to ' },
                { text = receiver,                                                                color = 'gold' },
                { text = ':\n' },
                { text = message,                                                                 color = 'gray' },
                { text = '\n' },
                {
                    text = '[Delete]',
                    color = 'red',
                    clickEvent = { action = 'suggest_command', value = '$mail delete ' .. uid },
                    hoverEvent = { action = 'show_text', contents = uid }
                }
            }
            if not read then
                table.insert(notificationToSender, 3, { text = ' (Offline)', color = 'dark_gray' })
            end
            table.insert(queue, { { username = sender, prefix = 'J-Mail' }, notificationToSender })

            -- Saves the mailbox database with the new message
            table.insert(json,
                { uid = uid, anon = anon, sender = sender, receiver = receiver, message = message, read = read })
            mailbox = fs.open('mailbox.json', 'w')
            mailbox.write(textutils.serialiseJSON(json))
            mailbox.close()
        end,

        box = function(user)
            local mailbox = fs.open('mailbox.json', 'r')
            local json = textutils.unserialiseJSON(mailbox.readAll())
            mailbox.close()

            local message = {}
            for index, value in ipairs(json) do
                if value.sender == user or value.receiver == user then
                    table.insert(message, {
                        text = value.anon and value.sender ~= user and 'Anonymous' or value.sender,
                        color = value.anon and 'gray' or 'aqua'
                    })
                    table.insert(message, {
                        text = ' -> ',
                    })
                    table.insert(message, {
                        text = value.receiver,
                        color = 'gold'
                    })
                    table.insert(message, {
                        text = ':\n'
                    })
                    table.insert(message, {
                        text = value.message,
                        color = 'gray',
                        clickEvent = { action = 'copy_to_clipboard', value = value.message },
                        hoverEvent = { action = 'show_text', contents = 'Click to copy' }
                    })
                    table.insert(message, {
                        text = '\n'
                    })
                    table.insert(message, {
                        text = '[Delete]',
                        color = 'red',
                        clickEvent = { action = 'suggest_command', value = '$mail delete ' .. value.uid },
                        hoverEvent = { action = 'show_text', contents = value.uid }
                    })
                    if value.receiver == user and not value.anon then
                        table.insert(message, {
                            text = ' '
                        })
                        table.insert(message, {
                            text = '[Reply]',
                            color = 'blue',
                            clickEvent = { action = 'suggest_command', value = '$mail send ' .. value.sender .. ' ' },
                            hoverEvent = { action = 'show_text', contents = 'Click to reply' }
                        })
                    end
                    if index ~= #json then
                        table.insert(message, {
                            text = '\n\n'
                        })
                    end
                    json[index].read = true
                end
            end

            if #message > 0 then
                table.insert(message, 1, { text = 'Your inbox:\n\n', color = 'yellow' })
            else
                table.insert(message, 1, { text = 'No messages', color = 'red' })
            end

            table.insert(queue, { { username = user, prefix = 'J-Mail' }, table.unpack(message) })
        end,

        clear = function(user)
            local mailbox = fs.open('mailbox.json', 'r')
            local json = textutils.unserialiseJSON(mailbox.readAll())
            mailbox.close()

            local newJson = {}
            for i, msg in ipairs(json) do
                if msg.sender ~= user and msg.receiver ~= user then
                    table.insert(newJson, msg)
                end
            end

            mailbox = fs.open('mailbox.json', 'w')
            mailbox.write(textutils.serialiseJSON(newJson))
            mailbox.close()
            table.insert(queue,
                { { username = user, prefix = 'J-Mail' }, { text = 'All your messages cleared', color = 'yellow' } })
        end,

        delete = function(user, uid)
            local mailbox = fs.open('mailbox.json', 'r')
            local messages = textutils.unserialiseJSON(mailbox.readAll())
            mailbox.close()

            local found = false
            for i, msg in ipairs(messages) do
                if msg.uid == uid and (msg.sender == user or msg.receiver == user) then
                    table.remove(messages, i)
                    found = true
                    break
                end
            end

            mailbox = fs.open('mailbox.json', 'w')
            mailbox.write(textutils.serialiseJSON(messages))
            mailbox.close()

            local message = found and { text = 'Message deleted', color = 'yellow' } or
            { text = 'Message not found', color = 'red' }
            table.insert(queue, { { username = user, prefix = 'J-Mail' }, message })
        end,

        help = function(user, broadcast)
            local notification = {
                { text = '- a simple mail bot\n' },
                { text = 'List of commands:\n' },
                {
                    text = '[Send Message]',
                    color = 'green',
                    clickEvent = { action = 'suggest_command', value = '$mail send ' },
                    hoverEvent = { action = 'show_text', contents = 'Click to send a message' }
                },
                { text = ' - send a message. Syntax: $mail send <receiver> <message>\n' },
                {
                    text = '[Check Mailbox]',
                    color = 'yellow',
                    clickEvent = { action = 'suggest_command', value = '$mail box' },
                    hoverEvent = { action = 'show_text', contents = 'Click to check your messages' }

                },
                { text = ' - check your messages.\n' },
                {
                    text = '[Help]',
                    color = 'aqua',
                    clickEvent = { action = 'suggest_command', value = '$mail help' },
                    hoverEvent = { action = 'show_text', contents = 'Click to see this menu' }

                },
                { text = ' - shows this menu.' }, }
            if broadcast == 'broadcast' then
                table.insert(queue, { { prefix = 'J-Mail' }, notification })
            else
                table.insert(queue, { { username = user, prefix = 'J-Mail' }, notification })
            end
        end,

        admin = {

            markEverythingRead = function()
                local mailbox = fs.open('mailbox.json', 'r')
                local json = textutils.unserialiseJSON(mailbox.readAll())
                mailbox.close()

                local newJson = {}
                for index, value in ipairs(json) do
                    value.read = true
                    table.insert(newJson, value)
                end

                mailbox = fs.open('mailbox.json', 'w')
                mailbox.write(textutils.serialiseJSON(newJson))
                mailbox.close()
            end

        }

    }

}

local unreadMessages = function (user)
    local mailbox = fs.open('mailbox.json', 'r')
    local json = textutils.unserialiseJSON(mailbox.readAll())
    mailbox.close()

    local newMessages = 0
    for i, msg in ipairs(json) do
        if msg.receiver == user and not msg.read then
            newMessages = newMessages + 1
        end
    end
    return newMessages
end

local playerJoined = function (user)
    local msgCount = unreadMessages(user)
    if unreadMessages(user) > 0 then
        local message = {
            { text = 'You have ' },
            { text = tostring(msgCount), color = 'yellow' },
            { text = ' new messages.\n' },
            {
                text = '[Check]',
                color = 'blue',
                clickEvent = { action = 'suggest_command', value = '$mail box' }
            }
        }
        table.insert(queue, { {username = user, prefix = 'J-Mail'}, table.unpack(message) })
    end
end

-- Main function
local main = function ()
    if not fs.exists('mailbox.json') then
        local mailbox = fs.open('mailbox.json', 'w')
        mailbox.writeLine('{}')
        mailbox.close()
    end
    while true do
        c.run(model, playerJoined)
    end
end

-- Solution to the problem of the formattedSend going on cooldown after sending a message.
local queueProcess = function ()
    while true do
        if #queue > 0 then
            local msg = table.remove(queue, 1)
            if msg[1].username then
                repeat
                    local result = c.formattedSend(table.unpack(msg))
                    sleep(0.5)
                until not result
            else
                repeat
                    local result = c.formattedBroadcast(table.unpack(msg))
                    sleep(0.5)
                until not result
            end
        else
            sleep(0.1)
        end
    end
end

parallel.waitForAll(queueProcess, main)