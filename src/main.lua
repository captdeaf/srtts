-- Tie everything together, and load+save.

function onLoad(save_state)
  math.randomseed(Time.time)
  -- Things to do on every load, not just clean up.
  -- Basically: rebuild PDATA from zones, load cards,
  -- etc.
  loadCards()
  buildHouseRules()
  mapObjects()
  fixObjects()
  setCustomUIAssets()
  mapColors()
  mapPlayers()
  mapTradeLocs()
  makeSnapPoints()
  drawVectors()
  clearIndicators()

  local saved = nil

  if save_state then
    if not pcall(function() saved = JSON.decode(save_state) end) then
      saved = nil
    end
  end

  if saved and #saved == 3 then
    local ver, menu_choices, gamestate = unpack(saved)
    if ver >= VERSION then
      GAMESTATE = gamestate
      MENU_CHOICES = menu_choices
      if GAMESTATE["state"] == RUNNING then
        qdo(refreshAfterSave)
      else
        updateState(GAMESTATE["state"])
      end
    end
  end
  if GAMESTATE == nil then
    cleanupGame()
  end

  greenWait({
    qwait = false,
    time = 4,
    count = -1,
    callback = qdoTick,
  })
  greenWait({
    qwait = false,
    time = 0.5,
    count = -1,
    callback = timerTick,
  })
  greenWait({
    qwait = false,
    time = 0.2,
    count = -1,
    callback = dumbAITick,
  })
end

-- I keep typing this as refreshAfterShave...
function refreshAfterSave()
  mapHouseRules()
  for _, obj in ipairs(getAllObjects()) do
    if obj.tag == "Tile" then
      local teamdata = GAMESTATE["teams"][obj.getDescription()]
      setupTokenCounter(obj, teamdata)
    end
  end
  createXMLUI()
  greenWait({
    name = "refreshaftersave",
    qwait = true,
    frames = 30,
    callback = function()
      clearUIElements()
      waitUntilSettled(function()
        clearUIElements()
        updateState(GAMESTATE["state"])
        startTurnUI(GAMESTATE["playing"])
      end)
    end
  })
end

function onSave()
  return JSON.encode({VERSION, MENU_CHOICES, GAMESTATE})
end

function cleanupGame()
  qCleanup()
  QUESTIONS = {}
  CURRENT_QUESTION = {}
  QUESTION_CHECKS = {}
  GAMESTATE = duplicate(GAMESTATE_CLEAN)
  Global.setDecals({})
  greenWait({
    qwait = false,
    frames = 30,
    count = 4,
    callback = function() Global.setDecals({}) end
  })
  clearNotes()
  clearUIElements()
  clearIndicators()
  destroyGameObjects()
  updateState(UNREADY)
end

