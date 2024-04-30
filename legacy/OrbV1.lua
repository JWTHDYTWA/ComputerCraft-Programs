local sphere = peripheral.wrap('top')

local function check()
    if sphere.getItemDetail(2)
    or sphere.getItemDetail(3)
    or sphere.getItemDetail(4)
    or sphere.getItemDetail(5)
    or sphere.getItemDetail(6)
    or sphere.getItemDetail(7) then
        return true
    end
end

term.clear()
term.setCursorPos(2,2)
term.setTextColor(colors.lime)
term.write('Orb Conveyor')
term.setCursorPos(2,4)
term.setTextColor(colors.lightGray)
term.write('It will push items from the left inventory\'s')
term.setCursorPos(2,5)
term.write('first 6 slots in parallel as long as all the')
term.setCursorPos(2,6)
term.write('input slots are empty.')
term.setCursorPos(2,8)
term.write('It will also extract output items into the')
term.setCursorPos(2,9)
term.write('right inventory.')

while true do
    if sphere.getItemDetail(1) then
        sphere.pushItems('right', 1)
    end

    if not check() then
        sphere.pullItems('left', 1, 1)
        sphere.pullItems('left', 2, 1)
        sphere.pullItems('left', 3, 1)
        sphere.pullItems('left', 4, 1)
        sphere.pullItems('left', 5, 1)
        sphere.pullItems('left', 6, 1)
    end

    sleep(0.2)
end