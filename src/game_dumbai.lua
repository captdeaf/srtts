function doSomethingDumb(color, isqok)
  if not isPlaying(color) then return end

  local pdata = PDATA[color]
  local hand = Player[color].getHandObjects()

  local q = CURRENT_QUESTION[color]
  if q then
    local selects = q["selects"]
    local answers = q["answers"]
    local choice = math.random(1, #answers - 1)
    if math.random(10) == 7 then
      -- last pick, usually cancel.
      choice = #answers
    elseif selects then
      choice = #answers
      local selectable = filterCards(getAllObjects(), function(obj,c)
        return isSelectable(color, getLocOfCard(color, obj, true, true), obj, selects)
      end)
      if #selectable > 0 then
        shuffle(selectable)
        local scount = math.min(#selectable, selects["max"])
        for i=1,scount,1 do
          trySelect(color,
                    getLocOfCard(color, selectable[i], true, true),
                    selectable[i])
        end
      end
      if q["acceptable"] then
        choice = 1
      end
    end
    clickUIAnswer(Player[color], tostring(choice))
    return
  end

  -- Only continue if it's safe to. (making our choices saner)
  if not isqok then return end

  -- No questions? Okay. Any interactables I can use - at random?
  local psi = getPlayState(color, "interactables")
  if hasAny(psi) then
    for guid, psid in pairs(psi) do
      if not isScrapped(guid) then
        if math.random(1,8) < 4 then
          local obj = getObjectFromGUID(guid)
          -- qdo(doRunInteractable, color, getObjectFromGUID(guid), psid)
          local loc = getLocOfCard(color, obj, false, false)
          if psid["scrap"] then
            local can, cb = getPlayerCardUse(color, obj, loc, S_SCRAP)
            local cstate = {color, loc, {}, {}, ts=Time.time}
            if can then
              qdo(cb, color, obj, S_TRADE, S_SCRAP, cstate)
            end
          else
            local can, cb = getPlayerCardUse(color, obj, loc, loc)
            local cstate = {color, loc, {}, {}, ts=Time.time}
            if can then
              qdo(cb, color, obj, S_TRADE, S_PLAY, cstate)
            end
          end
          return
        end
      end
    end
  end

  -- Maybe I wanna buy something.
  local buyable = {}
  local buycb = nil
  local odds = 2
  for _, obj in ipairs(getTradeCards()) do
    if not isScrapped(obj) then
      local can, cb = getPlayerCardUse(color, obj, S_TRADE, S_PLAY)
      if can then
        -- Non-explorers 3x more likely to be purchased.
        if obj.getDescription() ~= "X" then
          table.insert(buyable, obj)
          table.insert(buyable, obj)
          table.insert(buyable, obj)
          odds = 7
        else
          table.insert(buyable, obj)
        end
        buycb = cb
      end
    end
  end

  if #hand < 2 and #buyable > 0 and math.random(1,8) <= odds then
    local obj = buyable[math.random(#buyable)]
    local cstate = {color, S_TRADE, {}, {}, ts=Time.time}
    qdo(buycb, color, obj, S_TRADE, S_PLAY, cstate)
    return
  end

  if math.random(3) == 2 and #hand == 5 then
    -- Some players play all all the time.
    if #hand > 0 then
      clickPlayAll(Player[color])
      return
    end
  end

  -- Try attacking something.
  local targets = getPlayState("targets")
  local dam = getPlayState("damage")

  if dam > 0 then
    -- Random targets first, then dump damage on players if can.
    local ptargets = {}
    for guid, def in pairs(targets) do
      if def == true then
        table.insert(ptargets, guid)
      elseif dam >= def and (math.random(0,3) < def) then
        if not getPlayState("destroyed", guid) then
          local obj = getObjectFromGUID(guid)
          -- Simulate double click (S_AUTO)
          local can, cb = getPlayerCardUse(color, obj, S_UNKNOWN, S_AUTO)
          if can then
            local cstate = {color, S_UNKNOWN, {}, {}, ts=Time.time}
            qdo(cb, color, obj, S_UNKNOWN, S_AUTO, cstate)
            return
          end
        end
      end
    end
    if #hand < 1 and #ptargets > 0 then
      local pickon = ptargets[math.random(#ptargets)]
      local ctoken = getTeamAuthToken(pickon)
      clickAuthToken(ctoken, color, false)
      return
    end
  end

  -- Try tossing a card from discard into a pile. This ... really only
  -- works if discard is a single card, because the SEARCHING hack
  -- is entirely too painful to replicate just for this dumb AI.
  local discard = getPlayerDeckAt(color, pdata["discardloc"], false)
  if discard and discard.tag == "Card" then
    for _, dest in ipairs({S_SCRAP, S_DISCARD, S_PLAY, S_PLAYER}) do
      local touse = discard
      if not isScrapped(touse) then
        local can, cb = getPlayerCardUse(color, touse, S_PLAYER_DISCARD, dest)
        if can then
          local cstate = {color, S_PLAYER_DISCARD, {}, {}, ts=Time.time}
          qdo(cb, color, touse, S_PLAYER_DISCARD, dest, cstate)
          return
        end
      end
    end
  end

  -- Try scrapping, discarding or scrapcycling something? Otherwise, play.
  if #hand > 0 then
    for _, dest in ipairs({S_SCRAP, S_DISCARD, S_PLAY, S_PLAYER}) do
      local touse = hand[math.random(1, #hand)]
      if not isScrapped(touse) then
        local can, cb = getPlayerCardUse(color, touse, S_HAND, dest)
        if can then
          local cstate = {color, S_HAND, {}, {}, ts=Time.time}
          qdo(cb, color, touse, S_HAND, dest, cstate)
          return
        end
      end
    end
  end

  -- Still here? Wow. Do we have anything left we can do? If not, let's play all
  if #hand > 0 then
    clickPlayAll(Player[color])
    return
  end

  -- I guess we're done?
  clickEndTurn(Player[color])
end

function dumbAITick()
  if GAMESTATE["state"] ~= RUNNING then return end
  if not hasAny(GAMESTATE.ais) then return end
  local playas = {}
  for color, _ in pairs(getCurrentPlayers()) do
    table.insert(playas, color)
  end
  shuffle(playas)
  for _, color in ipairs(playas) do
    if GAMESTATE.ais[color] then
      if not Player[color].seated then
        -- if not getPlayState("ready", color) then
        doSomethingDumb(color, isQOK())
        -- end
      end
    end
  end
end


