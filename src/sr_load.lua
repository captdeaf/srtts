-- Global objects. These are OK to overwrite, or they'd be in globals.py
ALL_CARDS = {}
ALL_CARD_NAMEMAP = {}
DECK_JSONS = {}

local ALL_CARD_TYPES = {
  -- true: has cost, faction and effects.
  -- false: Just type and name. Usually only for image assets
  -- or non-playable cards such as Events
  [SHIP]=true,
  [BASE]=true,
  [OUTPOST]=true,
  [HERO]=true,
  [GAMBIT]=true,

  -- Below don't have cost+, just exist as cards.
  [EVENT]=false,
}

function loadCards()
  -- Load the cards first.
  for _, cardinfo in ipairs(CARDDEFS) do
    checkCardInfo(cardinfo) -- raises errors if cardinfo is invalid.
    local name, cardtype, factions, cost, effects = unpack(cardinfo)

    ALL_CARDS[name] = {
      name = name,
      type = cardtype,
      cost = cost,
      factions = factions,
      effects = effects,
    }
  end

  -- Create new ones for Merc ships of each faction. It's kindasorta
  -- a dumb stealth needle.
  local merc_colors = {}
  for cname, card in pairs(ALL_CARDS) do
    if ALL_CARD_TYPES[card.type] then
      if card["effects"]["mercenary"] then
        for _, fac in ipairs({SE, BB, MC, TF}) do
          local dup = duplicate(card)
          dup["effects"]["mercenary"] = nil
          dup["jsobj"] = nil
          dup["factions"] = {fac}
          dup["name"] = sprintf("%s: %s", card["name"], fac)
          table.insert(merc_colors, dup)
        end
      end
    end
  end

  for _, ship in ipairs(merc_colors) do
    ALL_CARDS[ship["name"]] = ship
  end

  -- The "Nones" for StealthNeedle and stealth tower to copy
  ALL_CARDS["NoneShip"] = {
    name = "NoneShip",
    type = SHIP,
    cost = 0,
    factions = {UA},
    effects = {},
    jsobj = {},
  }
  ALL_CARDS["NoneBase"] = {
    name = "NoneBase",
    type = OUTPOST,
    cost = 0,
    factions = {UA},
    effects = {},
    jsobj = {},
  }

  sanityCheckDecks()
  loadCardAssets()
end

function convertCustomCardnames(names, types)
  -- names is a comma-separated list.
  if not names then return true, {} end
  names = names:gsub("[^%w,]","")
  if names == "" then return true, {} end
  local good = true
  local allcards = {}
  local goodtypes = {}
  if not types or #types == 0 then types = {SHIP, OUTPOST, BASE, HERO} end
  for _, tname in ipairs(types) do
    goodtypes[tname] = true
  end
  for name in names:gmatch("[^,]+") do
    local nn = normalize(name)
    local cardname = ALL_CARD_NAMEMAP[nn]
    if cardname and goodtypes[ALL_CARDS[cardname].type] then
      table.insert(allcards, cardname)
    else
      good = false
    end
  end

  return good, allcards
end

