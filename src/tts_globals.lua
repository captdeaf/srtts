CUSTOM_UI_ASSETS = {
  dialogbg = "http://i.imgur.com/sNrxEY1.jpg",
}

DECALS = {
  discard = "https://www.pngkit.com/png/detail/5-58044_best-free-troll-face-png-image-troll-face.png",
}

-- color() is incompatible with JSON.encode, so I have to add my own jscolor()
-- to both convert (jscolor(col)) or create.
--
function jscolor(r, g, b, a)
  if type(r) == 'table' then -- convert
    return {r=r["r"], g=r["g"], b=r["b"], a=r["a"]}
  else -- create
    if a == nil then a = 100 end
    return {r=r, g=g, b=b, a=a}
  end
end

INDICATOR_DURATION = 1.0
INDICATOR_SCALE = 2.0
INDICATOR_MOVEMENT = {x=0.0, y=20.0, z=0.0}
INDICATOR_ROTATION = {x=0.0, y=0.0, z=1800.0}
INDICATORS = {
  damage = {
    color = jscolor(1.0, 0.6, 0.6),
    offset = {x=0, y=3.0, z=0},
  },
  trade = {
    color = jscolor(1.0, 1.0, 0.4),
    offset = {x=0, y=3.0, z=-2},
  },
  authority = {
    color = jscolor(0.6, 1.0, 0.6),
    offset = {x=0, y=3.0, z=2},
  },
  draw = {
    color = jscolor(0.0, 0.0, 1.0),
    offset = {x=2, y=3.0, z=0},
  },
  discard = {
    color = jscolor(0.0, 0.0, 0.0),
    offset = {x=-2, y=3.0, z=0},
  },
}

COLORS = {
  ATTACK = jscolor(1.0,0.3,0.3,1),
  BUYABLE = jscolor(0.4,0.4,1,1),
  INTERACTABLE = jscolor(1,1,1,1),
  SCRAPPABLE = jscolor(1,0.7,0.5,1),
  SELECTABLE = jscolor(1,1,1,1),
}

-- How large to draw tokens, cards, etc.
TOKENSCALE = 3
CARDSCALE = 2.5

PLAYER_COLOR = {}
PLAYER_BG_COLOR = {}

-- YFLAT: As close to the table surface as we can get, to reduce the
-- time it takes a card to rest.
YFLAT = 1.4

-- PDATA is our calculated data from the zones and information at load time.
-- e.g: it contains deck locations, default Y-rotation of the players' cards,
-- etc
PDATA = {}

PLAYER_ZONE = {}
PLAYER_DECK_ZONE = {}

GameZones = {}
GameObjects = {}

-- MAP_GUIDS convert guids into game objects.  Intended for permanent objects.
-- global sets them in _G[...]. PLAYER_ZONE sets them under the global
-- PLAYER_ZONE, etc.
GUIDS = {
  GameZones = {
    TRADE_DECK = "dd4adc",
    TRADE = "fdf7ea",
    EXPLORER = "63c5db",
    SCRAP = "4f76ae",
    DISCARD = "888eb9",
    PLAY = "6de60b",
  },
  GameObjects = {
    STATE_BUTTON = "ae0ffa",
    SCRIPT_BUTTON = "6a7aa1",
    PLAY_BOX = "69f9cc",
    TRADE_TOKEN = "b4e794",
    DAMAGE_TOKEN = "31ee2c",
    TURN_TEXT = "59a405",
  },
  PLAYER_ZONE = {
    -- top
    Yellow = "0ea119",
    Green = "24d092",
    Teal = "3d85a5",
    Purple = "23eeae",
    -- bottom
    Red = "c6c2e8",
    White = "3bc76c",
    Brown = "89224d",
    Orange = "b7151d",
  },
  PLAYER_DECK_ZONE = {
    Yellow = "e9b105",
    Green = "05273f",
    Teal = "a82e41",
    Purple = "e1232e",
    -- bottom
    Red = "9d7eb2",
    White = "bd5d7a",
    Brown = "c5baa1",
    Orange = "867deb",
  }
}

-- Player colors
Yellow = "Yellow"
Green  = "Green"
Teal   = "Teal"
Purple   = "Purple"
-- bottom
Red    = "Red"
White  = "White"
Brown  = "Brown"
Orange = "Orange"


HANDLOCS = {
    -- top
    Yellow = {x=-60, zmul=1,  yrot=180.0},
    Green  = {x=-20, zmul=1,  yrot=180.0},
    Teal   = {x=20,  zmul=1,  yrot=180.0},
    Purple   = {x=60,  zmul=1,  yrot=180.0},
    -- bottom
    Red    = {x=-60, zmul=-1, yrot=0.0},
    White  = {x=-20, zmul=-1, yrot=0.0},
    Brown  = {x=20,  zmul=-1, yrot=0.0},
    Orange = {x=60,  zmul=-1, yrot=0.0},
}

function mapObjects()
  -- Add global values for everything in guid, so we can directly manipulate
  -- objects
  for name, maps in pairs(GUIDS) do
    if name == "global" then
      for varname, guid in pairs(maps) do
        _G[varname] = getObjectFromGUID(guid)
      end
    else
      if _G[name] == nil then _G[name] = {} end
      for varname, guid in pairs(maps) do
        _G[name][varname] = getObjectFromGUID(guid)
      end
    end
  end

  INDICATORS.trade.color = jscolor(GameObjects.TRADE_TOKEN.getColorTint())
  INDICATORS.damage.color = jscolor(GameObjects.DAMAGE_TOKEN.getColorTint())
end

