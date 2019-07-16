function makeButton(butt, funcname, label, col)
  -- see if butt already has buttons.
  local params = {
    click_function = funcname,
    label = label,
    position = {x=0, y=0.51, z=0},
    scale = {x=10.0, y=3.0, z=10.0},
    font_size = 50,
    color = stringColorToRGB(col),
    font_color = {r=1, g=0.8, b=1},
    hover_color = {r=0.5, g=0.8, b=0.5},
    press_color = {r=0.8, g=0.8, b=0.8},
  }

  local butts = butt.getButtons()
  if butts and #butts > 0 then
    params["index"] = 0
    butt.editButton(params)
  else
    butt.createButton(params)
  end
end

ENDGAME_TIMEOUT = 0

function clearEndGame()
  -- It's 0 if somebody ended game.
  if ENDGAME_TIMEOUT == 0 then return end
  ENDGAME_TIMEOUT = ENDGAME_TIMEOUT - 1
  if (ENDGAME_TIMEOUT > 0) then
    makeButton(GameObjects.STATE_BUTTON, "clickEndGame", "Click again to end (" .. ENDGAME_TIMEOUT .. ")", "White")
    greenWait({
      qwait = false,
      time = 1.0,
      callback = clearEndGame
    })
  else
    makeButton(GameObjects.STATE_BUTTON, "clickEndGame", "End Game (quit)", "Red")
  end
end

function clickEndGame(obj, playercol, _)
  if ENDGAME_TIMEOUT > 0 then
    ENDGAME_TIMEOUT = 0
    cleanupGame()
  else
    ENDGAME_TIMEOUT = 7
    clearEndGame()
  end
end

function clickToggleScript(obj, playercol, _)
  if GAMESTATE["state"] == RUNNING then
    announceGame("Scripting Disabled")
    GAMESTATE["state"] = UNSCRIPTED
  elseif GAMESTATE["state"] == UNSCRIPTED then
    GAMESTATE["state"] = RUNNING
    announceGame("Scripting Enabled")
    updatePlayState()
  end
  updateButtons()
end

function clickPSToken(tok, _, alt_click)
  if GAMESTATE["state"] ~= UNSCRIPTED then
    whine("No cheating!")
    return
  end
  local what = "trade"
  if tok.getGUID() == GameObjects.DAMAGE_TOKEN.getGUID() then
    what = "damage"
  end
  local tot
  if alt_click then
    tot = tweakPlayState(what, function(x) return x + 1 end)
  else
    tot = tweakPlayState(what, function(x) return x - 1 end)
  end
  setTokenText(tok, tot)
end

function setTokenText(tok, text, funcname)
  -- see if tok already has the fake "button" text.
  local size = 0
  if GAMESTATE["state"] == UNSCRIPTED then
    size = 1000
  end
  local params = {
    label = tostring(text),
    position={0,0.51,0},
    height=size,
    width=size,
    color={r=0.7,g=0.7,b=1},
    font_size=250,
    font_color={0,0,0},
    click_function = "clickPSToken",
  }

  local butts = tok.getButtons()
  if butts and #butts > 0 then
    params["index"] = 0
    tok.editButton(params)
  else
    tok.createButton(params)
  end
end

function updatePlayBox(state)
  if state == UNREADY then
    GameObjects.PLAY_BOX.setPosition({x = 0.0, y = 5.0, z = 0.0})
    GameObjects.PLAY_BOX.setRotation({x = 0.0, y = 180.0, z = 0.0})
    GameObjects.PLAY_BOX.setLock(false)
  else
    GameObjects.PLAY_BOX.setPosition({x=-100, y=5, z=0})
    GameObjects.PLAY_BOX.setRotation({x=0, y=270.0, z=0})
    GameObjects.PLAY_BOX.setLock(true)
  end
end

