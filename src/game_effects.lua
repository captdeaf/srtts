USE_TEMPLATES = {}

USE_TEMPLATES["mustuse"] = {
  must = true,
}

USE_TEMPLATES["mayuse"] = {}

USE_TEMPLATES["mustscrap"] = {
  must = true,
  id = "scrap",
  to = TO_SCRAP,
  count = 1,
  cardmessage = "scraps %s",
}

USE_TEMPLATES["tradescrap"] = {
  from = {S_TRADE},
  id = "scrap",
  to = TO_SCRAP,
  count = 1,
  cardmessage = "scraps %s from trade",
}

USE_TEMPLATES["mayscrap"] = {
  id = "scrap",
  to = TO_SCRAP,
  count = 1,
  cardmessage = "scraps %s",
}

USE_TEMPLATES["scrapfor"] = {
  from = {S_HAND},
  to = TO_SCRAP,
  count = 1,
}

USE_TEMPLATES["scrapcycle"] = {
  id = "scrapcycle",
  from = {S_HAND},
  to = TO_SCRAP,
  count = 1,
  cardmessage = "scrapcycles %s",
  effects = {draw=1},
}

USE_TEMPLATES["recycle"] = {
  id = "recycle",
  from = {S_HAND},
  to = TO_DISCARD,
  count = 1,
  cardmessage = "recycles %s",
  effects = {draw=1},
}

USE_TEMPLATES["discardtotop"] = {
  to = TO_TOP,
  from = {S_PLAYER_DISCARD},
  cardmessage = "moves %s to top of deck",
  id = "discardttop",
}

