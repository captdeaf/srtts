function vecAvg(vecs)
  assert(#vecs >= 1, "vecAvg without enough vecs?")
  local ret = duplicate(vecs[1])
  if #vecs == 1 then return ret end

  for i=2,#vecs,1 do
    local vec = vecs[i]
    for k, v in pairs(ret) do
      ret[k] = ret[k] + vec[k]
    end
  end

  for k, v in pairs(ret) do
    ret[k] = ret[k] / #vecs
  end
  return ret
end

function mapList(lst, fnc)
  local ret = {}
  for idx, item in ipairs(lst) do
    table.insert(ret, fnc(item, idx))
  end
  return ret
end

function mapMember(lst, name)
  return mapList(lst, function(i) return i[name] end)
end

function oneormore(count, ifone, iftwo)
  if count == 1 then
    return ifone
  else
    return iftwo:format(count)
  end
end

function sprintf(s, ...)
  return s:format(...)
end

function printf(s, ...)
  print(s:format(...))
end

function isMember(lst, item)
  for _, i in ipairs(lst) do
    if item == i then return true end
  end
  return false
end

function concatAnd(list, conj)
  if not conj then conj = "and" end
  if not list or #list == 0 then return "None" end
  if #list == 1 then return list[1] end
  if #list == 2 then
    return sprintf("%s %s %s", list[1], conj, list[2])
  end
  -- Ah well, copy the list and remove the last.
  local butlast = {}
  for i=1,#list-1,1 do
    butlast[i] = list[i]
  end
  return sprintf("%s, %s %s", table.concat(butlast, ", "), conj, list[#list])
end

function hasAny(tbl)
  return howMany(tbl) > 0
end

function howMany(tbl)
  if tbl == nil then return 0 end
  local count = 0
  for _ in pairs(tbl) do
    count = count + 1
  end
  return count
end

function hasAnyBut(tbl, ex)
  if tbl == nil then return false end
  for k, v in pairs(tbl) do
    if ex ~= k then
      return true
    end
  end
  return false
end

function removeFromList(list, item)
  for idx, v in ipairs(list) do
    if v == item then
      table.remove(list, idx)
      return list
    end
  end
  die("removeFromList called for item not in list")
end

-- "tween" two vectors. amt=0, position is (orig+addl).
-- amt=1, position is (orig+diff+addl).
-- addl for an offset to both. (Since orig is usually an object.getPosition)
function vecTween(orig, diff, amt, addl)
  if addl == nil then addl = {} end
  local ret = {}
  for k, v in pairs(orig) do
    ret[v] = orig[v] + (diff[v] * amt) + (addl[v] or 0)
  end
  return ret
end

function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

function mergeTables(tbls)
  if not tbls or #tbls == 0 then
    return {}
  end
  local dst = tbls[1]
  for i=2,#tbls,1 do
    for k, v in pairs(tbls[i]) do
      dst[k] = v
    end
  end
  return dst
end

local NEEDSDUPE = {
  string = false,
  float = false,
  number = false,
  boolean = false,
  table = true,
}
function duplicate(obj)
  local nd = NEEDSDUPE[type(obj)]
  assert(nd ~= nil, "Unknown dupe target: " .. type(obj))
  if nd == false then return obj end

  local dupe = {}
  for k, v in pairs(obj) do
    dupe[k] = duplicate(v)
  end
  return dupe
end

function normalize(str)
  local ret = str:gsub("%W",'')
  return ret:lower()
end

