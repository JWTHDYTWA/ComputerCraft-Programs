local GL = require('JGraphicLib')
local expect = require('cc.expect')
local DW, DH = term.getSize();

_WindowStack = {}
_WindowProcedures = {}
_DESKTOP = { x = 1, y = 1, w = DW, h = DH }
nop = function () end
local lib = { element = {} }

-- #region < Window Procedures >

_WindowProcedures.add = function (w)
    table.insert(_WindowStack, w)
end

_WindowProcedures.remove = function (n)
    table.remove(_WindowStack, n)
end

_WindowProcedures.redraw = function ()
    term.clear()
    for k, v in pairs(_WindowStack) do
        v:draw()
    end
end

_WindowProcedures.process = function ()
    --[[
    Mouse events: p1 = mouse button, p2 = x, p3 = y
    Key events: p1 = key pressed
    Modem message: p1 = side, p2 = channel, p3 = reply channel, p4 = MESSAGE
    ]]
    _WindowProcedures.redraw()
    if #_WindowStack < 1 then
        return false
    end
    e1, p1, p2, p3, p4, p5 = os.pullEvent()
    if e1 == 'mouse_click' then
        for i = #_WindowStack, 1, -1 do
            if _WindowStack[i]:conj(p2,p3) then
                table.insert(_WindowStack, table.remove(_WindowStack, i))
                _WindowProcedures.redraw()
                for j = #_WindowStack[#_WindowStack].elements, 1, -1 do
                    if _WindowStack[#_WindowStack].elements[j].type == 'button' then
                        if _WindowStack[#_WindowStack].elements[j]:conj(p2,p3) then
                            local e2, mb, mx, my
                            repeat
                                e2, mb, mx, my = os.pullEvent('mouse_up')
                            until mb == p1
                            if _WindowStack[#_WindowStack].elements[j]:conj(mx,my) then
                                _WindowStack[#_WindowStack].elements[j].callback[p1]()
                            end
                            return true
                        end
                    elseif _WindowStack[#_WindowStack].elements[j].type == 'closeButton' then
                        local cx, cy = _WindowStack[#_WindowStack].elements[j]:getPos()
                        if p2 == cx and p3 == cy then
                            local e2, mb, mx, my
                            repeat
                                e2, mb, mx, my = os.pullEvent('mouse_up')
                            until mb == p1
                            if mx == cx and my == cy then
                                _WindowProcedures.remove(#_WindowStack)
                            end
                            return true
                        end
                    end
                end
                if _WindowStack[#_WindowStack]:hConj(p2,p3) and p1 == 1 then
                    local winX, winY = p2-_WindowStack[#_WindowStack].x, p3-_WindowStack[#_WindowStack].y
                    local e2, mb, mx, my
                    repeat
                        e2, mb, mx, my = os.pullEvent()
                        if mb == 1 and e2 == 'mouse_drag' then
                            _WindowStack[#_WindowStack].x = mx-winX
                            _WindowStack[#_WindowStack].y = my-winY
                            _WindowProcedures.redraw()
                        end
                    until mb == 1 and e2 == 'mouse_up'
                    return true
                end
                break
            end
        end
    end
    return true
end

-- #endregion

-- #region < Window Lib >

-- Window constructor
lib.window = function (name, posX, posY, width, height)
    --#region Expects
    expect.expect(1, name, 'string')
    expect.expect(2, posX, 'number')
    expect.expect(3, posY, 'number')
    expect.expect(4, width, 'number')
    expect.expect(5, height, 'number')
    --#endregion
    
    local class = {
        name = name,
        x = posX,
        y = posY,
        w = width,
        h = height,
        colors = { colors.lightGray, colors.gray, colors.black },
        elements = {},
        callsbacks = {}
    }
    
    -- Draws the window
    class.draw = function (self)
        GL.filledBox(self.x, (self.y + 1), (self.x + self.w - 1), (self.y + self.h - 1), self.colors[2]) -- Draws work area
        GL.filledBox(self.x, self.y, (self.x + self.w - 1), self.y, self.colors[1]) -- Draws header panel
        GL.write(self.name, self.x+1, self.y, self.colors[3], self.colors[1]) -- Draws header text
        for key, value in pairs(self.elements) do
            value:draw()
        end
    end

    -- Executes all the callback functions
    class.exec = function (self)
        for key, value in pairs(self.callbacks) do
            value()
        end
    end

    -- Adds an anonymous function to the callback list
    class.addCallback = function (self, callback)
        table.insert(self.callbacks, callback)
    end

    -- Adds an element to the window
    class.addElement = function (self, element)
        element.parent = self
        table.insert(self.elements, element)
    end

    -- Returns if the point is inside the window
    class.conj = function (self, x, y)
        return x >= self.x and y >= self.y and x < self.x + self.w and y < self.y + self.h
    end

    -- Returns if the point is in head panel
    class.hConj = function (self, x, y)
        return x >= self.x and y == self.y and x < self.x + self.w
    end

    -- Returns the finished window
    return class
end

-- Dialogue box constructor [TODO]
lib.showDialogue = function ()
    -- TODO
end

-- Exit button
lib.element.closeButton = function ()
    local class = {
        parent = _DESKTOP,
        type = 'closeButton'
    }

    class.getPos = function (self)
        local absR = self.parent.x + self.parent.w - 1
        local absT = self.parent.y
        return absR, absT
    end
    
    class.draw = function (self)
        local absR, absT = self:getPos()
        GL.write('X', absR, absT, colors.pink, colors.red)
    end

    return class
end

-- Button constructor
lib.element.button = function (text, posX, posY, width, height)
    --#region Expects
    expect.expect(1, text, 'string')
    expect.expect(2, posX, 'number')
    expect.expect(3, posY, 'number')
    expect.expect(4, width, 'number')
    expect.expect(5, height, 'number')
    --#endregion

    local class = {
        parent = _DESKTOP, -- Auto-assigned
        type = 'button', -- Constant
        text = text,
        x = posX,
        y = posY,
        w = width,
        h = height,
        colors = { colors.white, colors.gray },
        callback = { nop, nop, nop }
    }

    class.draw = function (self)
        local absL = self.parent.x + self.x - 1
        local absT = self.parent.y + self.y - 1
        local absR = absL + self.w - 1
        local absB = absT + self.h - 1
        local cutText = string.sub(self.text, 1, self.w)
        GL.filledBox(absL, absT, absR, absB, self.colors[1])
        GL.write(cutText, absL + (self.w - #cutText) / 2, absT+self.h/2, self.colors[2], self.colors[1])
    end
    
    -- Returns if the point is inside the button
    class.conj = function (self, x, y)
        local absL = self.parent.x + self.x - 1
        local absT = self.parent.y + self.y - 1
        local absR = absL + self.w - 1
        local absB = absT + self.h - 1
        return x >= absL and y >= absT and x <= absR and y <= absB
    end
    
    return class
end

lib.element.label = function (text, posX, posY)
    --#region Expects
    expect.expect(1, text, 'string')
    expect.expect(2, posX, 'number')
    expect.expect(3, posY, 'number')
    --#endregion

    local class = {
        parent = _DESKTOP, -- Auto-assigned
        type = 'label', -- Constant
        text = text,
        x = posX,
        y = posY,
        color = colors.white
    }

    class.draw = function (self)
        local absL = self.parent.x + self.x - 1
        local absT = self.parent.y + self.y - 1
        GL.write(self.text, absL, absT, self.color, self.parent.colors[2])
    end

    return class
end

-- #endregion

return lib