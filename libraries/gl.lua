local lib = {}
lib.properties = { states = {} }
lib.version = "0.1.0"

--#region Low-Level Functions

-- Saves the current cursor position, text color, and background color to the state stack
lib.saveState = function()
    local x, y = term.getCursorPos()
    local tc = term.getTextColor()
    local bc = term.getBackgroundColor()
    table.insert(lib.properties.states, { x = x, y = y, tc = tc, bc = bc })
end

-- Restores the cursor position, text color, and background color from the state stack.
-- Returns the state table if successful, or false if the state stack is empty.
lib.restoreState = function()
    local state = table.remove(lib.properties.states, #lib.properties.states)
    if not state then
        return false
    end
    term.setCursorPos(state.x, state.y)
    term.setTextColor(state.tc)
    term.setBackgroundColor(state.bc)
    return state
end

-- Fast version of write, does not return states to those before execution
-- Expected to be used sequentially with other "fast" functions between manual saveState and restoreState
lib.fastWrite = function (x, y, text, col, bcol)
    term.setCursorPos(x,y)
    term.setTextColor(col or colors.white)
    term.setBackgroundColor(bcol or colors.black)
    term.write(text)
    return term.getCursorPos()
end

lib.fastContinue = function (text, col, bcol)
    term.setTextColor(col or colors.white)
    term.setBackgroundColor(bcol or colors.black)
    term.write(text)
    return term.getCursorPos()
end

lib.fastSequentialWrite = function (x, y, xMax, yMax, strings, textcolors, bgcolors, sep, septc, sepbc)
    term.setCursorPos(x,y)
    for i, value in ipairs(strings) do
        local cX, cY = term.getCursorPos()
        if cX + #strings[i] + #sep > xMax then
            y = y + 1
            term.setCursorPos(x,y)
        end
        if y > yMax then
            break
        end
        term.setTextColor(textcolors[i] or colors.white)
        term.setBackgroundColor(bgcolors[i] or colors.black)
        term.write(strings[i])
        if i < #strings and sep then
            term.setTextColor(septc or colors.white)
            term.setBackgroundColor(sepbc or colors.black)
            term.write(sep)
        end
    end
    return term.getCursorPos()
end

lib.fastMultilineWrite = function (x, y, yMax, strings, textcolors, bgcolors, sep, septc, sepbc)
    for i, value in ipairs(strings) do
        if y - 1 + i > yMax then
            break
        end
        term.setCursorPos(x, y - 1 + i)
        term.setTextColor(textcolors[i] or colors.white)
        term.setBackgroundColor(bgcolors[i] or colors.black)
        term.write(value)
        if i < #strings and sep then
            term.setTextColor(septc or colors.white)
            term.setBackgroundColor(sepbc or colors.black)
            term.write(sep)
        end
    end
    return term.getCursorPos()
end

--#endregion

lib.box = function (left, top, right, bottom, col)
    local oldBC, oldX, oldY = term.getBackgroundColor(), term.getCursorPos()
    paintutils.drawBox(left,top,right,bottom,col)
    term.setBackgroundColor(oldBC)
    term.setCursorPos(oldX, oldY)
end

lib.filledBox = function (left, top, right, bottom, col)
    local oldBC, oldX, oldY = term.getBackgroundColor(), term.getCursorPos()
    paintutils.drawFilledBox(left,top,right,bottom,col)
    term.setBackgroundColor(oldBC)
    term.setCursorPos(oldX, oldY)
end

lib.write = function (x, y, text, color, bgcolor)
    local oldX, oldY = term.getCursorPos()
    local oldTC = term.getTextColor()
    local oldBC = term.getBackgroundColor()
    term.setCursorPos(x,y)
    term.setTextColor(col or colors.white)
    term.setBackgroundColor(bcol or oldBC)
    term.write(text)
    term.setCursorPos(oldX,oldY)
    term.setTextColor(oldTC)
    term.setBackgroundColor(oldBC)
end

return lib