function updateButtons()
  if GAMESTATE["state"] == STARTING then
    makeButton(GameObjects.STATE_BUTTON, "ignoreInput", "...", "Black")
    makeButton(GameObjects.SCRIPT_BUTTON, "ignoreInput", "...", "Black")
  elseif GAMESTATE["state"] == RUNNING then
    makeButton(GameObjects.STATE_BUTTON, "clickEndGame", "End Game (quit)", "Red")
    makeButton(GameObjects.SCRIPT_BUTTON, "clickToggleScript", "Disable Script", "Brown")
    setTokenText(GameObjects.TRADE_TOKEN, getPlayState("trade") or 0)
    setTokenText(GameObjects.DAMAGE_TOKEN,  getPlayState("damage") or 0)
  elseif GAMESTATE["state"] == UNSCRIPTED then
    makeButton(GameObjects.STATE_BUTTON, "clickEndGame", "End Game (quit)", "Red")
    makeButton(GameObjects.SCRIPT_BUTTON, "clickToggleScript", "Enable Script", "Brown")
    setTokenText(GameObjects.TRADE_TOKEN, getPlayState("trade") or 0)
    setTokenText(GameObjects.DAMAGE_TOKEN,  getPlayState("damage") or 0)
  elseif GAMESTATE["state"] == ENDED then
    makeButton(GameObjects.STATE_BUTTON, "clickCleanup", "Clean up & Reset", "Green")
    makeButton(GameObjects.SCRIPT_BUTTON, "clickCleanup", " ", "Yellow")
  else
    -- New, Ended, or Confused State
    makeButton(GameObjects.STATE_BUTTON, "clickStart", "Start Game", "Green")
    makeButton(GameObjects.SCRIPT_BUTTON, "clickCleanup", "Reset Board", "Yellow")
  end
end

-- Initially taken from "Better notecards and counters", by Idan
-- Modified for my scripting needs.

function clickAuthToken(ctoken, color, alt_click)
  qdo(clickAuthTokenReal, ctoken, color, alt_click)
end

function createTeamAuthToken(teamdata)

  local describe = teamdata["name"]

  local jstoken = {
    Name = "Custom_Token",
    Transform = {
      posX = 0.0, posY = 4.0, posZ = 0.0,
      rotX = 0.0, rotY = 0.0, rotZ = 0.0,
      scaleX = 1.0, scaleY = 1.0, scaleZ = 1.0,
    },
    Nickname = teamName(teamdata["name"]),
    Description = describe,
    ColorDiffuse = teamdata["authcolor"],
    CustomImage = {
      ImageURL = "http://cloud-3.steamusercontent.com/ugc/958597478463059274/DE73B64E1B5C6F272EA3BEE5EF458E73E48FF03D/",
      ImageSecondaryURL = "",
      WidthScale = 0.0,
      CustomToken = {
        Thickness = 0.1,
        MergeDistancePixels = 5.0,
        Stackable = false,
      }
    }
  }

  local cb = function(obj, _, _)
    setupTokenCounter(obj, teamdata)
  end

  spawnObjectJSON({
    json = JSON.encode(jstoken),
    position = teamdata["position"],
    rotation = teamdata["rotation"],
    scale = {x=TOKENSCALE, y=1.0, z=TOKENSCALE},
    sound = false,
    callback_function = qWaitFor("authtoken", cb),
  })
end

-- Called after setup, or on load after save&reload.
function setupTokenCounter(ctoken, teamdata)
  local authority = teamdata["authority"]
  local teamname = teamdata["name"]

  ctoken.createButton({
    label = tostring(authority),
    click_function = "clickAuthToken",
    tooltip = nil,
    position = {x=0.0, y=0.05, z=0},
    height = 1600,
    width = 1600,
    font_size = 500,
    font_color = {1,1,1},
    color = teamdata["authcolor"],
  })

  ctoken.createButton({
    click_function = "ignoreInput",
    tooltip = nil,
    label = teamname,
    alignment = 3,
    position = {x=0.0, y=0.5, z=-2.0},
    rotation = {x=0.0, y=180.0, z=0.0},
    width = 0,
    height = 0,
    font_size = 350,
    scale = {x=1, y=1, z=1},
    font_color = {r=1, g=1, b=1, a=100},
    color = teamdata["authcolor"],
  })

  ctoken.setLock(true)
end


