function spawnExplorer(newgame)
  spawnCard({
    cardname = "Explorer",
    position = PDATA["explorerpos"],
    rotation = {x=0.0, y=180.0, z=0.0},
    owner = "X",
  })
  updatePlayState()
end

function spawnCardsForPlayer(color, names, location)
  local pdata = PDATA[color]
  local rot = {x=0.0, y=180.0, z=180.0}
  local pos = pdata.deckloc

  if location == TO_DISCARD then
    pos = pdata.discardloc
    rot.z = 0.0
  elseif location == TO_HAND then
    pos = PLAYER_ZONE[color].getPosition()
  end

  for _, name in ipairs(names) do
    spawnCard({
      cardname = name,
      position = pos,
      rotation = rot,
      owner = color,
    })
  end
  updatePlayState()
end

function spawnDeckAt(owner, cards, params)
  local fulldeckjs = makeDeckJSON(cards, owner)

  local args = {
     json = JSON.encode(fulldeckjs),
     rotation = {x=0, y=270.0, z=180.0},
     scale = {x=CARDSCALE, y=1.0, z=CARDSCALE},
     sound = false,
  }

  for k, v in pairs(params) do
    args[k] = v
  end

  spawnObjectJSON(args)
end

function respawnDeckFrom(color, grouplist, params)
  local cardnames = {}
  for _, obj in ipairs(grouplist) do
    if obj.tag == "Card" then
      table.insert(cardnames, obj.getName())
      destroyCard(obj)
    elseif obj.tag == "Deck" then
      for _, cdef in ipairs(obj.getObjects()) do
        table.insert(cardnames, cdef["name"])
      end
      destroyCard(obj)
    else
      die("Trying to group a %s with cards into new deck?", obj.tag)
    end
  end

  local rot = {
    x = 0.0,
    y = PDATA[color]["yrot"],
    z = 0.0,
  }
  if params.is_face_down then rot["z"] = 180.0 end

  -- deck.shuffle() should do it, but just in case that actually waits
  -- a frame or so ...
  shuffle(cardnames)

  spawnDeckAt(color, cardnames, {
    position = params.position,
    rotation = rot,
    callback_function = params.callback,
  })
end

