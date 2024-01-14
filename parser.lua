require "tokens"

ast = {}
mem_locs = {}
mem_defaults = {}
addr_start = 0

local function open_file(fname)
  local function file_exists(path)
    local file = io.open(path, "rb")
    if file then file:close() end
    return file ~= nil
  end
  
  if not file_exists(fname) then
    print("Error loading file: ", fname)
  end
  
  local fh = io.open(fname, "rb")
  local contents = fh:read("*a")
  fh:close()
  
  return contents
end

function parse_file(fname)
  text = open_file(fname)

  local lines = {}
  for s in text:gmatch("[^\r\n]+") do
      table.insert(lines, s)
  end
  
  local words
  for _, line in ipairs(lines) do
    words = line:gmatch("%S+")
    for word in words do
      if word == ";;" then
        word = words()
        if word == "mem_range" then
          for i = tonumber(words()), tonumber(words()) do
            mem_locs[#mem_locs+1] = i
          end
        elseif word == "addr_start" then
          addr_start = tonumber(words())
        elseif word == "mem_value" then
          mem_defaults[#mem_defaults+1] = { loc = tonumber(words()), val = tonumber(words()) }
        else
          while words() do end -- Skip comments
        end
      elseif instructions[word] then
        ast[#ast+1] = { op = word, val = nil, pre = nil }
      elseif ast[#ast].op == "INC" or ast[#ast].op == "DEC" then
        ast[#ast].val = word
      else
        assert(ast[#ast], "No instruction ready for: ", word)
        local prefix = word:sub(1, 1)
        if prefix == "#" then
          ast[#ast].val = tonumber(word:sub(2))
          ast[#ast].pre = "#"
        elseif prefix == "&" then
          assert(false, "no hex yet")
          ast[#ast].pre = "&"
        else
          ast[#ast].val = tonumber(word)
        end
      end
    end
  end
  
--  local fmt
--  for i, op in pairs(ast) do
--    fmt = (op == "INC" or op == "DEC") and "%2d: %s %s%d\n" or "%2d: %s %s%s\n"
--    printf(fmt, i, op.op, op.pre or "", op.val or 0)
--  end
end
