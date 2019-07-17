function updateState(state)
  if state == UNREADY then
    createXMLRulesMenu()
    GameObjects.TURN_TEXT.setValue("Ready up, players!")
    setTokenText(GameObjects.TRADE_TOKEN, 0)
    setTokenText(GameObjects.DAMAGE_TOKEN, 0)
  end
  GAMESTATE["state"] = state
  updatePlayBox(state)
  updateButtons()
end

function gameStart()
  -- Cleanup
  destroyGameObjects()

  mapHouseRules()

  -- Initialize the house rules structure
  local selected = mapMember(PDATA.rules, "name")
  announceGame("Selected house rules: %s", concatAnd(selected))

  local seatedcolors = getSeatedPlayers()
  local colors = getHouseRule("getPlayers", seatedcolors)
  local teaminfo = getHouseRule("getTeams", colors)

  setupTeams(teaminfo)

  -- Default information prior to application of house rules.

  GAMESTATE["tradedeck"] = getCardsOfDecks(GAMESTATE["decks"])
  GAMESTATE["players"] = {}

  -- Update player info w/ their teams.
  for _, team in ipairs(teaminfo) do
    for color, _ in pairs(team["colors"]) do
      GAMESTATE["players"][color] = createDefaultInfo(color, team)
    end
  end

  -- on setup for house rules here. We don't need its results.
  callHouseRules("onSetup")

  local names = mapList(GAMESTATE["order"], playerName)
  announceGame("Turn order: %s", concatAnd(names, ""))

  spawnTradeDeck(GAMESTATE["tradedeck"])
  spawnExplorer(true)
  setupPlayers()
  createXMLUI()

  waitUntilSettled(function() qdo(dealFirstRound) end)
end

function createDefaultInfo(color, team)
  return {
    teamname = color,
    startdeck = duplicate(DECKS["STARTDECK"]),
    startdiscard = {},
    starthand = {},
    startinplay = {},
    musts = {},
    mays = newMays(),
    card_count = 0,
    team = team.name
  }
end

function getTradeCards()
  return filterCards(getAllObjects(), function(o,c) return (o.getDescription() == "T" or o.getDescription() == "X") end)
end

function dealToTrade(idx, td)
  if not td then return end
  local saveTrade = qWaitFor("savetrade", function(obj)
    GAMESTATE["tradecards"][idx] = obj.getGUID()
    local target = PDATA["tradepos"][idx]
    moveThen(obj, target, updatePlayState)
  end)
  local savewrap = function(obj1)
    waitForGUID(obj1, saveTrade)
  end
  if td and td.tag == "Deck" then
    local pos = td.getPosition()
    pos["y"] = pos["y"] + 2
    td.takeObject({
      position = pos,
      smooth = false,
      rotation = {x=0.0, y=180.0, z=0.0},
      callback_function = savewrap,
    })
  elseif td and td.tag == "Card" then
    td.setRotationSmooth({x=0.0, y=180.0, z=0.0})
    moveThen(td, PDATA["tradepos"][idx], function()
      savewrap(td)
    end)
  end
end

function refreshTradeOptions(tradeguid)
  for idx, guid in ipairs(GAMESTATE["tradecards"]) do
    if guid == tradeguid then
      dealToTrade(idx, getTradeDeck())
      updatePlayState()
      return
    end
  end
end

function dealFirstRound()
  local td = getTradeDeck()
  td.shuffle()

  for idx, _ in ipairs(PDATA["tradepos"]) do
    dealToTrade(idx, td)
  end

  qdo(nextTurn, true)
end

function newMays()
  return {
    carduses = {},
    destroybase = 0,
  }
end

function isScrapped(objorguid)
  if type(objorguid) == 'string' then
    return GAMESTATE["play"]["scrapped"][objorguid]
  else
    return GAMESTATE["play"]["scrapped"][objorguid.getGUID()]
  end
end