function dumpHand(color, inplay)
  local hand = {}
  local allcards = Player[color].getHandObjects()

  if not allcards or #allcards == 0 then return {} end

  local zone = PLAYER_ZONE[color]
  if inplay then
    zone = GameZones.PLAY
  end

  -- A bit of scatter to deal with TTS joining cards into decks.
  local pzs = zone.getScale()
  local xoff = (pzs["x"] * 0.9) / #allcards
  local xleft = 0 - (pzs["x"] / 2)
  local pos = zone.getPosition()
  for idx, card in ipairs(allcards) do
    pos["x"] = xleft + xoff*idx
    card.setPosition(pos)
    hand[#hand+1] = card
  end

  return hand
end

function spawnBases(color, cardnames)
  local zone = PLAYER_ZONE[color]

  -- A bit of scatter to deal with TTS joining cards into decks.
  local pzs = zone.getScale()
  local xoff = (pzs["x"] * 0.9) / #cardnames
  local xleft = 0 - (pzs["x"] / 2)
  local pos = zone.getPosition()

  local cardobjects = {}

  for idx, cardname in ipairs(cardnames) do
    pos["x"] = xleft + xoff * (idx - 1)
    local params = {
      cardname = cardname,
      position = pos,
      rotation = {x=0.0, y=90.0, z=0.0},
      owner = color,
      callback = function(o)
        table.insert(cardobjects, o)
        renderBases(color, cardobjects)
      end,
      locked = true
    }
    spawnCard(params)
  end
end

function spawnHand(color, cards)
  local fulldeckjs = makeDeckJSON(cards, color)

  local args = {
     json = JSON.encode(fulldeckjs),
     position = PLAYER_ZONE[color].getPosition(),
     rotation = {x=0, y=270.0, z=180.0},
     scale = {x=CARDSCALE, y=1.0, z=CARDSCALE},
     sound = false,
     callback_function = function(obj) return obj.deal(#cards, color) end,
  }
  spawnObjectJSON(args)
end

function spawnTradeDeck(allcards)
  shuffle(allcards)

  local pos = GameZones.TRADE_DECK.getPosition()
  pos["y"] = YFLAT
  spawnDeckAt("T", allcards, {
    position = pos,
    rotation = {x=0, y=180.0, z=180.0},
    callback_function = qWaitFor("tradelock", function(obj)
      obj.setLock(true)
    end)
  })
end

function spawnCard(pargs)
  local params = {
    cardname = nil,
    position = {x=0.0, y=0.0, z=0.0},
    rotation = {x=0.0, y=180.0, z=0.0},
    owner = nil,
    callback = nil,
  }
  for k, v in pairs(pargs) do
    params[k] = v
  end

  if params["facedown"] then
    params["rotation"]["z"] = 180.0
  end

  local cdef = ALL_CARDS[params["cardname"]]
  if not cdef then
    die("BUG: Cannot find card named '%s'", params["cardname"])
    return nil
  end
  local cjs = duplicate(cdef["jsobj"])
  cjs["Description"] = params["owner"]
  cjs["Locked"] = true

  return spawnObjectJSON({
     json = JSON.encode(cjs),
     position = params["position"],
     rotation = params["rotation"],
     scale = {x=CARDSCALE, y=1.0, z=CARDSCALE},
     sound = false,
     callback_function = qWaitFor("spawnCard", function(obj)
       if params["callback"] then params["callback"](obj) end
       obj.setLock(false)
     end),
  })
end

function sendToHand(color, obj)
  local ht = Player[color].getHandTransform()
  local rot = {
    x=10.0,
    y=PDATA[color]["yrot"],
    z=0.0,
  }
  if rot["y"] > 30 then
    rot["x"] = -10.0
  end
  obj.setRotationSmooth(rot, false, true)
  obj.setPositionSmooth(ht["position"], false, true)
end


function renderShips(ships)
  ships = filterCards(ships, function(o,c) return not isScrapped(o) end)
  renderCardGrid(ships, GameZones.PLAY, 3, 8)
end

function renderBases(color, allbases)
  -- Another misnomer, heroes + etc too.
  -- split: outposts, bases, other.
  local grid = {{},{},{}}

  for _, base in ipairs(allbases) do
    if base.tag ~= "Card" then
      return die("I don't know how to deal with non-Cards in base area")
    else
      local card = ALL_CARDS[base.getName()]
      if not card then
        return die("Unknown card in base area: " .. base.getName())
      end
      local rownum = 3
      if card["type"] == OUTPOST then rownum = 1 end
      if card["type"] == BASE then rownum = 2 end
      table.insert(grid[rownum], base)
    end
  end
  if #grid[1] > 0 then
    renderCardGrid(grid[1], PLAYER_ZONE[color], 1, 1000, 0.3)
  end
  if #grid[2] > 0 then
    renderCardGrid(grid[2], PLAYER_ZONE[color], 1, 1000, 0.05)
  end
  if #grid[3] > 0 then
    renderCardGrid(grid[3], PLAYER_ZONE[color], 1, 1000, -0.3)
  end
end

function renderCardGrid(cards, zone, maxrows, max_per_row, start_zoff)
  if start_zoff == nil then
    start_zoff = 0.0
  end
  local zonerot = zone.getRotation()
  local num_cards = #cards
  local num_rows = math.ceil(num_cards / max_per_row)
  local cards_per_row = math.min(max_per_row, num_cards)
  if num_rows > maxrows then
    num_rows = maxrows
    cards_per_row = math.ceil(num_cards / maxrows)
  end
  -- For columns and rows, we divide 1.0 by (num_cards). Then leftmost is
  -- (-0.5 + shipwidth/2.0), adding shipwidth for each.
  -- topmost is positive, leftmost is negative, so math is flipped for
  -- col+row
  local rowdiff = 1.0 / num_rows
  local rowtop = -0.5 + (rowdiff/2.0)
  local coldiff = 1.0 / cards_per_row
  local colleft = -0.5 + (coldiff/2.0)

  for idx, card in ipairs(cards) do
    card.setLock(true)
    local cardrot = 180.0
    local cdef = ALL_CARDS[card.getName()]
    if cdef then
      if ORIENTATIONS[cdef["type"]] then
        cardrot = 90
      end
    end
    -- Weird math thanks to lua's starting with 1.
    local rowi = math.floor((idx-1) / cards_per_row)
    local coli = math.floor((idx-1) % cards_per_row)
    local zoff = start_zoff + (rowtop + (rowi * rowdiff))
    local xoff = colleft + (coldiff * coli)
    local pos = getPositionInZone(zone, xoff, zoff)
    moveThen(card, pos)
    card.setRotationSmooth({x=0.0, y=((cardrot + zonerot["y"]) % 360.0), z=0.0})
  end
  waitUntilSettled()
end

function mergeMays(lst)
  local mays = newMays()
  if #lst == 1 then return lst[1] end

  for _, may in ipairs(lst) do
    for _, counter in ipairs({"destroybase"}) do
      mays[counter] = mays[counter] + may[counter]
    end
    for _, tbl in ipairs({"carduses", "scrap"}) do
      for _, val in ipairs(may[tbl]) do
        table.insert(mays[tbl], val)
      end
    end
  end
  return mays
end

function highlightInteractables()
  clearHighlights()
  if GAMESTATE["state"] ~= RUNNING then return end
  local team = GAMESTATE["playing"]
  if not team then return end

  local allmays = {}
  for color, _ in pairs(getCurrentPlayers()) do
    allmays[#allmays+1] = GAMESTATE["players"][color]["mays"]
  end
  local mays = mergeMays(allmays)
  if not getPlayState("trade") then return end

  -- Interactables are:
  -- * Destroyable outposts and bases. (red outline)
  -- * Damageable players / authority. (red outline) -- (not a card)
  local targets = getPlayState("targets")
  local dam = getPlayState("damage")
  if targets then
    for guid, def in pairs(targets) do
      -- if defense is a number, it's a card GUID.
      -- if it's true, then guid is a team name.
      if def == true then
        local teamname = guid
        if dam > 0 then
          getTeamAuthToken(teamname).highlightOn(COLORS["ATTACK"])
        end
      elseif dam >= def or (mays["destroybase"] > 0) then
        getObjectFromGUID(guid).highlightOn(COLORS["ATTACK"])
      end
    end
  end
  -- * Buyable trade items and explorer
  local trade = getPlayState("trade")
  local buyable = filterCards(getTradeCards(), function(_,c) return c["cost"] <= trade end)
  highlightObjects(buyable, COLORS["BUYABLE"])

  for color, _ in pairs(getCurrentPlayers()) do
    local psis = getPlayState(color, "interactables")
    if psis then
      for guid, types in pairs(psis) do
        -- choose, scrap, activate, destroybase
        if not isScrapped(guid) then
          local obj = getObjectFromGUID(guid)
          if obj then
            if hasAnyBut(types, "scrap") then
              obj.highlightOn(COLORS["INTERACTABLE"])
            else
              obj.highlightOn(COLORS["SCRAPPABLE"])
            end
          end
        end
      end
    end
  end
end

function clearHighlights()
  for _, obj in ipairs(getAllObjects()) do
    obj.highlightOff()
  end
end

function highlightObjects(list, color)
  if not list then return end
  for _, obj in ipairs(list) do
    obj.highlightOn(color)
  end
end

function getLocOfCard(color, obj, usedesc, vagueplay)
  local pdata = PDATA[color]
  if isMember(Player[color].getHandObjects(), obj) then
    return S_HAND
  elseif usedesc and obj.getDescription() == "T" then
    return S_TRADE
  elseif usedesc and obj.getDescription() == "X" then
    return S_EXPLORER
  elseif isInside(GameZones.DISCARD, obj) then
    return S_DISCARD
  elseif isInside(PLAYER_DECK_ZONE[color], obj) then
    if isNearby(pdata["discardloc"], obj.getPosition(), 4) then
      return S_PLAYER_DISCARD
    elseif isNearby(pdata["deckloc"], obj.getPosition(), 4) then
      return S_PLAYER_DECK
    elseif obj.is_face_down then
      return S_PLAYER_DECK
    else
      return S_PLAYER_DISCARD
    end
  elseif isInside(GameZones.PLAY, obj) then
    return S_PLAY
  elseif isInside(PLAYER_ZONE[color], obj) then
    return S_PLAYER
  elseif isInside(GameZones.SCRAP, obj) then
    return S_SCRAP
  elseif vagueplay then
    for col, zone in pairs(PLAYER_DECK_ZONE) do
      if isInside(zone, obj) then
        if obj.is_face_down then
          return sprintf("%s's player deck", col)
        else
          return sprintf("%s's discard pile", col)
        end
      end
    end
    if isNearby(GameZones.SCRAP.getPosition(), obj.getPosition(), 30) then
      return S_UNKNOWN
    end

    if isNearby(GameZones.DISCARD.getPosition(), obj.getPosition(), 30) then
      return S_UNKNOWN
    end
    return S_PLAY
  end
  return S_UNKNOWN
end

function getBasesInPlay(color)
  local cards = {}
  for _, obj in ipairs(PLAYER_ZONE[color].getObjects()) do
    if not obj.is_face_down then
      if obj.tag == "Card" and obj.getDescription() == color
          and not getPlayState("destroyed", obj.getGUID())
          and not isScrapped(obj.getGUID()) then
        cards[#cards+1] = obj
      end
    end
  end
  return cards
end

function getTeamAuthToken(teamname)
  for _, obj in ipairs(getAllObjects()) do
    if obj.tag == "Tile" and obj.getDescription() == teamname then
      return obj
    end
  end
  return nil
end

function moveToDeckTop(color, cards, docopy)
  local pdata = PDATA[color]
  local deckloc = pdata["deckloc"]

  for _, card in ipairs(cards) do
    if not card.is_face_down then
      card.setRotationSmooth({x=0.0, y=pdata["yrot"], z=180.0})
    end
    moveThen(card, deckloc)
  end
  waitUntilSettled(function() groupDecks(color) end)
end

function groupDecks(color)
  local discs = {}
  local decks = {}
  for _, obj in ipairs(PLAYER_DECK_ZONE[color].getObjects()) do
    if isGameObject(obj) then
      if obj.is_face_down then
        table.insert(decks, obj)
      else
        table.insert(discs, obj)
      end
    end
  end
  if discs and #discs > 1 then
    group(discs)
  end
  if decks and #decks > 1 then
    group(decks)
  end
  if #decks > 1 or #discs > 1 then
    waitUntilSettled()
  end
end

function moveDiscardToDeck(color, params)
  local togroup = {}
  local pdata = PDATA[color]
  local pos = pdata["discardloc"]

  for _, obj in ipairs(PLAYER_DECK_ZONE[color].getObjects()) do
    if isNearby(pos, obj.getPosition(), 3) then
      if ((obj.tag == "Card" or obj.tag == "Deck")
          and obj.is_face_down == false) then
        table.insert(togroup, obj)
      end
    end
  end

  respawnDeckFrom(color, togroup, {
    position = pdata.deckloc,
    is_face_down = true,
    callback = qWaitFor("movediscardtodeck", function(deck)
      deck.shuffle()
      if params["callback"] then
        params["callback"](deck)
      end
    end)
  })
end

function discardAllCards(color, allcards)
  local pdata = PDATA[color]

  moveAllGroupThen(allcards, {
    position = pdata["discardloc"],
    rotation = {x=0.0, y=pdata["yrot"], z=0.0},
    callback = qWaitFor("moveallgroupthen", function() groupDecks(color) end),
  })
end

function dealFrom(deck, color, count)
  -- Deal from deck, return count not dealt.
  if deck then
    local ncards = deck.getQuantity()
    -- A "Card" has quantity -1?
    if ncards < 1 then ncards = 1 end
    ncards = math.min(ncards, count)
    count = count - ncards
    deck.deal(ncards, color)
  end
  return count
end

function drawToPlayer(color, count)
  local pdata = PDATA[color]
  announce(color, "drawing %d", count)
  if pdata["isdrawing"] > 0 then
    die("Adding %d more to draw?", count)
    return
  end

  -- We need to be careful, if deck is 1 card, and we draw immediately after,
  -- that double-deals the same card. Bleh!
  local deck = getPlayerDeckAt(color, pdata["deckloc"], true)
  local discard = getPlayerDeckAt(color, pdata["discardloc"], false)

  waitUntilSettled(function()
    count = dealFrom(deck, color, count)
    if discard and count > 0 then
      moveDiscardToDeck(color, {
        callback = function(newdeck)
          waitUntilSettled(function()
            dealFrom(newdeck, color, count)
          end)
        end,
      })
    end
  end)
end

function discardToPlayer(color, obj)
  local pdata = PDATA[color]
  obj.setPositionSmooth(pdata["discardloc"], false, true)
  obj.setRotationSmooth(pdata["rot"], false, true)
end

function getPlayerDeckAt(color, pos, is_face_down)
  -- We define the pile as anything within 4 units of our calculated
  -- discard pile position.
  for _, obj in ipairs(PLAYER_DECK_ZONE[color].getObjects()) do
    if isNearby(pos, obj.getPosition(), 6) then
      if ((obj.tag == "Card" or obj.tag == "Deck")
          and obj.is_face_down == is_face_down) then
        return obj
      end
    end
  end
end

function getTradeDeck()
  local tdos = GameZones.TRADE_DECK.getObjects()
  -- It also often includes the board itself, so bleh.
  for _, obj in ipairs(tdos) do
    if obj.tag == "Card" or obj.tag == "Deck" then
      return obj
    end
  end
end

function moveAllGroupThen(objs, params)
  local position = params.position
  local rotation = params.rotation
  local callback = params.callback

  for _, obj in ipairs(objs) do
    obj.drop()
    obj.setLock(true)
    obj.use_hands = false
    obj.setPositionSmooth(position, false, true)
    obj.setRotationSmooth(rotation, false, true)
  end
  local cleanup = function()
    for _, obj in ipairs(objs) do
      obj.use_hands = true
      obj.setLock(false)
    end
    waitUntilSettled(function()
      if callback then callback(objs) end
    end)
  end
  greenWait({
    condition = function()
      for _, obj in ipairs(objs) do
        if obj.isSmoothMoving() then return false end
      end
      return true
    end,
    callback = qWaitFor("moveAllGroupThen", cleanup),
  })
end

function moveThen(obj, pos, callback)
  obj.drop()
  obj.setLock(true)
  obj.use_hands = false
  obj.setPositionSmooth(pos, false, true)
  local cleanup = function()
    obj.use_hands = true
    obj.setLock(false)
    if callback then callback(obj) end
  end
  greenWait({
    condition = function() return not obj.isSmoothMoving() end,
    callback = qWaitFor("moveThen", cleanup),
  })
end
