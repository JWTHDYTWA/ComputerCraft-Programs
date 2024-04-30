local WL = require('JWindowLib')
periphemu.create('top','speaker')
local S = peripheral.wrap('top')
 
local first = WL.window('The First', 20, 3, 20, 10)
 
local b1 = WL.element.button('Low', 2, 3, 3, 7)
b1.colors[1] = colors.blue
b1.colors[2] = colors.lightBlue
b1.callback[1] = function ()
    S.playNote('guitar', 1, 8)
end
local b2 = WL.element.button('Med', 6, 3, 3, 7)
b2.colors[1] = colors.green
b2.colors[2] = colors.lime
b2.callback[1] = function ()
    S.playNote('guitar', 1, 10)
end
local b3 = WL.element.button('Hig', 10, 3, 3, 7)
b3.colors[1] = colors.red
b3.colors[2] = colors.orange
b3.callback[1] = function ()
    S.playNote('guitar', 1, 12)
end

first:addElement(b1)
first:addElement(b2)
first:addElement(b3)
first:addElement(WL.element.closeButton())
 
local second = WL.window('Empty', 12, 2, 15, 7)
second.colors[1] = colors.purple
second.colors[2] = colors.cyan

second:addElement(WL.element.closeButton())
 
_WindowProcedures.add(first)
_WindowProcedures.add(second)

while #_WindowStack > 0 do
    _WindowProcedures.redraw()
    _WindowProcedures.process()
end
term.clear()