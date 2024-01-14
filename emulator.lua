require "tokens"

local mem_changed
memory = {}
trace_table = {}
registers = {
  PC   = 1,
  MDR  = 0,
  MAR  = 0,
  ACC  = 0,
  IX   = 0,
  CIR  = 0,
  SR   = 0,
  FLAG = 0,
}

local function mem_get(loc)
  for _, mem in pairs(memory) do
    if mem.loc == loc then
      return mem.val
    end
  end
end

local function mem_store(loc, val)
  for _, mem in pairs(memory) do
    if mem.loc == loc then
      mem.val = val
      mem_changed = loc
    end
  end
end

local operators = {
  LDM = function(val) registers.ACC = val end,
  LDD = function(val) registers.ACC = mem_get(val) end,
  LDI = function(val) registers.ACC = mem_get(mem_get(val)) end,
  LDR = function(val) registers.IX  = val end,
  LDX = function(val) registers.ACC = mem_get(val + registers.IX) end,
  STO = function(val) mem_store(val, registers.ACC) end,
  ADD = function(val)
    if registers.CIR.pre == "#" then
      registers.ACC = registers.ACC + val
    else
      registers.ACC = registers.ACC + mem_get(val)
    end
  end,
  SUB = function(val) registers.ACC = registers.ACC - val end,
  INC = function(reg) registers[reg] = registers[reg] + 1 end,
  DEC = function(reg) registers[reg] = registers[reg] - 1 end,
  CMP = function(val)
    if registers.ACC > val then
      registers.FLAG = 1
    elseif registers.ACC < val then
      registers.FLAG = -1
    else
      registers.FLAG = 0
    end
  end,
  JPE = function(val) if registers.FLAG == 0 then registers.PC = val - addr_start end end,
  JPN = function(val) if registers.FLAG ~= 0 then registers.PC = val - addr_start end end,
}

function emulator_init()
  printf("Initialized emulator with memory locations: ")
  registers.CIR = ast[registers.PC]
  trace_table = {{}}
  local default
  for i, loc in pairs(mem_locs) do
    default = 0
    printf("%d ", loc)
    for _, v in pairs(mem_defaults) do
      if v.loc == loc then
        default = v.val
      end
    end
    memory[i] = { loc = loc, val = default }
    trace_table[1][i] = { loc = loc, val = default }
  end
  print()
end

local function next_instruction()
  registers.PC  = registers.PC + 1
  registers.CIR = ast[registers.PC]
end

function emulate()
  if registers.CIR.op == "END" then
    print("Program complete")
    return
  elseif registers.CIR.op == "OUT" then
    printf("Output: %s (%d)\n", string.char(registers.ACC), registers.ACC)
    next_instruction()
    return
  end
  if registers.CIR.op == "INC" or registers.CIR.op == "DEC" then
    printf("Running instruction %s (%s): incrementing %s\n", registers.PC+addr_start-1, registers.CIR.op, registers.CIR.val)
  else
    printf("Running instruction %s (%s) with value: %s%d\n", registers.PC+addr_start-1, registers.CIR.op, registers.CIR.pre or "", registers.CIR.val)
  end
--  printf("'%s' -> %d / %d\n", registers.CIR.op, registers["ACC"], registers[registers.CIR.val] or 0)
  operators[registers.CIR.op](registers.CIR.val)
  trace_table[#trace_table+1] = {}
  if mem_changed then
    for i, mem in pairs(memory) do
      if mem.loc == mem_changed then
        trace_table[#trace_table][i] = mem
        mem_changed = nil
      else
        trace_table[#trace_table][i] = nil
      end
    end
  end
  
  next_instruction()
end
