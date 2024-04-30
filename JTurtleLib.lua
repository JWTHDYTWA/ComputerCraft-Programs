local tur = {}

tur.getName = function ()
    local A, B = turtle.inspect()
    if A then
        return B.name
    end
end

tur.getNameUp = function ()
    local A, B = turtle.inspectUp()
    if A then
        return B.name
    end
end

tur.getNameDown = function ()
    local A, B = turtle.inspectDown()
    if A then
        return B.name
    end
end

tur.useItem = function (id)
    local ss = turtle.getSelectedSlot()
    for i = 1, 16 do
        turtle.select(i)
        local cs = turtle.getItemDetail()
        if cs then
            if cs.name == id then
                turtle.place()
                turtle.select(ss)
                return true
            end
        end
    end
    turtle.select(ss)
    return false
end

tur.useItemF = function (fid)
    local ss = turtle.getSelectedSlot()
    for i = 1, 16 do
        turtle.select(i)
        local cs = turtle.getItemDetail()
        if cs then
            if cs.name:find(fid) then
                turtle.place()
                turtle.select(ss)
                return true
            end
        end
    end
    turtle.select(ss)
    return false
end

return tur