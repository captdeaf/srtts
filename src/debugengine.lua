-- Why oh why oh why does TTS remove all debug libraries and symbols?
-- I hate this approach, but I don't see anything better.
--
-- Debug or not debug, that is the question.

DebugEngine = {
  start = function()
    for name, istoplevel in pairs(DEBUG_FUNCTIONS) do
      local val = _G[name]
      if type(val) == 'function' then
        if istoplevel then
          _G[name] = DebugEngine.wrapToplevel(name, val)
        else
          _G[name] = DebugEngine.wrap(name, val)
        end
      end
    end
  end,
  wrapToplevel = function(name, func)
    return function(...)
      DebugEngine.used[name] = true
      local stackcopy = DebugEngine.stack
      DebugEngine.stack = {name}
      local rets = {func(...)}
      DebugEngine.stack = stackcopy
      return unpack(rets)
    end
  end,
  wrap = function(name, func)
    return function(...)
      DebugEngine.used[name] = true
      local atstart = #DebugEngine.stack
      table.insert(DebugEngine.stack, name)
      local rets = {func(...)}
      local popped = table.remove(DebugEngine.stack, #DebugEngine.stack)
      if popped ~= name then
        printf("Popped function mismatch: %s ~= %s", name, popped)
      end
      local atend = #DebugEngine.stack
      if atend ~= atstart then
        printf("Debug mismatch in stack count: %d vs %d", atstart, atend)
      end
      return unpack(rets)
    end
  end,
  handler = function(err)
    printf("ERROR caught by DebugEngine.handler: %s", tostring(err))
    DebugEngine.printCallStack()
  end,
  printCallStack = function()
    print("Call Stack:")
    print(table.concat(DebugEngine.stack, "->"))
  end,
  stack = {},
  used = {},
  printUnused = function()
    local ret = {}
    for name, istoplevel in pairs(DEBUG_FUNCTIONS) do
      if not DebugEngine.used[name] then
        table.insert(ret, name)
      end
    end
    printAll(ret)
  end,
}

function safecall(fn)
  local good, result = xpcall(fn, DebugEngine.handler)
  if not good then
    die("Error in safecall: %s. Stopping.", tostring(result))
  end
  return good, result
end

function printAll(val, name, prefix)
  if not name then name = "(toplevel)" end
  if not prefix then prefix = "" end
  if type(val) == 'table' then
    if hasAny(val) then
      printf("%s%s = {", prefix, name)
      for k, v in pairs(val) do
        printAll(v, k, prefix .. "  ")
      end
      printf("%s},", prefix)
    else
      printf("%s%s = {},", prefix, name)
    end
  elseif type(val) == 'function' then
    printf("%s%s = (function),", prefix, JSON.encode(name))
  else
    printf("%s%s = %s,", prefix, JSON.encode(name), JSON.encode(val))
  end
end

DebugEngine.start()
