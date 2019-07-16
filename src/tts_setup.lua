function mapColors()
  PLAYER_COLOR = {
    White = jscolor(1, 1, 1),
    Brown = jscolor(0.443, 0.231, 0.09),
    Red = jscolor(0.856, 0.1, 0.094),
    Orange = jscolor(0.956, 0.392, 0.113),
    Yellow = jscolor(0.905, 0.898, 0.172),
    Green = jscolor(0.192, 0.701, 0.168),
    Teal = jscolor(0.129, 0.694, 0.607),
    Purple = jscolor(0.627, 0.125, 0.941),
    Pink = jscolor(0.96, 0.439, 0.807),
    Grey = jscolor(0.5, 0.5, 0.5),
    Black = jscolor(0.25, 0.25, 0.25),
  }

  local dim = function(col)
    return {
      r = col["r"] * 0.6,
      g = col["g"] * 0.6,
      b = col["b"] * 0.6,
    }
  end

  for pcol, jscol in pairs(PLAYER_COLOR) do
    PLAYER_BG_COLOR[pcol] = dim(jscol)
  end
end

function mapPlayers()
  for color, zone in pairs(PLAYER_ZONE) do
    mapPlayer(color, zone)
  end
end

function mapPlayer(color, pzone)
  local pdata = {
    yrot = {},
    deckloc = {},
    discardloc = {},
    isdrawing = 0,
  }
  if not pzone then
    die("Can't find zone for %s", color)
  end

  local prot = { x = 0.0, y = 0.0, z = 0.0, }

  -- The "rotation" is actually the rotation of what faces the center,
  -- so for facing the player, we want it flipped around the y axis.
  local pzr = pzone.getRotation()
  -- Float comparisons stink.
  if pzr["y"] > 178.0 and pzr["y"] < 182.0 then
    prot["y"] = 0
  elseif pzr["y"] < 1.0 and pzr["y"] > -1.0 then
    prot["y"] = 180.0
  else
    prot["y"] = (pzr["y"] + 180.0) % 360
  end

  pdata["rot"] = prot
  pdata["yrot"] = prot["y"]

  -- Player's Deck Zone:

  local dzone = PLAYER_DECK_ZONE[color]

  pdata["deckloc"] = getPositionInZone(dzone, 0.3, 0.0)
  pdata["discardloc"] = getPositionInZone(dzone, -0.3, 0.0)
  pdata["authloc"] = getPositionInZone(dzone, 0.0, 0.0)

  PDATA[color] = pdata
end

function mapTradeLocs()
  -- With odd # of cards, and left/rightmost being 0.5: each card gets 0.2
  -- width, but we calculate from center.
  --  -0.4  -0.2  0 0.2 0.4
  local tradepos = {
    getPositionInZone(GameZones.TRADE, -0.4, 0.0),
    getPositionInZone(GameZones.TRADE, -0.2, 0.0),
    getPositionInZone(GameZones.TRADE,  0.0, 0.0),
    getPositionInZone(GameZones.TRADE,  0.2, 0.0),
    getPositionInZone(GameZones.TRADE,  0.4, 0.0),
  }
  PDATA["tradepos"] = tradepos

  -- And explorer position.
  PDATA["explorerpos"] = getPositionInZone(GameZones.EXPLORER,  0.0, 0.0)
end

function makeSnapPoints()
  -- Snap points:
  -- Each player's deck and discard
  -- Trade deck
  -- Explorer
  -- Trade card positions
  -- (All are rotation snap)
  local snaps = {}

  -- each player's deck and discard.
  for color in pairs(PLAYER_ZONE) do
    local pdata = PDATA[color]
    table.insert(snaps, {
      position = pdata.deckloc,
      rotation = {x=0, y=pdata["yrot"], z=180.0},
      rotation_snap = true,
    })
    table.insert(snaps, {
      position = pdata.discardloc,
      rotation = {x=0, y=pdata["yrot"], z=0.0},
      rotation_snap = true,
    })
  end

  -- Rotation that applies to all the script-managed cards
  -- in the play are: trade row, deck, explorer.
  local play_rotation = {x=0, y=180, z=0.0}

  -- Trade deck
  table.insert(snaps, {
    position = GameZones.TRADE_DECK.getPosition(),
    rotation = play_rotation,
    rotation_snap = true,
  })

  -- all cards of trade row
  for _, pos in ipairs(PDATA["tradepos"]) do
    table.insert(snaps, {
      position = pos,
      rotation = play_rotation,
      rotation_snap = true,
    })
  end

  -- explorer
  table.insert(snaps, {
    position = PDATA["explorerpos"],
    rotation = play_rotation,
    rotation_snap = true,
  })

  Global.setSnapPoints(snaps)
end

