local utils = require('utils')
local args = utils.argParse(...)

if not (args.IN and args.OUT) then
    error('Usage:\nshop IN=left OUT=right LIST=filename')
end

local monitor = peripheral.find('monitor')
local IN = peripheral.wrap(args.IN)
local OUT = peripheral.wrap(args.OUT)

if not (IN and OUT and utils.contains({peripheral.getType(IN)}, 'inventory') and utils.contains({peripheral.getType(OUT)}, 'inventory')) then
    error('One of inventories not found')
end

