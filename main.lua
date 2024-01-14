require "parser"
require "emulator"

function printf(s, ...)
  return io.write(s:format(...))
end

local dividers = {
  { 5, 50, love.graphics.getWidth() - 5, 50 },     -- Horizontal register divider
  { 200, 55, 200, love.graphics.getHeight() - 5 }, -- Vertical instruction divider
}

local op_table_pos = { x = 25, y = 50 }
local cell_height  = 16

local reg_table_pos = { x = 25, y = 10 }
local reg_width     = 50

local mem_min = 1000
local mem_max = 0
local mem_table_pos = { x = dividers[2][1] + 25, y = dividers[1][2] + 25 }
local mem_width
local mem_height

local line_height

function love.load()
  love.graphics.setBackgroundColor(0.2, 0.2, 0.6, 1.0)
  font = love.graphics.newFont("veramono.ttf", 16)
  love.graphics.setFont(font)
  line_height = font:getHeight("0")

  parse_file("programs/test")

  -- Get the range of memory locations used in the program
  local mem_ops = { STO = 1, LDD = 2, LDI = 3 }
  for i, op in ipairs(ast) do
    if mem_ops[op.op] then
      if op.val < mem_min then mem_min = op.val end
      if op.val > mem_max then mem_max = op.val end
    end
  end
  emulator_init()

  -- Calculate trace table divider lines
  mem_width  = font:getWidth(string.format("%5d", 0))
  mem_height = (#ast + 3)*font:getHeight("0")
--  printf("Mem col width: %d\nMem total height: %d\n", mem_width, mem_height)
--  printf("Adding %d lines for mem\n", table.getn(memory))
  local x, y
  for i = 1, #mem_locs + 1 do
    x = mem_table_pos.x + (i-1)*mem_width
    y = mem_table_pos.y
    dividers[#dividers+1] = { x, y, x, y+mem_height }
  end
  -- Header divider
  x = mem_table_pos.x
  y = mem_table_pos.y
  dividers[#dividers+1] = { x, y+line_height, x+(#mem_locs)*mem_width, y+line_height }
  dividers[#dividers+1] = { x, y, x+(#mem_locs)*mem_width, y }
end

function love.update(dt)

end

function love.draw()
  local str, fmt
  
  -- Instructions 
  for i, op in ipairs(ast) do
    fmt = type(op.val) == "string" and "%2d | %s | %s%s" or op.val and "%2d | %s | %s%d" or "%2d | %s | "
    str = string.format(fmt, i+addr_start-1, op.op, op.pre or "", op.val)
    love.graphics.print(str, op_table_pos.x, op_table_pos.y + i*font:getHeight())
  end

  -- Registers
  local ordered_tokens = {}
  for key in pairs(registers) do
    table.insert(ordered_tokens, key)
  end

  table.sort(ordered_tokens)
  local is_cir
  for i, reg in pairs(ordered_tokens) do
    is_cir = type(registers[reg]) == "number"
    fmt = is_cir and "%s\n%d" or "%s\n%s"
    str = string.format(fmt, reg, is_cir and registers[reg] or registers[reg].op)
    love.graphics.printf(str, reg_table_pos.x+i*reg_width, reg_table_pos.y, reg_width, "center")
  end

  -- Memory headers
  for i, mem in pairs(memory) do
    fmt = "%d"
    str = string.format(fmt, mem.loc)
    love.graphics.printf(str, mem_table_pos.x+(i-1)*mem_width, mem_table_pos.y, mem_width, "center")
  end
  -- Memory values
  for j = 1, #trace_table do
    for i, mem in pairs(trace_table[j]) do
      fmt = mem.val and "%d" or "%s"
      str = string.format(fmt, mem.val and mem.val or "")
      love.graphics.printf(str, mem_table_pos.x+(i-1)*mem_width, mem_table_pos.y+j*line_height, mem_width, "center")
    end
  end

  -- Divider lines
  for _, points in ipairs(dividers) do
    love.graphics.line(unpack(points))
  end
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  elseif key == "space" then
    emulate()
  end
end

function love.keyreleased(key)

end
