function ttsJSObject(params)
  local ret = {
    Nickname = "",
    Transform = {
      posX = 0.0, posY = 4.0, posZ = 0.0,
      rotX = 0.0, rotY = 0.0, rotZ = 0.0,
      scaleX = 1.0, scaleY = 1.0, scaleZ = 1.0,
    },
    ColorDiffuse = { r = 0.713235259, g = 0.713235259, b = 0.713235259, },
    Description = "-?-",
    Locked = false,
    Grid = false,
    Snap = true,
    IgnoreFoW = false,
    Autoraise = true,
    Sticky = true,
    Tooltip = true,
    GridProjection = false,
    Hands = false,
    XmlUI = "",
    LuaScript = "",
    LuaScriptState = "",
  }

  assert(params["Name"] ~= nil, "ttsJSObject must have a Name!")

  for k, val in pairs(params) do
    ret[k] = val
  end
  for k, val in pairs(ret) do
    if k == nil or val == nil then
      assert(false, sprintf("Card %s, jsobj[%s] = %s?",
                            params.Name, tostring(k), tostring(val)))
    end
  end
  return ret
end

function destroyGameObjects()
  for _, obj in ipairs(getAllObjects()) do
    if obj.tag == "Tile" then
      -- Authority counters
      destroyObject(obj)
    elseif (obj.tag == "Card" or obj.tag == "Deck") then
      -- The rules cards are not hide when face down.
      if obj.hide_when_face_down then
        destroyObject(obj)
      end
    end
  end
end

function getPositionInZone(zone, xoff, zoff)
  -- Returns position inside zone. xoff and zoff of -0.5 = lower-left corner.
  local bounds = zone.getBounds()
  local bscale = zone.getScale()
  local bpos = bounds["center"]

  local xmul = bscale["x"]
  local zmul = bscale["z"]


  local rot = zone.getRotation()
  local yrot = rot["y"]

  local rcos = math.cos(math.rad(yrot))
  local rsin = math.sin(math.rad(yrot))

  -- Point is {xoff, zoff} rotated.
  local x2 = (xoff * rcos) - (zoff * rsin)
  local z2 = (zoff * rcos) + (xoff * rsin)

  local pos = {
    x = bpos["x"] + (x2 * xmul),
    y = YFLAT,
    z = bpos["z"] + (z2 * zmul),
  }
  return pos
end

