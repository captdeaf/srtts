
function spreadLocs(col, pos, count, range)
  -- A bit of scatter to deal with TTS joining cards into decks.
  math.randomseed(tonumber(PLAYER_ZONE[col].getGUID(), 16))
  local ret = {}

  for idx=1,count,1 do
    local xloc = range - math.random(range*2)
    local zloc = range - math.random(range*2)
    table.insert(ret, {
      x = pos["x"] + xloc,
      y = pos["y"],
      z = pos["z"] - zloc,
    })
  end

  math.randomseed(Time.time)
  return ret
end

function updateDecals()
  local decs = {}
  for col, pinfo in pairs(GAMESTATE["players"]) do
    local musts = pinfo["musts"]
    if musts and #musts > 0 then
      local mustdo = musts[1][1]
      if (mustdo == "discard" and musts[1][2] > 0)
         or (mustdo == "scrap" and #musts[1][2] > 0) then
        for _, pos in ipairs(spreadLocs(col, PLAYER_ZONE[col].getPosition(), musts[1][2], 15)) do
          table.insert(decs, {"discard", pos, PDATA[col]["yrot"]})
        end
      end
    end
  end

  -- Now we have pairs of decals.
  local params = {}
  for _, def in ipairs(decs) do
    local rot = {
      x = 90.0,
      y = 0.0,
      z = 180.0 - def[3],
    }
    table.insert(params, {
      name = def[1],
      url = DECALS[def[1]],
      position = def[2],
      rotation = rot,
      scale = {x=7.0,y=7.0,z=7.0},
    })
  end

  Global.setDecals(params)
end

function showIndicator(arg, itype)
end

INDICATOR_LIST = {}
function showIndicator__OLD(arg, itype)
  -- indef == indicator global definition
  -- idef == instance def of indicator.
  local now = Time.time
  local indef = INDICATORS[itype]
  if not indef then
    return
  end
  local idef = {
    name = itype,
    indef = indef,
    tStart = now,
    tEnd = now + INDICATOR_DURATION,
    origrot = {x=90.0, y=0.0, z=0.0},
    scale = 2.0,
    offset = indef["offset"],
  }
  if type(arg) == 'table' then
    idef['origpos'] = arg
  else
    idef['guid'] = arg.getGUID()
    idef['origpos'] = arg.getPosition()
  end
  local cb = function(tok)
    idef["tok"] = tok
    tok.highlightOn(jscolor(1.0, 1.0, 0.7, 1.0))
    table.insert(INDICATOR_LIST, idef)
  end
  spawnSpinToken(idef, idef["origpos"], cb)
end

function clearIndicators()
  for _, obj in ipairs(getAllObjects()) do
    if obj.tag == "backgammon_piece_white" or obj.tag == "Backgammon Piece" then
      if obj.getGUID() ~= GUIDS.GameObjects.TRADE_TOKEN and
         obj.getGUID() ~= GUIDS.GameObjects.DAMAGE_TOKEN then
        destroyObject(obj)
      end
    end
  end
  INDICATOR_LIST = {}
end

function spawnSpinToken(idef, position, cb)
  local rot = {
    x=0.0,
    y=0.0,
    z=90.0,
  }
  local indef = idef["indef"]
  local token = {
    Name = "backgammon_piece_white",
    Transform = {
      posX = 0.0, posY = 0.0, posZ = 0.0,
      rotX = rot["x"], rotY = rot["y"], rotZ = rot["z"],
      scaleX = 1, scaleY = 1, scaleZ = 1,
    },
    Nickname = "spinny",
    Description = "",
    ColorDiffuse = indef["color"],
    Locked = true,
    Interactable = false,
    Grid = false,
    Snap = false,
    IgnoreFoW = true,
    Autoraise = false,
    Sticky = false,
    Tooltip = false,
    GridProjection = false,
    HideWhenFaceDown = false,
    Hands = false,
    XmlUI = "",
    LuaScript = "",
    LuaScriptState = "",
  }

  -- Start a bit above so we don't screw physics
  spawnObjectJSON({
    json = JSON.encode(token),
    position = vecTween(position, INDICATOR_MOVEMENT, 0.0, idef["offset"]),
    rotation = rot,
    scale = {x=INDICATOR_SCALE, y=1.0, z=INDICATOR_SCALE},
    sound = false,
    callback_function = cb,
  })
end

function updateIndicator(idef, now)
  local mul = (now - idef["tStart"]) / (idef["tEnd"] - idef["tStart"])
  local pos = idef["origpos"]
  if idef["guid"] then
    local obj = getObjectFromGUID(idef["guid"])
    if obj ~= nil then
      pos = obj.getPosition()
      idef['origpos'] = pos
    end
  end

  local newpos = vecTween(pos, INDICATOR_MOVEMENT, mul, idef["offset"])
  local newrot = vecTween(idef["origrot"], INDICATOR_ROTATION, mul)

  newrot["x"] = newrot["x"] % 360
  newrot["y"] = newrot["y"] % 360
  newrot["z"] = newrot["z"] % 360

  idef["tok"].setPosition(newpos, false, true)
  idef["tok"].setRotation(newrot, false, true)
end

function tickIndicators()
  if #INDICATOR_LIST < 1 then return end
  if GAMESTATE["state"] ~= RUNNING then
    clearIndicators()
    return
  end
  local now = Time.time
  while #INDICATOR_LIST > 0 and INDICATOR_LIST[1]["tEnd"] < now do
    destroyCard(INDICATOR_LIST[1]["tok"])
    table.remove(INDICATOR_LIST, 1)
  end
  if #INDICATOR_LIST < 1 then
    clearIndicators()
    return
  end
  for _, idef in ipairs(INDICATOR_LIST) do
    updateIndicator(idef, now)
  end
end

