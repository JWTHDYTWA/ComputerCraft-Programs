local lib = {}
lib.version = '0.1.0'

lib.pull = function(from, to, amount, fromSlot, toSlot)
    return to.pullItems(peripheral.getName(from), fromSlot, amount, toSlot)
end

lib.push = function(from, to, amount, fromSlot, toSlot)
    return from.pushItems(peripheral.getName(to), fromSlot, amount, toSlot)
end

lib.transferEnsured = function(from, to, amount, timeout, pull, fromSlot, toSlot)
    local watchdog = os.startTimer(timeout)
    local transferred = 0
    
    function awaitTimer()
        while true do
            local event, id = os.pullEvent('timer')
            if id == watchdog then
                return false
            end
        end
    end
    
    function awaitTransfer()
        while transferred < amount do
            if pull then
                transferred = transferred + lib.pull(from, to, amount - transferred, fromSlot, toSlot)
            else
                transferred = transferred + lib.push(from, to, amount - transferred, fromSlot, toSlot)
            end
        end
    end
    
    parallel.waitForAny(awaitTimer, awaitTransfer)
    os.cancelTimer(watchdog)
    return transferred
end

return lib