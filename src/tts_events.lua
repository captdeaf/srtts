function onObjectLeaveContainer(deck, obj)
  -- This is painful. If deck has 2 cards in it, last card leaving causes
  -- deck to disappear, replacing w/ new card and diff guid.
  --
  -- AND - if discard has more than one, deck is empty,, player searches,
  --       scraps, and draws, then we get a leave for the deck itself.

  local color = obj.getDescription()
  local key = color .. deck.getGUID()
  if not SEARCHING[key] then return end
  if PLAYER_ZONE[color] ~= nil then
    local decksource = getLocOfCard(color, deck, true)
    if SEARCHING[key] ~= nil and SEARCHING[key][1] == decksource then
      local deckstate = SEARCHING[key]
      qdo(waitUntilSettled, function()
        onObjectPickUp(color, obj, deckstate)
        onObjectDrop(color, obj)
      end)
    end
  end
end

function onObjectSearchStart(obj, color)
  local key = color .. obj.getGUID()
  local loc = getLocOfCard(color, obj, false)
  announce(color, "is searching %s", loc)
  SEARCHING[key] = {getLocOfCard(color, obj, false, true),
                    obj.getPosition(),
                    obj.getRotation(),
                    track = obj.getGUID(),
                    ts = Time.time}
end

function onObjectSearchEnd(obj, color)
  if not isLivePlayer(color) then return end
  local key = color .. obj.getGUID()
  local loc = getLocOfCard(color, obj, false, true)
  announce(color, "stops searching %s", loc)
  SEARCHING[key] = nil
  qdo(groupDecks, color)
end

function onObjectPickUp(color, obj, deckstate)
  -- Game can get confused if things move around while STARTING
  if GAMESTATE.state == UNREADY and GameObjects.PLAY_BOX.getGUID() == obj.getGUID() then
    obj.drop()
    greenWait({
      frames = 3,
      callback = clickStart,
    })
    return
  end
  if GAMESTATE["state"] == STARTING then
    obj.drop()
  end
  -- And we only run our game logic scripts during RUNNING.
  if GAMESTATE["state"] ~= RUNNING then return end

  if not isGameObject(obj) then return end
  if not isLivePlayer(color) then
    whine("Not live")
    obj.drop()
    return
  end
  local source
  local cstate
  if deckstate == nil then
    source = getLocOfCard(color, obj, true)
    cstate = {color, source, obj.getPosition(), obj.getRotation(), ts=Time.time}
  else
    source = deckstate[1]
    cstate = {color, source, deckstate[2], deckstate[3], ts=Time.time}
  end

  CARDSTATES[obj.getGUID()] = cstate
  -- We have no control outside of RUNNING state.

  local can, _ = getPlayerCardUse(color, obj, source, nil)
  local cb = nil
  local dest = nil

  if not hasAny(PICKINGS[color]) then PICKINGS[color] = {} end
  local apick = PICKINGS[color][obj.getGUID()]

  if (apick and (apick["exp"] > Time.time)) then
    PICKINGS[color][obj.getGUID()] = {
      exp = apick["exp"],
      ready = true,
      ts=Time.time,
    }
    if not can then
      -- Attempt S_AUTO?
      PICKINGS[color][obj.getGUID()] = nil
      -- Double clicked.
      can, cb = getPlayerCardUse(color, obj, source, S_AUTO)
      if can then
        dest = S_AUTO
      end
    end
  else
    apick = {
      exp = Time.time + 0.4,
      ready = false,
      ts = Time.time,
    }
    PICKINGS[color][obj.getGUID()] = apick
  end

  if not can then
    obj.drop()
    returnObject(color, obj, cstate)
    return
  end

  if can and cb ~= nil then
    obj.drop()
    greenWait({
      frames = 1,
      callback = function() qdo(cb, color, obj, source, dest, cstate) end,
    })
  end
end

function onObjectDrop(color, obj)
  if GAMESTATE["state"] ~= RUNNING then return end

  if not isLivePlayer(color) then return end
  if not isGameObject(obj) then return end

  local cstate = CARDSTATES[obj.getGUID()]
  local source = cstate[2]
  local dest = getLocOfCard(color, obj, false)

  if not cstate then
    whine("Drop without pickup?")
    return
  end

  -- Double click version (auto target)
  if not hasAny(PICKINGS[color]) then PICKINGS[color] = {} end
  local apick = PICKINGS[color][obj.getGUID()]

  local can = false
  local cb = "Unset"

  if apick and apick["ready"] and apick["exp"] > Time.time then
    PICKINGS[color][obj.getGUID()] = nil
    -- Double clicked.
    can, cb = getPlayerCardUse(color, obj, source, S_AUTO)
    dest = S_AUTO
  end

  if not can then
    -- Drag and drop
    can, cb = getPlayerCardUse(color, obj, source, dest)
  end

  if can then
    if cb then
      qdo(cb, color, obj, source, dest, cstate)
    end
  else
    if cb then
      warnPlayer(color, "Unable: " .. cb)
    end
    returnObject(color, obj, cstate)
  end
end

