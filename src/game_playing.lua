function doPlayAll(color)
  local player = Player[color]
  if not isPlaying(color) then return end

  local allcards = player.getHandObjects()

  if not allcards or #allcards < 1 then
    return
  end

  -- I'm lazy, if we can play one card, we can play 'em all, so just checking
  -- the permissions for one card using getPlayerCardUse

  local testobj = allcards[1]
  local can, cb = getPlayerCardUse(color, testobj, S_HAND, S_PLAY)

  if can then
    -- I should use doPlayCard, but that has a tendency to join cards into
    -- a deck at present.
    for _, card in ipairs(dumpHand(color, true)) do
      playCards(color, {card}, nil, nil)
    end
  elseif cb then
    warnPlayer(color, "Unable: " .. cb)
  end
end

function makeDiscard(color, targetColor, cardname, count)
  addMust(targetColor, "discard", count)
  logEffect(targetColor, cardname, "is discarding %d", count)
  showIndicator(PLAYER_ZONE[targetColor].getPosition(), "discard")
  announce(color, "makes %s discard %d", playerName(targetColor), count)
end

function playCards(color, objs, choice, forcecardname)
  local newships = {}
  local newbases = {}

  if (choice or forcecardname) and #objs ~= 1 then
    return die("choice or forcecardname and #objs ~= 1?!")
  end

  for _, obj in ipairs(objs) do
    if obj.tag ~= "Card" then return whine("Can't play '" .. obj.tag .. "', only Card types") end
    obj.drop()

    local cardname = obj.getName()
    if forcecardname then
      -- For stealth needle.
      cardname = forcecardname
    end
    local cdef = ALL_CARDS[cardname]
    if not cdef then return whine("Don't know what to do with '" .. cardname .. "'") end

    local ctype = cdef["type"]

    if applyCard(color, cardname, obj, true, choice) then
      if ctype == SHIP then
        newships[#newships+1] = obj
      elseif ctype == BASE or ctype == OUTPOST or ctype == HERO then
        newbases[#newbases+1] = obj
      else
        return die("Don't know how to play '" .. ctype .. "'")
      end
    else
      sendToHand(color, obj)
    end
  end
  if #newships then
    addShipsToPlay(color, newships)
  end
  if #newbases then
    addBasesToPlay(color, newbases)
  end
end

function addShipsToPlay(color, objs)
  local allguids = getPlayState("ships")
  local allships = {}
  local newguids = {}
  for _, guid in ipairs(allguids) do
    local ship = getObjectFromGUID(guid)
    if ship then
      newguids[#newguids+1] = guid
      allships[#allships+1] = ship
    end
  end

  for _, obj in ipairs(objs) do
    newguids[#newguids+1] = obj.getGUID()
    allships[#allships+1] = obj
  end
  setPlayState("ships", newguids)
  renderShips(allships)
end

function applyCurrentBaseEffects(color)
  -- A bit of a misnomer, we use "Base" to cover everything that isn't a ship
  -- or event: Outpost, Base, Hero, Gambit, Mission
  local existing = getBasesInPlay(color)

  if not existing then return end

  -- This can include decks of bases (!)
  local baseguids = {}
  for _, base in ipairs(existing) do
    local cardname = base.getName()
    applyCard(color, cardname, base, false)
    baseguids[#baseguids+1] = base.getGUID()
  end
  setPlayState(color, "other", baseguids)
end

function addBasesToPlay(color, objs)
  local allguids = getPlayState(color, "other")
  local allbases = {}
  local newguids = {}

  for _, guid in ipairs(allguids) do
    if not isScrapped(guid) then
      local base = getObjectFromGUID(guid)
      if base then
        newguids[#newguids+1] = guid
        allbases[#allbases+1] = base
      end
    end
  end

  for _, obj in ipairs(objs) do
    newguids[#newguids+1] = obj.getGUID()
    allbases[#allbases+1] = obj
  end
  setPlayState(color, "other", newguids)


  renderBases(color, allbases)
end

function rebuildAllies(color)
  -- Called on in-play cards being scrapped.
  local allies = {}
  allies[BB] = false
  allies[TF] = false
  allies[SE] = false
  allies[MC] = false
  -- I don't think anything uses UA as a faction ...
  allies[UA] = false

  for guid, cardname in pairs(getPlayState(color, "played")) do
    local obj = getObjectFromGUID(guid)
    if not isScrapped(guid) then
      local cdef = ALL_CARDS[cardname]
      for _, faction in ipairs(cdef["factions"]) do
        allies[faction] = true
      end
      if obj and obj.getName() ~= cardname then
        -- Stealth Tower / Needle
        local rdef = ALL_CARDS[obj.getName()]
        for _, faction in ipairs(rdef["factions"]) do
          allies[faction] = true
        end
      end
    end
  end

  for faction, val in pairs(getPlayState(color, "effectallies")) do
    if val then
      allies[faction] = true
    end
  end

  setPlayState(color, "allies", allies)
end

function applyCard(color, cardname, obj, isnew, choice)
  local card = ALL_CARDS[cardname]
  if not card then
    die("I don't have card " .. cardname)
    return false
  end
  return applyEffects(color, obj, card, card["effects"], obj.getPosition(), false, isnew, choice)
end

function playStealthNeedle(color, obj, sels)
  if not sels or #sels == 0 then
    replayWithChoice(color, "NoneShip", obj, true, nil)
  else
    replayWithChoice(color, sels[1].getName(), obj, true, nil)
  end
end

function playStealthTower(color, obj, sels)
  local psi = getPlayState(color, "interactables")

  psi[obj.getGUID()]["stealthtower"] = nil
  if not hasAny(psi[obj.getGUID()]) then
    psi[obj.getGUID()] = nil
  end

  local cardname = "NoneBase"
  if sels and #sels == 1 then
    cardname = sels[1].getName()
  end
  local card = ALL_CARDS[cardname]
  applyEffects(color, obj, card, card["effects"], obj.getPosition(), false, true, nil)
end

function replayWithChoice(color, cardname, obj, isnew, choice)
  if not isPlaying(color) then
    whine("errr... wrong Turn replay?")
    return
  end

  local pzs = GameZones.PLAY.getScale()
  local xoff = (pzs["x"] * 0.9) / 7.5
  local xleft = 0 - (pzs["x"] / 2)
  local pos = GameZones.PLAY.getPosition()
  pos["x"] = xleft + xoff
  pos["z"] = pos["z"] - xoff

  obj.drop()
  obj.setPosition(pos)

  playCards(color, {obj}, choice, cardname)
end

function addMayUse(color, obj, params)
  createCardUse(obj, params)
  local mayuses = GAMESTATE.players[color].mays.carduses
  table.insert(mayuses, params)
end

function addMustUse(color, obj, params)
  local use = createCardUse(obj, params)
  local musts = GAMESTATE.players[color].musts
  table.insert(musts, {"carduse", use, nil})
end

function describeCardUse(use, youmay)
  -- Target:
  -- "scrap", "discard", etc.
  if youmay == nil then
    if use.must then
      youmay = "must"
    else
      youmay = "may"
    end
  end
  local action = "move %s to " .. use.to
  if use.to == TO_SCRAP then
    action = "scrap %s"
  elseif use.to == TO_HAND then
    action = "return %s to hand"
  elseif use.to == TO_DISCARD then
    action = "discard %s"
  elseif use.to == TO_TOP then
    action = "put %s on top of your deck"
  elseif use.to == TO_PLAY then
    action = "put %s into play"
  end

  -- What
  if use.guids then
    -- Special case, using specific cards.
    local namelist = guidsToNames(use.guids)
    local desc = concatAnd(namelist, "or")
    if use.count > 1 then
      desc = sprintf("%d of %s", use.count, concatAnd(namelist, "or"))
    end
    return sprintf("%s %s", youmay, desc)
  end

  local carddesc = ""
  local checks = use.checks
  if (not checks) and use.check then checks = {use.check} end
  if checks and #checks > 0 then
    for _, check in ipairs(checks) do
      if carddesc ~= "" then carddesc = carddesc .. "; " end
      if check[1] == "factions" then
        carddesc = carddesc .. concatAnd(check[2], "or")
      elseif check[1] == "cost" then
        carddesc = carddesc .. sprintf("value %d or less", check[2])
      elseif check[1] == "type" then
        carddesc = carddesc .. concatAnd(check[2], "or")
      else
        carddesc = carddesc .. "(undescribed check)"
      end
    end
    carddesc = carddesc .. " "
  end

  if use.count < 0 then
    carddesc = sprintf("any number of %scards", carddesc)
  elseif use.count > 1 then
    carddesc = sprintf("up to %d %scards", use.count, carddesc)
  else
    carddesc = sprintf("a %scard", carddesc)
  end

  local desc = sprintf("%s from %s", carddesc, concatAnd(use.from, "or"))

  local fulldesc = sprintf(action, desc)

  if use.effects then
    if use.count > 1 then
      return sprintf("%s %s to %s (each)", youmay, fulldesc, describeEffects(use.effects))
    else
      return sprintf("%s %s to %s", youmay, fulldesc, describeEffects(use.effects))
    end
  end
  return sprintf("%s %s", youmay, fulldesc)
end

function createCardUse(obj, params)
  -- carduses is newer version of recycle, scrapcycle, scrap, discardfor, tradescrap, etc.
  --
  -- Format: It is a list of:
  -- {
  --   -- REQUIRED:
  --   from = {S_HAND,S_DISCARD, etc},
  --   to = TO_HAND, TO_... etc.
  --   id = "name",  -- Uses w/ same ID are considered identical, so if two
  --                    cards allow "scrapfromhandordiscard", then only one
  --                    is returned by findCardUses.
  --   complexity = # -- For effects of same ID, complexity is used to sort
  --                     for preferred matches. e.g: Death World, Brain World
  --                     and Junk Yard all in effect, and you scrap a trade fed
  --                     card? Prefer Death World. Scrap a blob card? Prefer Brain
  --                     World. Only fall back to Junk Yard if nothing else works.
  --                     (Auto Calculated if it doesn't exist.)
  --
  --   -- OPTIONAL:
  --   count = 1, -- how many times can it be used? Defaults to 1
  --   reason = "GUID", -- if exists and is scrapped, this is no longer valid.
  --   guids = {"GUID"}, -- only eligible for a given set of GUIDS
  --   check = {"funcname", args}, -- additional check.
  --   checks = {{"funcname", args}}, -- multiple checks (generated from check)
  --   effects = {}, -- optional, effects to apply upon success
  --   cardmessage = "scraps %s", -- optional, defaults to message based
  --                 on destination.
  -- }
  assert(type(params["from"]) == 'table', "cardUse requires 'from' list")
  assert(type(params["to"]) == 'string', "cardUse requires 'to' string")
  assert(type(params["id"]) == 'string', "cardUse requires 'id' string")
  local complexity = 0
  if not params["count"] then params["count"] = 1 end
  if params["check"] then
    if not params["checks"] then
      params["checks"] = {}
    end
    table.insert(params["checks"], params["check"])
    params["check"] = nil
  end
  if params.checks then
    complexity = complexity + 5 * #params.checks
  end
  if params.effects then
    -- Having any effects makes it more useful.
    complexity = complexity + 10
  end
  if params.guids and #params.guids > 0 then
    -- If it needs guid matches, it's got super high complexity.
    complexity = complexity + 20
  end
  if obj then
    params["reason"] = obj.getGUID()
  end
  params["complexity"] = complexity
  return params
end

function applyCardUse(color, use, source, dest, card, obj)
  if use.reason and isScrapped(use.reason) then return false end
  if use.effects ~= nil then
    applyEffects(color, obj, card, use.effects, obj.getPosition(), use.to or dest, false)
  end
  local msg = use["cardmessage"]
  if not msg then
    if use.to == TO_SCRAP then
      msg = "scraps %s"
    elseif use.to == TO_DISCARD then
      msg = "discards %s"
    elseif use.to == TO_TOP then
      msg = "returns %s to top of deck"
    elseif use.to == TO_HAND then
      msg = "takes %s to hand"
    elseif dest == S_SCRAP then
      msg = "scraps %s"
    elseif dest == S_DISCARD then
      msg = "discards %s"
    end
  end
  announce(color, msg, card.name)
  sendCardTo(color, obj, use.to)
end

function sendCardTo(color, obj, sendto)
  if sendto == TO_DISCARD then
    discardAllCards(color, {obj}, false)
  elseif sendto == TO_SCRAP then
    sendCardToScrap(color, obj)
  elseif sendto == TO_PLAY then
    playCards(color, {obj})
  elseif sendto == TO_HAND then
    sendToHand(color, obj)
  elseif sendto == TO_TOP then
    moveToDeckTop(color, {obj}, false)
  else
    return die("Unknown sendto in sendCardTo ?")
  end
end

TO_DESTS = {
  [TO_PLAY] = {S_PLAY, S_PLAYER},
  [TO_DISCARD] = {S_DISCARD},
  [TO_SCRAP] = {S_SCRAP},
  [TO_HAND] = {S_PLAY, S_HAND, S_PLAYER},
  [TO_TOP] = {S_PLAYER_DECK, S_PLAYER_DISCARD, S_PLAYER},
}

function canUseCardUse(use, source, dest, card, obj)
  if use.reason and isScrapped(use.reason) then return false end
  if not isMember(use.from, source) then return false end
  -- A dest of "nil" is the first part of drag.
  if dest ~= nil and not isMember(TO_DESTS[use.to], dest) then return false end
  if use.guids ~= nil and not isMember(use.guids, obj.getGUID()) then
    return false
  end
  if use.checks then
    for _, check in ipairs(use.checks) do
      if check[1] == "factions" then
        local hasfac = false
        for _, fac in ipairs(card.factions) do
          if isMember(check[2], fac) then
            hasfac = true
          end
        end
        if not hasfac then return false end
      elseif check[1] == "type" then
        if not isMember(check[2], card.type) then return false end
      elseif check[1] == "cost" then
        if card.cost > check[2] then return false end
      else
        whine("Don't know carduse check %s", check[1])
      end
    end
  end
  return true
end

function findCardUses(list, source, dest, obj)
  local card = ALL_CARDS[obj.getName()]
  if not card then return die("No card for obj in findCardUses?") end
  local found = {}
  for _, use in ipairs(list) do
    if canUseCardUse(use, source, dest, card, obj) then
      if not found[use.id] or found[use.id].complexity < use.complexity then
        found[use.id] = use
      end
    end
  end
  local ret = {}
  for _, use in pairs(found) do
    table.insert(ret, use)
  end
  return ret
end

function addMust(color, what, val)
  -- Musts is format:
  -- {what, value, has_asked_question}

  local musts = GAMESTATE.players[color].musts
  if musts and #musts > 0 and musts[#musts][1] == what then
    -- Squash adjacent musts (e.g: discard 1 discard 1 discard 1 = discard 3)
    local lastmust = musts[#musts]
    if lastmust[3] == nil then
      -- Don't modify a must already asked.
      if what == "discard" or what == "draw" then
        lastmust[2] = lastmust[2] + val
        return
      end
      if what == "scrap" then
        for _, v in ipairs(val) do
          table.insert(lastmust[2], v)
        end
        return
      end
    end
  end
  table.insert(musts, {what, val, nil})
end

function checkTag(color, tagname, count)
  return getTag(color, tagname) >= count
end

function isPlaytoBetter(a, b)
  if a == nil then return false end
  if b == nil then return true end
  if a == TO_PLAY then return true end
  if b == TO_PLAY then return false end
  if a == TO_HAND then return true end
  if b == TO_HAND then return false end
  if a == TO_TOP then return true end
  if b == TO_TOP then return false end
  return true
end

function canBuy(color, obj)
  if not (obj.getDescription() == "X" or obj.getDescription() == "T") then
    return false
  end
  if not isPlaying(color) then return false end
  local card = ALL_CARDS[obj.getName()]
  if not card then return false end

  return card["cost"] <= getPlayState("trade")
end

function doBuy(color, obj, charge, playto)
  -- And not Dubai
  if not isPlaying(color) then return end
  if charge and not canBuy(color, obj) then return end
  local card = ALL_CARDS[obj.getName()]
  if not card then return end

  local cost = 0

  if charge then
    cost = card["cost"]
    tweakPlayState("trade", function(x) return x - card["cost"] end)
  end

  local seller = obj.getDescription()

  local tradeguid = obj.getGUID()
  local cardname = obj.getName()
  obj.setDescription(color)

  local ctype = card["type"]
  if ctype == HERO then
    playto = TO_PLAY
  elseif card["effects"]["buyto"] then
    local v = card["effects"]["buyto"]
    if checkTag(color, v[1], v[2]) then
      playto = v[3]
    end
  else
    local nbts = getPlayState(color, "nextbuyto")
    local playtotype = ctype
    if ctype == BASE or ctype == OUTPOST then
      playtotype = BASES
    end
    if nbts[ANY] or nbts[playtotype] then
      if isPlaytoBetter(nbts[ANY], nbts[playtotype]) then
        playto = nbts[ANY]
      else
        playto = nbts[playtotype]
      end
      nbts[ANY] = nil
      nbts[playtotype] = nil
    end
  end

  if cost > 0 then
    announce(color, "purchases %s %s for %d trade", cardname, playto, cost)
  else
    announce(color, "acquires %s %s for free", cardname, playto)
  end

  obj.drop()
  if playto == TO_DISCARD then
    discardAllCards(color, {obj}, false)
  elseif playto == TO_PLAY then
    playCards(color, {obj})
  elseif playto == TO_HAND then
    sendToHand(color, obj)
  elseif playto == TO_TOP then
    moveToDeckTop(color, {obj}, false)
  else
    return die("Unknown playto in doBuy")
  end

  local expected = GAMESTATE["players"][color]["card_count"]
  GAMESTATE["players"][color]["card_count"] = expected + 1

  if charge then
    logEffect(color, obj.getName(), "purchased to %s", playto)
  else
    logEffect(color, obj.getName(), "acquired to %s", playto)
  end

  if seller == "X" then
    spawnExplorer()
  end

  if seller == "T" then
    refreshTradeOptions(tradeguid)
  end
end

function getTag(color, name)
  -- Special tags: running counts are a pain.
  if name == "enemy:base" then
    local oppbases = getOpponentBases(getTeamOf(color))
    return #oppbases
  elseif name == "my:base" then
    local mybases = getBasesInPlay(color)
    return #mybases
  end

  -- Normal tags:
  local tags = getPlayState(color, "tags")
  return (tags[name] or 0)
end

function addTag(color, name, desc)
  local cur = tweakPlayState(color, "tags", name, function(x) return (x or 0) + 1 end)

--      guid=obj.getGUID(),
 --     cardname=card["name"],
  --    effect=tageffect,
  local ontags = getPlayState(color, "ontags")

  if ontags[name] and #ontags[name] > 0 then
    for _, ondef in ipairs(ontags[name]) do
      local guid = ondef["guid"]
      local cardname = ondef["cardname"]
      local tageffect = ondef["effect"]

      if (ondef["limit"] < 0) or (ondef["limit"] > 0) then
        if cur >= ondef["min"] then
          if not isScrapped(guid) then
            local obj = getObjectFromGUID(guid)
            local card = ALL_CARDS[cardname]
            if card then
              applyEffects(color, obj, card, tageffect, obj.getPosition(), desc, false)
            end
          end
          if ondef["limit"] > 0 then
            ondef["limit"] = ondef["limit"] - 1
          end
        end
      end
    end
  end
end

function applyTags(color, card, isnew)
  -- On playing card: This is primarily for "check"
  local ctype = "unknown"
  if card["type"] == BASE or card["type"] == OUTPOST then
    ctype = "base"
  elseif card["type"] == SHIP then
    ctype = "ship"
  elseif card["type"] == HERO then
    ctype = "hero"
  end

  if isnew then
    addTag(color, "play:" .. ctype, "Play " .. ctype)
    addTag(color, "play:" .. card["name"], "Play " .. card["name"])
    for _, faction in ipairs(card["factions"]) do
      -- play:tf is what we use in the card definitions.
      addTag(color, "play:" .. FACTION_MAP[faction], "Play " .. faction)
      -- for Command Center ...
      addTag(color, "play:" .. ctype .. ":" .. FACTION_MAP[faction], "Play " .. faction .. " " .. ctype)
    end
  end

  addTag(color, "my:" .. ctype, "Have " .. ctype)
  addTag(color, "my:" .. card["name"], "Have " .. card["name"])
  for _, faction in ipairs(card["factions"]) do
    addTag(color, "my:" .. FACTION_MAP[faction], "Have " .. faction)
    addTag(color, "my:" .. ctype .. ":".. FACTION_MAP[faction], "Have " .. faction .. " " .. ctype)
  end
end

function triggerAllyEffects(color, factions)
  -- needs is a list of {
  --   {{factions}, effects, guid}
  -- }
  local needs = getPlayState(color, "needally")
  if needs and #needs > 0 then
    local facs = {}
    for _, faction in ipairs(factions) do
      facs[faction] = true
    end
    local newneeds = {}
    for _, need in ipairs(needs) do
      local hasally = false
      for _, fac in ipairs(need[1]) do
        if facs[fac] then hasally = true end
      end
      if hasally and not isScrapped(need[3]) then
        local obj = getObjectFromGUID(need[3])
        local cardname = obj.getName()
        local card = ALL_CARDS[cardname]
        applyEffects(color, obj, card, need[2], obj.getPosition(), "Ally", false)
      else
        table.insert(newneeds, need)
      end
    end

    setPlayState(color, "needally", newneeds)
  end
end

function doAttackEnemyCard(color, obj, source, dest, cstate)
  local card = ALL_CARDS[obj.getName()]
  local pinfo = GAMESTATE["players"][color]
  local defense = getPlayState("targets", obj.getGUID())
  if defense == nil then
    return die("No defense in doAttackEnemyCard?!")
  end

  local guid = obj.getGUID()

  -- We can target it somehow. Let's see how.
  local ways = 0
  if getPlayState("damage") >= defense then ways = 1 end
  local mays = pinfo["mays"]
  if mays["destroybase"] > 0 then ways = ways + 2 end

  if ways == 3 then
    askQuestion(guid, color, "What would you like to use?",
      {
        {"Destroy Base skill", function() destroyEnemyBase(color, obj, false, card) end },
        {"Damage", function() destroyEnemyBase(color, obj, true, card) end },
        {"Cancel", nil},
    })
  elseif ways == 1 then
    destroyEnemyBase(color, obj, true, card)
  elseif ways == 2 then
    destroyEnemyBase(color, obj, false, card)
  else
    whine("No idea how to destroy?")
  end
end

function rebuildTargets()
  local team = GAMESTATE["playing"]
  local targets = getHouseRule("getTargets", team)
  setPlayState("targets", targets)
end

function destroyEnemyBase(color, obj, is_damage, card)
  -- In case multiple players on same team attempt attacking simultaneously.
  -- (such as the dumbai)
  if getPlayState("destroyed", obj.getGUID()) then return end

  local pinfo = GAMESTATE["players"][color]
  if is_damage then
    announce(color, "deals %d damage to %s, destroying it.",
             card["effects"]["def"], card["name"])
    tweakPlayState("damage", function(x) return x - card["effects"]["def"] end)
  else
    announce(color, "destroys %s", card["name"])
    pinfo["mays"]["destroybase"] = pinfo["mays"]["destroybase"] - 1
  end

  setPlayState("destroyed", obj.getGUID(), true)
  discardAllCards(obj.getDescription(), {obj}, true)
  rebuildTargets()
end

function getPlayerCardUse(color, obj, source, dest)
  -- Thanks to the nonlinear nature of qdo: getPlayerCardUse is now
  -- used for both checking in UI (on click/pickup/etc) and
  -- verifying before taking action.
  local can, cb = getPlayerCardUseReal(color, obj, source, dest, false)
  local oname = obj.getName()

  if can then
    local newcb = function(...)
      local check, checkcb = getPlayerCardUseReal(color, obj, source, dest, false)
      if not check or checkcb ~= cb then
        whine("Out of order? %s trying a qdo: %s from %s to %s",
              color, oname, source, dest)
        return
      end

      cb(...)
    end
    return can, newcb
  else
    return can, cb
  end
end

function isSelectable(color, loc, obj, selects)
  if not selects then
    selects = CURRENT_QUESTION[color]["selects"]
    if not selects then
      die("isSelectable called without selects in question?")
      return false
    end
  end
  -- Object sanity checks
  if not obj then return false end
  if isScrapped(obj) then return false end
  local card = ALL_CARDS[obj.getName()]
  if not card then return false end

  if selects["sources"] and #selects["sources"] > 0 and not isMember(selects["sources"], loc) then
    return false
  end
  if selects["owners"] and #selects["owners"] > 0 and not isMember(selects["owners"], obj.getDescription()) then
    return false
  end
  if selects["types"] and #selects["types"] > 0 and not isMember(selects["types"], card["type"]) then
    return false
  end
  if selects["cost"] and card["cost"] > selects["cost"] then
    return false
  end
  if selects["checkfunc"] and not selects["checkfunc"](obj, card) then
    return false
  end
  return true
end

-- Can player pick up (dest=nil) or move (dest~=nil) a card?
function getPlayerCardUseReal(color, obj, source, dest, isqdo)
  local name = obj.getName()
  local card = ALL_CARDS[obj.getName()]
  if not name or not card then
    die("uh, no name or card?")
    return true, nil
  end

  if isScrapped(obj) then
    whine("Trying to play w/ scrapped guid %s? Duplication?", obj.getGUID())
    return false
  end

  -- If player has any questions remaining, no.
  if CURRENT_QUESTION[color] then
    local sels = CURRENT_QUESTION[color]["selects"]
    if sels then
      if isSelectable(color, source, obj) then
        if not isqdo then
          trySelect(color, source, obj)
        end
        return false, nil
      else
        return false, "Can't select that"
      end
    else
      return false, "You have questions to answer first."
    end
  end

  -- If player has any musts, it depends on first must.
  local pinfo = GAMESTATE["players"][color]
  local musts = pinfo["musts"]
  local mays = pinfo["mays"]

  if musts and #musts > 0 then
    local must = musts[1]
    if must[1] == "discard" then
      -- "must" discards are only from hand.
      if source ~= S_HAND then return false end
      if (dest ~= S_DISCARD and dest ~= nil) then
        return false, "You must discard, first."
      end
      return true, doDiscardCard
    elseif must[1] == "draw" then
      -- player clicked faster than cards settled so they could draw.
      -- Force an updatePlayState so they must draw.
      qdo(updatePlayState)
      return false, "Slow down so you can draw!"
    elseif must[1] == "carduse" then
      if canUseCardUse(must[2], source, dest, card, obj) then
        return true, doCardUseMust
      else
        return false, must[2].message
      end
    else
      die("Don't know must{%s, %s}", tostring(must[1]), tostring(must[2]))
    end
    return false, "You have musts"
  end

  local opps = getTargetOpponents(color)
  if isPlaying(color) and opps[obj.getDescription()] then
    if dest == S_AUTO then
      -- Double click
      return true, doAttackEnemyCard
    end
    return false, "Enemy Card"
  end

  if #mays.carduses > 0 then
    local uses = findCardUses(mays.carduses, source, dest, obj)
    if #uses > 0 then
      return true, doCardUseMay
    end
  end

  -- Aside from targeting, no reason to be able to interact with opponent card.
  local acceptable = {
    T = true, -- Trade
    X = true, -- Explorer
  }
  acceptable[color] = true
  if not acceptable[obj.getDescription()] then
    return false, "Not your card"
  end

  -- Everything after this is only for current players or team
  if not isPlaying(color) then
    return false, "Not your turn"
  end

  if getPlayState(color) == nil then
    die("%s doesn't have playstate, but is in getPlayerCardUse somehow?", color)
    return
  end
  local psi = getPlayState(color, "interactables")

  if (source == S_TRADE or source == S_EXPLORER) then
    if canBuy(color, obj) then
      if dest == nil or dest == S_PLAY or dest == S_PLAYER or dest == S_AUTO then
        return true, doBuyCard
      end
    end

    -- No trade cards for you, sir!
    return false, nil
  end

  -- Interactables are our own ships and bases we can interact with.
  if (source == S_PLAY or source == S_PLAYER) then
    local psid = psi[obj.getGUID()]
    if hasAnyBut(psid, "scrap") then
      if (dest == source or dest == nil) then
        if not isqdo then
          doRunInteractable(color, obj, psid)
        end
        return false, nil
      end
    end
  end

  if source == dest then
    return false, nil
  end

  if source == S_PLAYER_DECK then
    return false, "Playing from deck?"
  end

  -- Anything from player's hand is "play"able, as long as dest is nil.
  if source == S_HAND and dest == nil then
    return true, doPlayCard
  end

  -- Scrappable
  if ((source == S_PLAY or source == S_PLAYER)
      and (dest == S_SCRAP or dest == nil)
      -- If double click should scrap, then add S_AUTO
      and psi[obj.getGUID()] and psi[obj.getGUID()]["scrap"] ~= nil) then
    return true, doScrapCardForEffects
  end

  local playlocs = {}
  playlocs[S_PLAY] = true
  playlocs[S_AUTO] = true
  playlocs[S_PLAYER] = true

  if source == S_HAND and playlocs[dest] then
    return true, doPlayCard
  end

  -- Rest uninteractable?
  local msg1 = "Dunno: %s-%s for %s"
  local msg2 = msg1:format(source, tostring(dest), tostring(obj.getName()))
  return false, msg2
end

function doPlayCard(color, obj, source, dest, origstate)
  playCards(color, {obj})
end

function doCardUseMust(color, obj, source, dest, origstate)
  local musts = GAMESTATE.players[color].musts
  local card = ALL_CARDS[obj.getName()]

  if not musts or #musts == 0 then
    return die("doCardUseMust w/o a must?")
  end
  local must = musts[1]
  if must[1] ~= "carduse" then
    return die(color, "No must.carduse?")
  end

  if not canUseCardUse(must[2], source, dest, card, obj) then
    return die("doCardUseMust with invalid canUseCardUse?")
  end
  applyCardUse(color, must[2], source, dest, card, obj)
  if must[2].count > 0 then
    must[2].count = must[2].count - 1
  end
  if must[2].count == 0 then
    table.remove(musts, 1)
  end
end

function doCardUseMay(color, obj, source, dest, origstate, id)
  local mays = GAMESTATE.players[color].mays
  local uses = findCardUses(mays.carduses, source, dest, obj)
  local card = ALL_CARDS[obj.getName()]

  if not uses or #uses == 0 then
    return die("doCardUseMay called without uses?")
  end

  if #uses > 1 and id == nil then
    local choices = {}
    for _, use in ipairs(uses) do
      table.insert(choices, {
        describeCardUse(use, "You may"),
        function()
          doCardUseMay(color, obj, source, dest, origstate, use.id)
        end
      })
    end
    table.insert(choices, {
      "Cancel",
      function()
        returnObject(color, obj, origstate)
      end
    })
    askQuestion(obj.getGUID(), color, card.name, choices)
    return
  end

  local selectedUse = uses[1]
  if #uses > 1 and id ~= nil then
    for _, use in ipairs(uses) do
      if use.id == id then
        selectedUse = use
      end
    end
  end

  if selectedUse.count > 0 then
    selectedUse.count = selectedUse.count - 1
  end
  if selectedUse.count == 0 then
    local toremove = nil
    for idx, use in ipairs(mays.carduses) do
      if use == selectedUse then
        toremove = idx
      end
    end
    if toremove == nil then
      return die("Mays couldn't find its own use? eh?")
    end
    table.remove(mays.carduses, toremove)
  end

  applyCardUse(color, selectedUse, source, dest, card, obj)
end

function doRunInteractable(color, obj, interactions, selname)
  local icount = 0
  local name = nil
  for k, _ in pairs(interactions) do
    if k ~= "scrap" then
      name = k
      icount = icount + 1
    end
  end
  if not name then
    -- scrap is interactions, but we ignore for now.
    return
  end
  if icount > 1 then
    if selname == nil then
      return die("Multiple interactions. Coming soon.")
    else
      name = selname
    end
  end
  -- interactions["choose"] = effects["choose"]
  -- interactions["scrap"] = effects["onscrap"]
  -- interactions["activate"] = effects["onactivate"]
  local cardname = getPlayState(color, "played", obj.getGUID()) or obj.getName()
  local args = interactions[name]

  if name == "choose" then
    local choices = {}
    for idx, eff in ipairs(args) do
      choices[#choices+1] = {
        describeEffects(eff, cardname),
        function() doApplyInteraction(color, obj, "choose", eff, idx) end
      }
    end
    choices[#choices+1] = { "Cancel", nil }
    askQuestion(obj.getGUID(), color, cardname .. " (Choose):", choices)
  end
  if name == "stealthtower" then
    -- Copy a base, any other base, on the field.
    askSelectCard(obj.getGUID(), color, "Become a copy of", {
        min = 0, max = 1,
        types = {BASE, OUTPOST},
        owners = getSeatedColors(),
        sources = {S_PLAY, S_PLAYER},
        checkfunc = function(o,c) return c["name"] ~= obj.getName() end,
      },
      function(sels) playStealthTower(color, obj, sels) end)
    sendToHand(color, obj)
    return false
  end
  if name == "mayreturn" then
    -- {"freecard", {SHIP}, 100, TO_TOP}
    if not args[2] or #args[2] < 1 then
      return die("invalid mayreturn")
    end
    local qstr = sprintf("Return %s", describeTypes(args[2], "or"))

    askSelectCard(obj.getGUID(), color, qstr, {
        min = 1, max = args[3],
        types = args[2],
        owners = GAMESTATE["order"],
      },
      function(sels) doReturnCards(color, obj, sels) end)
  end
  if name == "freecard" then
    -- {"freecard", {SHIP}, 100, TO_TOP}
    local typestr = "a card"
    if args[2] and #args[2] > 0 then
      typestr = describeTypes(args[2], "or")
    end
    local qstr = sprintf("Pick %s of cost %d or less", typestr, args[3])
    if args[3] > 30 then
      qstr = sprintf("Pick %s", typestr)
    end

    askSelectCard(obj.getGUID(), color, qstr,
      {
        min = 0, max = 1,
        types = args[2],
        cost = args[3],
        owners = {"T", "X"},
      },
      function(sels) doAcquireFreeCard(color, obj, args[4], sels) end)
  end
  if name == "activate" then
    local choices = {}
    for idx, onact in ipairs(args) do
      table.insert(choices, {
        describeEffects(onact, cardname),
        function() doApplyInteraction(color, obj, "activate", onact, idx) end,
      })
    end
    table.insert(choices, { "Cancel", nil })
    local desc = describeEffects(args, cardname)
    askQuestion(obj.getGUID(), color, cardname .. " Activate " .. desc, choices)
  end
  if name == "scrap" then
    -- I think this is only used by dumbai?
    local desc = describeEffects(args, cardname)
    askQuestion(obj.getGUID(), color, "Scrap " .. cardname .. " for " .. desc .. "?", {
      { "Yes", function() doScrapCardForEffects(color, obj, S_PLAY, S_SCRAP, {}) end },
      { "No", nil },
    })
  end
end

function describeTypes(typelist, conj)
  local types = {}
  for _, t in ipairs(typelist) do
    -- For description, OUTPOST and BASE are identical.
    if t ~= OUTPOST then
      table.insert(types, t)
    end
  end

  return concatAnd(types, conj)
end

function doApplyInteraction(color, obj, why, effects, idx)
  local card = ALL_CARDS[obj.getName()]

  applyEffects(color, obj, card, effects, obj.getPosition(), why, false)

  if getPlayState(color) == nil then
    return die("%s doesn't have playstate, but is in doApplyInteraction somehow?", color)
  end

  -- And remove the interaction from interactables so it's not repeatable.
  -- (Though removing it from play and adding it back should work.)
  local psi = getPlayState(color, "interactables")
  local interactions = psi[obj.getGUID()]
  if why == "activate" then
    table.remove(interactions[why], idx)
    if #interactions[why] == 0 then
      interactions[why] = nil
    end
  else
    interactions[why] = nil
  end
  if not hasAny(interactions) then
    psi[obj.getGUID()] = nil
  end
end

function doDiscardCard(color, obj, source, dest, origstate)
  local pinfo = GAMESTATE["players"][color]
  local musts = pinfo["musts"]

  if musts and #musts > 0 then
    local must = musts[1]
    if must[1] ~= "discard" then return warnPlayer(color, "No must.discard?") end

    must[2] = must[2] - 1
    if must[2] < 1 then
      table.remove(musts, 1)
    end
  end

  announce(color, "discarded %s", obj.getName())
  discardAllCards(color, {obj})
end

function doScrapCardForEffects(color, obj, source, dest, origstate)
  if getPlayState(color) == nil then
    return die("%s doesn't have playstate, but is in doScrapCardForEffects somehow?", color)
  end
  local psi = getPlayState(color, "interactables")
  local guid = obj.getGUID()
  if psi[guid] and psi[guid]["scrap"] then
    local card = ALL_CARDS[obj.getName()]
    applyEffects(color, obj, card, psi[guid]["scrap"], obj.getPosition(), "onScrap", false)
    announce(color, "scrapped %s for %s", obj.getName(), describeEffects(psi[guid]["scrap"], card.name))
    psi[guid] = nil
    sendCardToScrap(color, obj)
    addTag(color, "scrap:play", "Scrapped a card in play")
    waitUntilSettled()
  end
end

function doAcquireFreeCard(color, giver, dest, sels)
  local psi = getPlayState(color, "interactables")
  local guid = giver.getGUID()
  if psi[guid] and psi[guid]["freecard"] then
    for _, obj in ipairs(sels) do
      doBuy(color, obj, false, dest)
    end
    psi[guid]["freecard"] = nil
    if not hasAny(psi[guid]) then
      psi[guid] = nil
    end
  else
    return die("No freecard interactables in doAcquireFreeCard?")
  end
end

function doBuyCard(color, obj, source, dest, origstate)
  doBuy(color, obj, true, TO_DISCARD)
end

function sendCardToScrap(color, obj)
  local owner = obj.getDescription()
  if owner ~= "T" and owner ~= "X" then
    addTag(color, "scrap", "Scrap")
    rebuildAllies(color)
    local expected = GAMESTATE["players"][color]["card_count"]
    GAMESTATE["players"][color]["card_count"] = expected - 1
  end
  destroyCard(obj)
end

function updatePlayStateNow(doapply)
  if GAMESTATE["state"] ~= RUNNING then return end
  local tt = getPlayState("trade")
  local dt = getPlayState("damage")
  if tt == nil or dt == nil then
    tt = 0
    dt = 0
  end

  setTokenText(GameObjects.TRADE_TOKEN, tt)
  setTokenText(GameObjects.DAMAGE_TOKEN, dt)

  highlightInteractables()

  for color in allSeatedColors() do
    if doapply then
      applyMusts(color)
    end
    updateStatUI(color)
  end
end

function clickAuthTokenReal(ctoken, color, alt_click)
  local targetname = ctoken.getDescription()
  local targetteam = GAMESTATE["teams"][targetname]

  if GAMESTATE["state"] == RUNNING then
    tryAttacking(color, targetname, not alt_click)
  elseif GAMESTATE["state"] == UNSCRIPTED then
    local authority = targetteam["authority"]
    if alt_click then
      authority = authority + 1
    else
      authority = authority - 1
    end
    targetteam["authority"] = authority
    ctoken.editButton({index=0, label=tostring(authority)})
  end
end