function describeEffects(effects, cardname)
  local ret = {}
  local done = {}

  local append = function(str, ...)
    local fmtstr = str:format(...)
    ret[#ret+1] = fmtstr
  end
  if effects["t"] then
    done["t"] = true
    append("gain %d Trade", effects["t"])
  end
  if effects["d"] then
    done["d"] = true
    if effects.d == "cost" then
      append("gain attack equal to cost")
    else
      append("gain %d Attack", effects["d"])
    end
  end
  if effects["a"] then
    done["a"] = true
    append("gain %d Authority", effects["a"])
  end
  if effects["draw"] then
    done["draw"] = true
    if effects["draw"] == 1 then
      append("draw 1 card")
    else
      append("draw %d cards", effects["draw"])
    end
  end
  if effects["ally"] then
    done["ally"] = true
    append("allies " .. concatAnd(effects["ally"]))
  end
  if effects["mustdiscard"] then
    done["mustdiscard"] = true
    append("discard %d cards", effects["mustdiscard"])
  end
  if effects["choose"] then
    local opts = mapList(effects["choose"], function(e) return describeEffects(e, cardname) end)
    append("choose between: %s", concatAnd(opts, "or"))
    done["choose"] = true
  end
  if effects["uniq"] then
    done["uniq"] = true
    local u = effects["uniq"]
    if u[1] == "blobworld" then
      append("draw 1 card for every blob card played.")
    elseif u[1] == "reclamation" then
      append("gain 3 damage for every card you've scrapped this turn (including this one)")
    else
      append("unique '%s' effect (not added to describe yet)", effects["uniq"][1])
    end
  end
  if effects["destroybase"] then
    done["destroybase"] = true
    append(oneormore(effects["destroybase"], "destroy target base", "destroy %d target bases"))
  end
  if effects["oppdiscard"] then
    done["oppdiscard"] = true
    append(oneormore(effects["oppdiscard"], "target opponent discards a card", "target opponent discards %d cards"))
  end
  for k, v in pairs(USE_TEMPLATES) do
    if effects[k] then
      done[k] = true
      local params = duplicate(v)
      params = mergeTables({params, effects[k]})
      params.id = params.id or cardname
      append(describeCardUse(params))
    end
  end

  for k, _ in pairs(effects) do
    if not done[k] then
      whine("Undescribed effect for %s: %s", cardname, k)
      append("undescribed: %s", k)
    end
  end

  return table.concat(ret, ", ")
end

function applyEffects(color, obj, card, effects, position, issub, isnew, choice)
  local pinfo = GAMESTATE["players"][color]
  local cardname = card["name"]
  if issub then
    -- "issub": A sub-action, cannot have additional actions (e.g: scrap can't
    -- have ally effects)
    cardname = cardname .. "+" .. issub
  else
    issub = false
  end

  if not isPlaying(color) then
    die("%s isn't playing but triggered applyEffects somehow?", color)
    return
  end

  local done = {}
  done["buyto"] = true
  local chosen = nil

  if not issub and effects["uniq"] and effects["uniq"][1] == "stealthneedle" then
    -- { "Stealth Needle", SHIP, {MC}, 4 , {uniq={"stealthneedle"}}},
    askSelectCard(obj.getGUID(), color, "Become a copy of", {
        min = 0, max = 1,
        types = {SHIP},
        owners = {color},
        sources = {S_PLAY, S_PLAYER},
        checkfunc = function(o,c) return c["name"] ~= obj.getName() end,
      },
      function(sels) playStealthNeedle(color, obj, sels) end)
    return false
  end
  if effects["choose"] and isnew and card["type"] == SHIP then
    if choice ~= nil then
      chosen = effects["choose"][choice]
    else
      local choices = {}
      for idx, val in ipairs(effects["choose"]) do
        choices[#choices+1] = {
          describeEffects(val, cardname),
          function() replayWithChoice(color, cardname, obj, true, idx) end
        }
      end
      choices[#choices+1] = { "Cancel", nil }
      askQuestion(obj.getGUID(), color, cardname .. " (Choose):", choices)
      return false
    end
  end
  if effects["mercenary"] and isnew then
    done["mercenary"] = true
    local choices = {}
    for _, fac in ipairs({MC, BB, TF, SE}) do
      choices[#choices+1] = {
        fac,
        function() replayWithChoice(color, sprintf("%s: %s", card["name"], fac), obj, true, nil) end
      }
    end
    choices[#choices+1] = { "Cancel", nil }
    askQuestion(obj.getGUID(), color, cardname .. " Faction:", choices)
    return false
  end

  if isnew then
    if obj.getName() ~= cardname then
      announce(color, "plays %s (%s)", cardname, obj.getName())
    else
      announce(color, "plays %s", cardname)
    end
  end

  if effects["onplay"] then
    if isnew then
      applyEffects(color, obj, card, effects["onplay"], position, "On play", false, nil)
    end
    done["onplay"] = true
  end

  if effects["t"] then
    local tot = tweakPlayState("trade", function(t) return t + effects["t"] end)
    logEffect(color, cardname, "gained %d trade (%d)", effects["t"], tot)
    showIndicator(obj, "trade")
    done["t"] = true
  end
  if effects["d"] then
    local dam = effects["d"]
    if dam == "cost" then dam = card.cost end
    local tot = tweakPlayState("damage", function(d) return d + dam end)
    logEffect(color, cardname, "gained %d attack (%d)", dam, tot)
    showIndicator(obj, "damage")
    done["d"] = true
  end
  if effects["a"] then
    local newa = changeTeamAuthority(color, effects["a"])
    logEffect(color, cardname, "gained %d authority (%d)", effects["a"], newa)
    showIndicator(obj, "authority")
    done["a"] = true
  end

  -- Draw must come before any of the musts (e.g: mustscrap), or Machine
  -- Base, etc will not work.
  if effects["draw"] then
    done["draw"] = true
    addMust(color, "draw", effects["draw"])
    showIndicator(obj, "draw")
    announce(color, oneormore(effects["draw"], "draws a card", "draws %d cards") .. " (".. cardname .. ")")
    if effects["draw"] == 1 then
      logEffect(color, cardname, "Draws a card")
    else
      logEffect(color, cardname, "Draws %d cards", effects["draw"])
    end
  end

  if not issub then
    -- Only apply tags when it's not a sub-play.
    applyTags(color, card, isnew)
  end

  if effects["ontag"] then
    done["ontag"] = true
    local tagname = effects["ontag"][1]
    local tageffect = effects["ontag"][2]
    local forexisting = effects["ontag"][3] or false

    local ontags = getPlayState(color, "ontags")
    if not ontags[tagname] then ontags[tagname] = {} end
    local forsave = {
      guid=obj.getGUID(),
      cardname=card["name"],
      effect=tageffect,
      min=0,
      limit=-1,
    }
    table.insert(ontags[tagname], forsave)

    if forexisting and getTag(color, tagname) then
      for i=1,getTag(color, tagname),1 do
        applyEffects(color, obj, card, tageffect, position, "ontag", false)
      end
    end
  end

  local interactions = getPlayState(color, "interactables", obj.getGUID()) or {}
  -- destroybase=1: Destroy target base
  -- tradescrap=2: Scrap up to 2 cards in trade row
  -- choose={{t=2},{a=2}}: Pick between 2 trade or 2 authority
  -- mayscrap={HAND_ONLY, 2}: May Scrap 2 cards from hand
  -- mustscrap={HAND_ONLY, 1}: Must Scrap 1 card from hand
  -- oppdiscard=1: Opponent discards 1

  if effects["onactivate"] then
    done["onactivate"] = true
    if interactions["activate"] then
      table.insert(interactions["activate"], effects["onactivate"])
    else
      interactions["activate"] = {effects["onactivate"]}
    end
  end

  if effects["onscrap"] then
    done["onscrap"] = true
    interactions["scrap"] = effects["onscrap"]
  end

  if effects["oppdiscard"] then
    askOpponentDiscard(color, obj, cardname, effects["oppdiscard"])
    logEffect(color, cardname, "pick target opponent to discard")
    done["oppdiscard"] = true
  end

  if effects["choose"] then
    if chosen ~= nil then
      applyEffects(color, obj, card, chosen, position, "Choice", false)
    elseif issub then
      local choices = {}
      for idx, eff in ipairs(effects["choose"]) do
        choices[#choices+1] = {
          describeEffects(eff, cardname),
          function() applyEffects(color, obj, card, eff, position, "Choice", false) end
        }
      end
      askQuestion(obj.getGUID(), color, cardname .. " (Choose):", choices)
    else
      interactions["choose"] = effects["choose"]
    end
    done["choose"] = true
  end

  if effects["destroybase"] then
    done["destroybase"] = true
    pinfo["mays"]["destroybase"] = pinfo["mays"]["destroybase"] + effects["destroybase"]
    logEffect(color, cardname, oneormore(effects["destroybase"], "may destroy a base", "may destroy %d bases"))
  end

  if effects["mustdiscard"] then
    done["mustdiscard"] = true
    makeDiscard(cardname, color, cardname, effects["mustdiscard"])
    logEffect(color, cardname, "must discard %d", effects["mustdiscard"])
  end

  for k, v in pairs(USE_TEMPLATES) do
    if effects[k] then
      done[k] = true
      local params = duplicate(v)
      mergeTables({params, effects[k]})
      params.id = params.id or cardname
      if v.must then
        addMustUse(color, obj, params)
      else
        addMayUse(color, obj, params)
      end
    end
  end

  if effects["uniq"] then
    local uparams = effects["uniq"]
    local uwhat = uparams[1]
    if uwhat == "blobworld" then
      local count = getTag(color, "play:bb")
      announce(color, oneormore(count, "draws a card", "draws %d cards") .. " (".. cardname .. ")")
      if count > 0 then
        addMust(color, "draw", count)
      end
      done["u.blobworld"] = true
    elseif uwhat == "reclamation" then
      -- Add one since reclamation is triggered before scrap tag is added for the station.
      local amt = (getTag(color, "scrap") + 1) * 3
      announce(color, "scraps reclamation station for %d damage", amt)
      tweakPlayState("damage", function(d) return d + amt end)
      done["u.reclamation"] = true
    elseif uwhat == "freecard" then
      interactions["freecard"] = uparams
      done["u.freecard"] = true
    elseif uwhat == "stealthtower" then
      interactions["stealthtower"] = uparams
      done["u.stealthtower"] = true
    elseif uwhat == "mayreturn" then
      interactions["mayreturn"] = uparams
      done["u.mayreturn"] = true
    elseif uwhat == "nextbuyto" then
      -- Hrmmmmmm... next card, next ship, next base.
      -- ANY clears SHIP and BASES.
      -- SHIPS and BASES may be separate, but ANY overrides.
      -- TO_PLAY > TO_HAND > TO_TOP > TO_DISCARD
      local nbts = getPlayState(color, "nextbuyto")
      local ctypes = uparams[2]
      local playto = uparams[3]
      if isPlaytoBetter(playto, nbts[ctypes]) then
        nbts[ctypes] = playto
        logEffect(color, cardname, "moves next purchase of %s %s", ctypes, playto)
      end
      done["u.nextbuyto"] = true
    end
  end

  if effects["check"] then
    local v = effects["check"]
    if checkTag(color, v[1], v[2]) then
      applyEffects(color, obj, card, v[3], position, "Check", false)
    elseif v[4] then
      -- If v[4], it's san "ongoing check" - if it happens at all,
      -- past or future, it'll pass.
      local tagname = v[1]
      local ontags = getPlayState(color, "ontags")
      if not hasAny(ontags[tagname]) then ontags[tagname] = {} end
      local forsave = {
        guid=obj.getGUID(),
        cardname=card["name"],
        effect=v[3],
        min=v[2] or 1,
        limit=1,
      }
      table.insert(ontags[tagname], forsave)
    end
    done["check"] = true
  end

  local allies = getPlayState(color, "allies")

  if effects["ally"] then
    done["ally"] = true
    -- Mech world, heroes.
    triggerAllyEffects(color, effects["ally"])
    logEffect(color, cardname, "allies %s for the rest of the turn", concatAnd(effects["ally"]))
    for _, faction in ipairs(effects["ally"]) do
      setPlayState(color, "allies", faction, true)
      setPlayState(color, "effectallies", faction, true)
    end
  end

  done["tf"] = true
  done["se"] = true
  done["bb"] = true
  done["mc"] = true

  done["def"] = true

  if not issub then
    if obj.getName() ~= cardname then
      -- Stealth Needle and Tower.
      local realcard = ALL_CARDS[obj.getName()]
      triggerAllyEffects(color, realcard["factions"])
    end
    triggerAllyEffects(color, card["factions"])

    local needs = getPlayState(color, "needally")

    local allymap = { mc = MC, se = SE, bb = BB, tf = TF }
    for key, faction in pairs(allymap) do
      if effects[key] then
        if allies[faction] then
          applyEffects(color, obj, card, effects[key], position, "Ally", false)
        else
          table.insert(needs, {{faction}, effects[key], obj.getGUID()})
        end
      end
    end

    if effects["union"] and #effects["union"] > 0 then
      done["union"] = true
      -- union is a list of {factions,effects}
      for _, union in ipairs(effects["union"]) do
        local hasally = false
        for _, faction in ipairs(union[1]) do
          if allies[faction] then hasally = true end
        end
        if hasally then
          applyEffects(color, obj, card, union[2], position, "Union", false)
        else
          table.insert(needs, {union[1], union[2], obj.getGUID()})
        end
      end
    end

    setPlayState(color, "played", obj.getGUID(), cardname)

    for _, faction in ipairs(card["factions"]) do
      setPlayState(color, "allies", faction, true)
    end
  end

  if hasAny(interactions) then
    setPlayState(color, "interactables", obj.getGUID(), interactions)
  end

  -- Sanity checking.
  for k, v in pairs(effects) do
    if not done[k] then
      if k == 'uniq' then
        local kn = v[1]
        if not done["u." .. kn] then
          die("Unapplied Unique effect for %s: %s", cardname, kn)
        end
      else
        die("Unapplied effect for %s: %s", cardname, k)
      end
    end
  end

  return true
end

function describeMays(mays)
  local rets = {}
  if mays["destroybase"] > 0 then
    table.insert(rets, oneormore(mays["destroybase"],
      "You may destroy an enemy base.",
      "You may destroy %d enemy bases."
    ))
  end
  for _, use in ipairs(mays["carduses"]) do
    table.insert(rets, describeCardUse(use, "You may"))
  end
  local ret = table.concat(rets, "\n")
  return ret
end

function applyMusts(color)
  local pinfo = GAMESTATE["players"][color]
  local musts = pinfo["musts"]
  local player = Player[color]
  local hand = player.getHandObjects()
  local keepgoing = true

  while keepgoing and musts and #musts > 0 do
    keepgoing = false
    local must = musts[1]
    if must[1] == "draw" then
      drawToPlayer(color, must[2])
      keepgoing = false
      table.remove(musts, 1)
    elseif must[1] == "scrap" then
      if not must[2] or  #must[2] < 1 then
        table.remove(musts, 1)
        keepgoing = true
      end
    elseif must[1] == "discard" then
      if must[2] == 0 then
        table.remove(musts, 1)
        keepgoing = true
      elseif #hand == 0 then
        announce(color, "has no more to discard")
        table.remove(musts, 1)
        keepgoing = true
      end
    end
  end
end

function updateStatUI(color)
  if not GAMESTATE["players"] then return end
  if not GAMESTATE["players"][color] then return end
  local pinfo = GAMESTATE["players"][color]
  local musts = pinfo["musts"]
  local mays = pinfo["mays"]

  local statkey = "stat" .. color
  local statkeyt = statkey .. "T"

  local ret = ""

  if musts and #musts > 0 then
    ret = describeMusts(musts)
  end
  if ret == "" then
    ret = describeMays(mays)
  end
  if ret ~= "" then
    UI.setAttribute(statkeyt, "text", ret)
    showUI(statkey, color)
  else
    hideUI(statkey)
  end
end

function describeMusts(musts)
  local ret = ""
  local must = musts[1]
  if must[1] == "discard" then
    ret = "Discard " .. tostring(must[2]) .. " cards."
  elseif must[1] == "carduse" then
    ret = describeCardUse(must[2], "You must")
  end

  if #musts > 1 then
    ret = ret .. " (+" .. tostring(#musts-1) .. ")"
  end
  return ret
end