function filterCards(objs, fnc)
  local ret = {}
  for _, obj in ipairs(objs) do
    if obj.tag == "Card" and obj.hide_when_face_down then
      local card = ALL_CARDS[obj.getName()]
      if not fnc or fnc(obj, card) then
        ret[#ret+1] = obj
      end
    end
  end
  return ret
end

function warnPlayer(color, fmt, ...)
  tellPlayer(color, {r=1.0, g=0.7, b=0.7}, fmt, ...)
end

function tellPlayer(color, textcol, fmt, ...)
  local what = fmt:format(...)
  if Player[color] and Player[color].seated then
    broadcastToColor(what, color)
  else
    broadcastToAll("--- to " .. playerName(color) .. ": " .. what)
  end
end

function announce(color, fmt, ...)
  local pname = playerName(color)
  local what = fmt:format(...)
  announceGame(pname .. " " .. what)
end

RECENT_ANNOUNCEMENTS = {}

function announceGame(fmt, ...)
  local what = fmt:format(...)
  local found = false
  local dostart = #RECENT_ANNOUNCEMENTS == 0

  for _, val in ipairs(RECENT_ANNOUNCEMENTS) do
    if val[1] == what then
      val[2] = val[2] + 1
      found = true
      break
    end
  end
  if not found then
    table.insert(RECENT_ANNOUNCEMENTS, {what, 1})
  end
  if dostart then
    greenWait({
      name = "dumpAnnouncements",
      qwait = false,
      frames = 10,
      callback = dumpAnnouncements,
    })
  end
end

function dumpAnnouncements()
  for _, val in ipairs(RECENT_ANNOUNCEMENTS) do
    local msg
    if val[2] > 1 then
      msg = sprintf("*** %s (x%d)", val[1], val[2])
    else
      msg = "*** " .. val[1]
    end
    printToAll(msg, {r=0.3, g=0.7, b=0.7})
    logToNotes(msg)
  end
  RECENT_ANNOUNCEMENTS = {}
end

function objectsToGUIDs(objs)
  return mapList(objs, function(o) return o.getGUID() end)
end

function guidsToObjects(guids)
  if not guids or #guids < 1 then
    return {}
  end
  local ret = {}
  for _, guid in ipairs(guids) do
    table.insert(ret, getObjectFromGUID(guid))
  end
  return ret
end

function guidsToNames(guids)
  if not guids or #guids < 1 then
    return "(None)"
  end
  local ret = {}
  for _, obj in ipairs(guidsToObjects(guids)) do
    table.insert(ret, obj.getName())
  end
  return concatAnd(ret, "and")
end

function clearNotes()
  Notes.editNotebookTab({
    index=0,
    title="Game Log",
    body="",
    color="Grey",
  })
end

function logToNotes(msg)
  local tabs = Notes.getNotebookTabs()
  local tab = nil
  for _, x in ipairs(tabs) do
    -- Le sigh, can't just use tabs[0] ...
    if x["index"] == 0 then
      tab = x
      break
    end
  end
  if tab then
    tab["body"] = tab["body"] .. msg .. "\n"
    Notes.editNotebookTab(tab)
  else
    die("No tab to log to?")
  end
end

function logEffect(color, card, fmt, ...)
  local speaker = playerName(color)
  if not speaker then speaker = color end
  local message = fmt:format(...)

  local msg = card .. ": " .. speaker .. " " .. message
  logToNotes(msg)
end

function isNearby(a, b, maxdist)
  -- Fast & easy pythagorean
  local xd = a["x"] - b["x"]
  local zd = a["z"] - b["z"]

  local max = maxdist * maxdist
  local dist = xd * xd + zd * zd
  return (dist < max)
end

function isInside(zone, obj)
  -- quick & dirty for now, then add
  -- Position checking later.
  local list = zone.getObjects()
  for _, o in ipairs(list) do
    if o == obj then
      return true
    end
  end
  return false
end

function destroyCard(obj)
  obj.setDescription("DEAD")
  obj.setPosition({x="0", y="-10", z="0"})
  setPlayState("scrapped", obj.getGUID(), true)
  -- destroyObject(obj)
  obj.destruct()
end

function die(fmt, ...)
  dumpAnnouncements()
  local tmp = {...}
  local n = select('#', ...)

  local good, err = pcall(function()
    local message = string.format(fmt, unpack(tmp, 1, n))
    printToAll("Die: " .. message)
  end)

  if not good then
    printToAll("Die Failed trying: '" .. fmt .. "': " .. err)
  end

  DebugEngine.printCallStack()

  local now = Time.time
  for qid, gwait in pairs(QWAITON) do
    printf("QWAITON: %s for %d seconds", gwait["name"], math.floor(now - gwait["ts"]))
  end
  if GAMESTATE.state == RUNNING then
    announceGame("Die: Scripting Halted")
    GAMESTATE.state = UNSCRIPTED
    updateButtons()
  end
end

function whine(fmt, ...)
  dumpAnnouncements()
  local tmp = {...}
  local n = select('#', ...)

  local good, err = safecall(function()
    local message = string.format(fmt, unpack(tmp, 1, n))
    printToAll("Whine: " .. message)
  end)

  if not good then
    printToAll("Whine Failed trying: '" .. fmt .. "': " .. err)
  end
end

function returnObject(color, obj, origstate)
  if origstate[2] == S_HAND then
    sendToHand(obj.getDescription(), obj)
  elseif origstate[2] == S_PLAYER_DISCARD then
    discardAllCards(color, {obj}, obj.held_by_color ~= nil)
  else
    local pos = origstate[3]
    local rot = origstate[4]
    obj.setPosition(pos)
    obj.setRotation(rot)
  end
end

function isGameObject(obj)
  if obj.tag == "Deck" then return true end
  if obj.tag == "Card" then
    local card = ALL_CARDS[obj.getName()]
    if card then
      return true
    end
  end
  return false
end