function loadCardAssets()
  -- And now load the assets.
  for didx, idef in ipairs(CARDASSETS) do
    local deckid = 70 + didx -- I dunno any way to really make it unique.
    local deckjs = {
      FaceURL = idef.uri,
      BackURL = "http://i.imgur.com/sNrxEY1.jpg",
      NumWidth = idef.cols,
      NumHeight = idef.rows,
      BackIsHidden = true,
      UniqueBack = false,
    }
    local decksjs = {[tostring(deckid)] = deckjs}
    DECK_JSONS[tostring(deckid)] = deckjs

    assert(type(idef.uri) == 'string', sprintf("uri for asset %d is not a string", didx))
    assert(type(idef.rows) == 'number', sprintf("rows for asset %d is not a number", didx))
    assert(type(idef.cols) == 'number', sprintf("cols for asset %d is not a number", didx))
    assert(type(idef.cards) == 'table', sprintf("cards for asset %d is not a table", didx))

    local count = 0
    for cidx = 1,(idef.rows*idef.cols),1 do
      local cardname = idef.cards[cidx]
      -- A nil cardname means a duplicate picture or unused picture in the
      -- card sheet.
      if cardname ~= nil then
        local cardid = (deckid * 100) + cidx - 1
        count = count + 1
        local card = ALL_CARDS[cardname]
        assert(card ~= nil, sprintf("Invalid card in assets: %s", tostring(cardname)))
        ALL_CARD_NAMEMAP[normalize(cardname)] = cardname
        card["cardid"] = cardid
        card["jsobj"] = ttsJSObject({
          Name = "Card",
          Nickname = cardname,
          HideWhenFaceDown = true,
          Hands = true,
          CardID = cardid,
          SidewaysCard = false,
          CustomDeck = decksjs,
          Snap = true,
        })
      end
    end
  end
end

MISSING_CARDS = {}
function sanityCheckDecks()
  for dname, deck in pairs(DECKS) do
    for _, cardname in ipairs(deck) do
      if not ALL_CARDS[cardname] then
        MISSING_CARDS[dname] = MISSING_CARDS[dname] or {}
        MISSING_CARDS[dname][cardname] = true
      end
    end
  end
  -- AVAILABLE_DECKS must all be valid and have nothing missing.
  for _, ad in ipairs(AVAILABLE_DECKS) do
    if not DECKS[ad.name] then
      die("Deck %s does not exist in DECKS?", ad.name)
    end
    if MISSING_CARDS[ad.name] then
      local cnames = {}
      for v in pairs(MISSING_CARDS[ad.name]) do
        table.insert(cnames, v)
      end
      die("Deck %s marked available has missing cards: %s!",
          ad.name, table.concat(cnames, ","))
    end
  end
end

function printMissingCards()
  for dname, cards in pairs(MISSING_CARDS) do
    local cnames = {}
    for v in pairs(cards) do
      table.insert(cnames, v)
    end
    printf("%s: %s", dname, table.concat(cnames, ", "))
  end
end

function checkCardInfo(cardinfo)
  local name, cardtype, factions, cost, effects = unpack(cardinfo)

  assert(type(name) == "string", sprintf("%s.name must be a string", tostring(name)))

  local playablecard = ALL_CARD_TYPES[cardtype]
  assert(playablecard ~= nil, sprintf("loadCards '%s' Unknown cardtype: %s",
         tostring(name), tostring(cardtype)))

  if playablecard then
    assert(type(effects) == "table", sprintf("%s.effects must be a table", name))
    assert(type(cost) == "number", sprintf("%s.cost must be a table", name))
    assert(type(factions) == "table", sprintf("%s.factions must be a table of strings", name))
    assert(type(factions[1]) == "string", sprintf("%s.factions must be a table of strings", name))
  end

  if cardtype == BASE or cardtype == OUTPOST then
    assert(effects["def"] ~= nil, sprintf("%s (%s) missing defense", name, cardtype))
  end
  return true
end

function makeDeckJSON(cardnames, owner)
  local deckjs = ttsJSObject({
    Name = "Deck",
    Nickname = "",
    Description = "",
    HideWhenFaceDown = true,
    Hands = false,
  })

  -- deckids is a misnomer: It's all the CardIDs.
  local deckids = {}
  local contents = {}

  for _, cardname in ipairs(cardnames) do
    local cdef = ALL_CARDS[cardname]
    assert(cdef ~= nil, sprintf("Invalid cardname %s", cardname))
    assert(cdef.jsobj ~= nil, sprintf("No jsobj for %s?", cardname))

    local cjs = duplicate(cdef.jsobj)
    cjs["Description"] = owner
    contents[#contents+1] = cjs
    deckids[#deckids+1] = cjs["CardID"]
  end

  deckjs["DeckIDs"] = deckids
  deckjs["ContainedObjects"] = contents

  return deckjs
end

