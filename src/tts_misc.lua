function defineHandZones()
  for col, def in pairs(HANDLOCS) do
    local tf = Player[col].getHandTransform()
    local handrot = {x=0.0, y=def["yrot"], z=0.0}
    tf["scale"]["z"] = 7.5
    tf["scale"]["y"] = 5.1
    tf["scale"]["x"] = 25
    tf["position"]["y"] = 3.0
    tf["position"]["x"] = def["x"]
    tf["position"]["z"] = 55 * def["zmul"]
    tf["rotation"] = handrot
    Player[col].setHandTransform(tf)

    local deckzone = PLAYER_DECK_ZONE[col]
    local pos = deckzone.getPosition()
    local scale = deckzone.getScale()
    pos["z"] = 43 * def["zmul"]
    pos["y"] = 3.0
    pos["x"] = def["x"]
    scale["z"] = 7.5
    scale["x"] = 35
    scale["y"] = 5.1
    deckzone.setScale(scale)
    deckzone.setPosition(pos)
    deckzone.setRotation(handrot)


    local playzone = PLAYER_ZONE[col]
    pos = playzone.getPosition()
    scale = playzone.getScale()
    pos["z"] = 27.5 * def["zmul"]
    pos["y"] = 3.0
    pos["x"] = def["x"]
    scale["z"] = 20
    scale["x"] = 35.0
    scale["y"] = 5.1
    playzone.setScale(scale)
    playzone.setPosition(pos)
    playzone.setRotation(handrot)
  end

  for _, obj in ipairs(getAllObjects()) do
    if obj.tag == "Scripting" then
      local pos = obj.getPosition()
      pos["y"] = 3.0
      obj.setPosition(pos)
    end
  end
end

function fixObjects()
  defineHandZones()
  for _, obj in ipairs(getAllObjects()) do
    if obj.tag == "Board" then
      obj.setLock(true)
      obj.interactable = false
    end
  end
end

function getZoneBorder(zone)
  return {
    getPositionInZone(zone, -0.5, -0.5),
    getPositionInZone(zone, -0.5, 0.5),
    getPositionInZone(zone, 0.5, 0.5),
    getPositionInZone(zone, 0.5, -0.5),
    getPositionInZone(zone, -0.5, -0.5),
  }
end

function drawVectors()
  local vectors = {
    {
      points = getZoneBorder(GameZones.SCRAP),
      color = {r=1, g=0.5, b=0.5},
      thickness = 0.2,
    },
    {
      points = getZoneBorder(GameZones.DISCARD),
      color = {r=0.5, g=1, b=1},
      thickness = 0.2,
    },
  }

  Global.setVectorLines(vectors)
end

function setCustomUIAssets()
  local assets = {}
  for name, val in pairs(CUSTOM_UI_ASSETS) do
    assets[#assets+1] = {
      name = name,
      url = val,
    }
  end
  UI.setCustomAssets(assets)
end