function endTurn()
  clearHighlights()
  clearTurnUIs()
  -- Clean up all ships in play.
  local allships = getPlayState("ships")
  for color, _ in pairs(getCurrentPlayers()) do
    local allcards = {}
    for _, guid in ipairs(allships) do
      if not isScrapped(guid) then
        local ship = getObjectFromGUID(guid)
        if ship and ship.getDescription() == color then
          allcards[#allcards+1] = ship
        end
      end
    end

    -- Clear out musts and mays.
    GAMESTATE["players"][color]["musts"] = {}
    GAMESTATE["players"][color]["mays"] = newMays()

    if #allcards > 0 then
      discardAllCards(color, allcards)
    end
  end

  callHouseRules("onTurnEnd")

  -- Queue nextTurn for when it's all settled.
  waitUntilSettled(waitUntilSettled)
  qdo(nextTurn, false)
end

function clearPlayerCards(color)
  local pdata = PDATA[color]
  local allcards = filterCards(getAllObjects(), function(o,c) return o.getDescription() == color end)
  -- Empty player's hand.
  for _, card in ipairs(dumpHand(color, false)) do
      allcards[#allcards+1] = card
  end
  discardAllCards(color, allcards)

  local deck = getPlayerDeckAt(color, pdata["deckloc"], true)
  if deck then
    deck.flip()
    deck.setPositionSmooth(pdata["discardloc"])
    deck.setRotationSmooth(pdata["rot"])
  end
end

function nextTurn(isnewgame)
  if not isnewgame then
    local doneteam = GAMESTATE["playing"]
    local handsize = getHouseRule("getHandSize", doneteam)
    for color, _ in pairs(getTeamPlayers(doneteam)) do
      qdo(drawToPlayer, color, handsize)
    end
  end

  local team = table.remove(GAMESTATE["order"], 1)
  table.insert(GAMESTATE["order"], team)

  qdo(startTurn, team)
end

function checkGameSanity()
  if GAMESTATE["state"] ~= RUNNING then return end
  local issane = true

  if not checkPlayerCardCount() then
    issane = false
  end

  if getPlayState("trade") < 0 or getPlayState("damage") < 0 then
    whine("trade or damage less than zero?")
    issane = false
  end

  -- Check trade cards.
  local tcs = getTradeCards()
  if #tcs ~= 6 then
    whine("# of trade cards: %d ~= 6!", #tcs)
    issane = false
  end

  -- No player has more than their handsize

  if not issane then
    announceGame("Game sanity in question - scripting Disabled")
    GAMESTATE["state"] = UNSCRIPTED
    updateButtons()
  end
end

function checkPlayerCardCount()
  for color, _ in pairs(getCurrentPlayers()) do
    local cur = countPlayerCards(color)
    local expected = GAMESTATE["players"][color]["card_count"]
    if expected == 0 then
      GAMESTATE["players"][color]["card_count"] = cur
    elseif expected ~= cur then
      whine("!! %s expected: %d, have: %d", playerName(color), expected, cur)
      return false
    end
  end
  return true
end

function countPlayerCards(color)
  local count = 0
  local counted = {}
  local good = true

  for _, obj in ipairs(getAllObjects()) do
    if obj.tag == "Deck" then
      for _, item in ipairs(obj.getObjects()) do
        if item["description"] == color then
          count = count + 1
        end
        if item.guid and item.guid ~= "" then
          if counted[item.guid] then
            whine("countPlayerCards(%s) dupe: %s.%s(%s) - %s vs %s", color, item.guid, item.name, item.description, "item", counted[item.guid])
            good = false
          end
          counted[item.guid] = sprintf("item.%s.%s", item.name, item.description)
        end
      end
    elseif obj.tag == "Card" and obj.getDescription() == color then
      count = count + 1
      local guid = obj.getGUID()
      if counted[guid] then
        whine("countPlayerCards(%s) dupe: %s.%s(%s) - %s vs %s", color, guid, obj.getName(), obj.getDescription(), "item", counted[guid])
        good = false
      end
      counted[guid] = sprintf("object.%s.%s", obj.getName(), obj.getDescription())
    end
  end
  if not good then
    die("Invalid countPlayerCards")
  end

  return count
end

function setDevPlayerTo(color)
  local players = Player.getPlayers()
  if players and #players > 0 then
    players[1].changeColor(color)
  end
end

function getSeatedColors()
  local ret = {}
  for color in allSeatedColors() do
    table.insert(ret, color)
  end
  return ret
end

function timerTick()
  if GAMESTATE["state"] == RUNNING then
    updateDecals()
    clearSavedStates()
  else
    Global.setDecals({})
  end
end

function startTurnUI(team)
  showTurnUI()
  GameObjects.TURN_TEXT.setValue(teamName(team) .. "'s turn")
  printToAll("*** " .. teamName(team) .. "'s turn", {r=0.9, g=0.9, b=0.4})
end

function newPlayState(color)
  return {
    -- guid:cardname map
    played = {},
    nextbuyto = {},
    -- For rendering
    other = {},
    -- needally is [faction] = {guid, guid} map
    needally = {},
    -- allies is for cards in play as well as effects, regenerated
    -- on cards being scrapped.
    allies = {},
    -- effectallies is for effects, e.g: Heroes that give ally effects for rest
    -- of turn on scrap.
    effectallies = {},
    -- Interactables: Interactable cards (e.g: Select target base to destroy)
    -- Format: {GUID={what, count}}
    -- Bases with CHOOSE are interactables.
    interactables = {},

    -- tags: A variety for checks, counts, etc.
    tags = {},

    -- "ontag" effects. e.g: Fleet HQ, ontag={"play:ship", {d=1}}
    ontags = {},
  }
end

function getPlayState(...)
  local tmp = {...}
  local n = select('#', ...)
  local ptr = GAMESTATE["play"]

  local starti = 1
  -- If it's a color, use play.colors
  if PLAYER_ZONE[tmp[1]] then
    ptr = GAMESTATE["play"]["colors"][tmp[1]]
    starti = 2
  end

  for i=starti,n,1 do
    if not ptr then
      die("getPlayState unable to get parent for %s", table.concat(tmp, "."))
      return nil
    end
    local key = tmp[i]
    ptr = ptr[key]
  end
  return ptr
end

function setPlayState(...)
  local tmp = {...}
  local n = select('#', ...)

  local key = tmp[n-1]
  local val = tmp[n]

  if n == 2 then
    GAMESTATE["play"][key] = val
    return val
  end
  local parent = getPlayState(unpack(tmp, 1, n-2))
  if not parent then
    local tmpb = {unpack(tmp, 1, n-1)}
    die("setPlayState unable to get parent for %s", table.concat(tmpb, "."))
    return
  end
  parent[key] = val
  return val
end

function tweakPlayState(...)
  local tmp = {...}
  local n = select('#', ...)
  local ptr = GAMESTATE["play"]

  local key = tmp[n-1]
  local fnc = tmp[n]

  if n == 2 then
    local val = fnc(ptr[key])
    ptr[key] = val
    return val
  end
  local parent = getPlayState(unpack(tmp, 1, n-2))
  if not parent then
    table.remove(tmp, n)
    die("tweakPlayState unable to get parent for %s", table.concat(tmp, "."))
    return
  end
  local newval = fnc(parent[key])
  parent[key] = newval

  return newval
end

function startTurn(team)
  if GAMESTATE.state == STARTING then
    updateState(RUNNING)
  end
  GAMESTATE["playing"] = team
  callHouseRules("onTurnStart")

  startTurnUI(team)
  local playing_colors = getTeamPlayers(team)

  GAMESTATE["playing"] = team
  GAMESTATE["play"] = {
    -- Current sums
    trade = 0,
    damage = 0,
    scrapped = {},
    destroyed = {},
    targets = {},
    ready = {},
    colors = {},
    ships = {},
  }

  -- getOpponentBases() checks "destroyed" and "scrapped" in GAMESTATE.play
  GAMESTATE.play.enemybases = objectsToGUIDs(getOpponentBases(team))

  for col, _ in pairs(playing_colors) do
    GAMESTATE["play"]["ready"][col] = false
    GAMESTATE["play"]["colors"][col] = newPlayState(col)
  end
  for col, _ in pairs(playing_colors) do
    -- Apply outposts, bases, and others (gambits?)
    applyCurrentBaseEffects(col)
  end
  updatePlayState()

  rebuildTargets()
end

function tryEndTurn(player)
  local color = player.color
  if not isPlaying(color) then return end

  local playerinfo = GAMESTATE["players"][color]

  if QUESTIONS[color] and #QUESTIONS[color] > 0 then
    warnPlayer(color, "You have some questions remaining.")
    return
  end
  local hand = player.getHandObjects()
  if hand and #hand > 0 then
    warnPlayer(color, "You still have cards in your hand.")
    return
  end
  local musts = playerinfo["musts"]
  if musts and #musts > 0 then
    warnPlayer(color, "You have some things you must do remaining.")
    return
  end

  local whoready = getPlayState("ready")
  if whoready[color] then
    -- Already ended turn.
    return false
  end

  setPlayState("ready", color, true)
  for col, val in pairs(getPlayState("ready")) do
    if val == false then
      announce(color, "is finished.")
      return
    end
  end
  announce(color, "ends turn.")

  clearTurnUIs()
  -- Add endTurn to end of qdo queue.
  qdo(endTurn)
end

function tryAttacking(color, targetTeam, domax)
  if not isPlaying(color) then return end

  if not getPlayState("targets", targetTeam) then
    logEffect(color, "attack", "Not a valid target. Bases or Outposts?")
    warnPlayer(color, "!!! Not a valid target. Bases or Outposts?")
    return
  end

  local maxdam = getPlayState("damage")
  if maxdam > 0 then
    local health = changeTeamAuthority(targetTeam, 0)
    local dam = 1
    if domax then dam = math.min(maxdam, health) end
    health = changeTeamAuthority(targetTeam, -dam)
    tweakPlayState("damage", function(d) return d - dam end)

    announce(color, "deals %d damage to %s.", dam, playerName(targetTeam))

    if health <= 0 then
      killPlayer(color, targetTeam)
    end
    updatePlayState()
  end
end

function killPlayer(color, targetTeam)
  local team = getTeamOf(color)
  announce(teamName(team), "has eliminated %s(%s) from the galaxy!",
           teamName(targetTeam), targetTeam)

  local remaining = {}
  for _, col in ipairs(GAMESTATE["order"]) do
    if col ~= targetTeam then
      table.insert(remaining, col)
    end
  end
  GAMESTATE["order"] = remaining
  for deadcol in pairs(getTeamPlayers(targetTeam)) do
    clearPlayerCards(deadcol)
  end
  rebuildTargets()

  checkWin(team, remaining)
end

function checkWin(team, remaining)
  if #remaining == 1 then
    announce(teamName(remaining[1]), "has conquered the galaxy!")
    clearUIElements()
    updateState(ENDED)
  elseif #remaining > 1 then
    announceGame("%d remain: %s", #remaining, concatAnd(mapList(remaining, teamName), "and"))
  else
    announceGame("Bug in checkWin?")
  end
end

function setupPlayers()
  for _, team in ipairs(GAMESTATE["order"]) do
    local handsize = getHouseRule("getHandSize", team)
    for color, _ in pairs(getTeamPlayers(team)) do
      local info = GAMESTATE["players"][color]
      local pdata = PDATA[color]

      if not info["starthand"] or #info["starthand"] == 0 then
        local hand, deck = getHouseRule("getFirstHand", info["startdeck"], handsize)
        info["starthand"] = hand
        info["startdeck"] = deck
      end
      -- And deal their default set of cards.
      local downrot = {
        x = 0.0,
        y = pdata["yrot"],
        z = 180.0,
      }
      local uprot = {
        x = 0.0,
        y = pdata["yrot"],
        z = 0.0,
      }
      if info["startdeck"] and #info["startdeck"] > 0 then
        spawnDeckAt(color, shuffle(info["startdeck"]), {
          position = pdata["deckloc"],
          rotation = downrot,
        })
      end
      if info["startdiscard"] and #info["startdiscard"] > 0 then
        spawnDeckAt(color, shuffle(info["startdiscard"]), {
          position = pdata["discardloc"],
          rotation = uprot,
        })
      end
      if info["starthand"] and #info["starthand"] > 0 then
        spawnHand(color, info["starthand"])
      end
      if info["startbases"] and #info["startbases"] > 0 then
        spawnBases(color, info["startbases"])
      end
    end
  end
end

function changeTeamAuthority(teamorplayer, amt)
  -- returns the player's authority as number
  local teamname = getTeamOf(teamorplayer)
  local teamdata = GAMESTATE["teams"][teamname]
  local authority = teamdata["authority"]
  if amt and amt ~= 0 then
    authority = authority + amt
    teamdata["authority"] = authority

    local tok = getTeamAuthToken(teamname)
    tok.editButton({
      index = 0,
      label = tostring(authority),
    })
  end
  return authority
end

function clearSavedStates()
  -- cardstates, PICKINGS
  local older = Time.time - 120
  local statesavers = {CARDSTATES, SEARCHING}
  -- PICKINGS is indexed by color.
  for _, picky in pairs(PICKINGS) do
    table.insert(statesavers, picky)
  end
  for _, loc in ipairs(statesavers) do
     for k, v in pairs(loc) do
       if v["ts"] < older then
         loc[k] = nil
       end
     end
  end
end

