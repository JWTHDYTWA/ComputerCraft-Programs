local function hash(str)

  local h = 5381

  local bitShifts = {5, 15, 10, 3}
  
  for i = 1, string.len(str) do
    h = h + string.byte(str, i)
    
    local shift = bitShifts[i % #bitShifts + 1]
    if shift > 0 then
      h = h % 2^shift * 2^32 + math.floor(h / 2^shift)
    end
    
    h = h % 4294967296
  end

  return h

end

return hash