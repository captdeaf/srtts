function createXMLTurnUI(color)
  return wrapXMLInBG(
    {
      id = "turn" .. color,
      visibility = color,
      active = false,
      rectAlignment = "LowerRight", offsetXY = "-40 40",
      width = "20%", height = "20%",
      allowDragging = true, returnToOriginalPositionWhenReleased = false,
      bgimage = "dialogbg",
    },
    XML("TableLayout", {
      XML("Row", {
        XML("Cell", "titlecell", XMLText(color .. ": Your Turn", "title"))
      }),
      XML("Row", {
        XML("Cell", "buttoncell", {
          XML("Button",
            { class = "leftB", onClick = "clickPlayAll"},
            "Play All"
          ),
        }),
        XML("Cell", "buttoncell", {
          XML("Button",
            { class = "rightB", onClick = "clickEndTurn"},
            "End Turn"
          ),
        }),
      })
    })
  )
end

function createXMLStatUI(color)
  return XML("Panel",
    {
      id = "stat" .. color,
      visibility = color,
      active = false,
      color = "#f0f0f0",
      outline = "#635351",
      fontColor = "#000000",
      textColor = "#000000",
      outlineSize="2 -2",
      rectAlignment = "UpperCenter", offsetXY = "0 -80",
      width = "600", height = "120",
      padding = "15",
      allowDragging = true, returnToOriginalPositionWhenReleased = false,
    },
    XMLText("INFO HERE", "stat", "stat" .. color .. "T")
  )
end

function createXMLQuestionUI(color)
  local answerbutts = {}
  for i=1,10,1 do
    answerbutts[#answerbutts+1] = XML(
      "Button",
      {
        class = "button",
         id="ask" .. color .. "." .. tostring(i),
         onClick = "clickUIAnswer(" .. tostring(i) .. ")"
      },
      "Answer " .. tostring(i)
    )
  end

  return wrapXMLInBG(
    {
      id = "ask" .. color,
      visibility = color,
      active = false,
      rectAlignment = "UpperCenter", offsetXY = "0 -100",
      width = "30%", height = "20%",
      allowDragging = true, returnToOriginalPositionWhenReleased = false,
      bgimage = "dialogbg",
    },
    XML("TableLayout", {
      XML("Row", {
        XML("Cell", XMLText("Question ...", "title", "ask" .. color .. "Q"))
      }),
      XML("Row", {
        XML("Cell", "buttoncell", {
          XML("HorizontalLayout", answerbutts)
        }),
      })
    })
  )
end

function createXMLUI()
  -- Called at gameStart, when all colors are seated.
  --
  -- Goal: Create a turn dialog, player selection, and question/confirmation dialog for every seated player.

  local defaults = XML("Defaults", {
    XML("Text", {
      class = "stat",
      resizeTextForBestFit="false",
      color="black",
      fontSize = "18",
      alignment="upperLeft",
    }, false),
    XML("Text", {
      class = "itext",
      fontSize = "24",
      color="white",
      alignment="upperLeft",
    }, false),
    XML("Text", {
      class="title",
      resizeTextForBestFit="true",
      color="white",
      resizeTextMinSize="40"
    }, false),
    XML("Cell", {
      class="titlecell",
      columnSpan="2",
    }, false),
    XML("Cell", {
      class="info",
      columnSpan="2",
      resizeTextForBestFit="false",
      color="white",
    }, false),
    XML("Cell", {
      class="buttoncell",
      resizeTextForBestFit="true",
      color="white",
      resizeTextMinSize="40"
    }, false),
    XML("Button", {
      class = "leftB",
      color = "rgba(0.5, 0.8, 0.5, 0.7)",
      textColor = "white"
    }, false),
    XML("Button", {
      class = "rightB",
      color = "rgba(0.5, 0.5, 0.8, 0.7)",
      textColor = "white"
    }, false),
  })

  local allxmls = {}

  allxmls[#allxmls+1] = defaults

  for color in allSeatedColors() do
    allxmls[#allxmls+1] = createXMLTurnUI(color)
    allxmls[#allxmls+1] = createXMLStatUI(color)
    allxmls[#allxmls+1] = createXMLQuestionUI(color)
  end
  UI.setXmlTable(allxmls)
end

function clearUIElements()
  for col, _ in pairs(PLAYER_ZONE) do
    hideUI("stat" .. col)
    hideUI("turn" .. col)
    hideUI("ask" .. col)
  end
end

function clearTurnUIs()
  for col in allSeatedColors() do
    hideUI("turn" .. col)
  end
end

function showTurnUI()
  for color, _ in pairs(getTeamPlayers(GAMESTATE["playing"])) do
    local turnkey = "turn" .. color
    showUI(turnkey, color)
  end

  for enemyteam, _ in pairs(getOpponents(GAMESTATE["playing"])) do
    for enemycol, _ in pairs(getTeamPlayers(enemyteam)) do
      hideUI("turn" .. enemycol)
    end
  end
end

function clickUIAnswer(player, value)
  local i = tonumber(value, 10)
  local color = player.color
  if not CURRENT_QUESTION[color] then return end
  local qdef = CURRENT_QUESTION[color]
  local answers = qdef["answers"]
  if not answers then
    die("Invalid UI Answer for %s? (%s)", color, tostring(value))
    return
  end
  local chosen = nil
  local selected = nil
  if answers[i] then
    if qdef["selects"] then
      selected = getSelectedCards(color)
    end

    local answer = answers[i]
    if answer[2] ~= nil then
      chosen = answer[2]
    end
    CURRENT_QUESTION[color] = nil
    table.remove(QUESTIONS[color], 1)
    QUESTION_CHECKS[color][qdef["guid"]] = nil
  end
  if #QUESTIONS[color] > 0 then
    showQuestionDialog(color)
  else
    hideUI("ask" .. color)
  end
  if chosen then
    qdo(chosen, selected)
  end
  updatePlayState()
end

function askQuestion(guid, color, question, answers, selects)
  -- In necessity, answers is of format:
  -- {
  --   {"Bob", function() playBobCard() end},
  --   {"Daisy", function() attack("daisy") end },
  --   etc. Text and callbacks.
  -- }
  if not QUESTIONS[color] then
    CURRENT_QUESTION[color] = nil
    QUESTIONS[color] = {}
    QUESTION_CHECKS[color] = {}
  end

  if QUESTION_CHECKS[color][guid] then
    local obj = getObjectFromGUID(guid)
    if obj then
      die("Double-asking for object GUID '%s' (%s)", obj.getGUID(), obj.getName())
    else
      die("Double-asking for nonexistent GUID '%s'", guid)
    end
    return
  end

  if selects then
    selects["choices"] = {}
  end

  table.insert(QUESTIONS[color], {
    guid=guid,
    question=question,
    answers=answers,
    selects=selects,
    acceptable=true,
  })
  QUESTION_CHECKS[color][guid] = true

  if CURRENT_QUESTION[color] == nil then
    showQuestionDialog(color)
  end
end

function askSelectCard(guid, color, question, selects, onselect, oncancel)
  askQuestion(guid, color, question, {
    {"Accept Selection", onselect},
    {"Cancel", oncancel}
  }, selects)
end

function getSelectQuestion(qdef)
  local question = qdef["question"]
  local selects = qdef["selects"]
  local choices = selects["choices"]

  local ret = question .. ": "

  if choices and #choices > 0 then
    ret = ret .. guidsToNames(choices)
  else
    ret = ret .. "(None)"
  end
  return ret
end

function getSelectedCards(color)
  local colq = CURRENT_QUESTION[color]
  if not colq then die("%s trying getSelected, has no question?", color) end
  local selects = colq["selects"]
  if not selects then die("%s trying getSelected, has no selects?", color) end
  local choices = selects["choices"]
  if not choices then die("%s trying getSelected, has no choices?", color) end
  return guidsToObjects(choices)
end

function trySelect(color, loc, obj)
  local qdef = CURRENT_QUESTION[color]
  if not isSelectable(color, loc, obj) then return end

  local selects = qdef["selects"]

  local guid = obj.getGUID()

  if isMember(selects["choices"], guid) then
    -- Remove this selection
    local old = selects["choices"]
    selects["choices"] = {}
    for _, g in ipairs(old) do
      if g ~= guid then
        table.insert(selects["choices"], g)
      end
    end
  else
    -- A new selection.
    table.insert(selects["choices"], guid)
    if #selects["choices"] > selects["max"] then
      table.remove(selects["choices"], 1)
    end
  end

  local choices = selects["choices"]
  local acceptable = true

  if (qdef["selects"] and qdef["selects"]["min"]
      and qdef["selects"]["min"] > #choices) then
    acceptable = false
  end
  qdef["acceptable"] = acceptable

  UI.setAttribute("ask" .. color .. "Q", "text", getSelectQuestion(qdef))
  UI.setAttribute("ask" .. color .. ".1", "interactable", acceptable)
end

function showQuestionDialog(color)
  if not QUESTIONS[color] or #QUESTIONS[color] < 1 then
    die("Err, question dialog when no question?")
    return
  end
  local qdef = QUESTIONS[color][1]
  CURRENT_QUESTION[color] = qdef

  local answers = qdef["answers"]
  -- Up to 10 questions.

  if qdef["selects"] then
    UI.setAttribute("ask" .. color .. "Q", "text", getSelectQuestion(qdef))
  else
    UI.setAttribute("ask" .. color .. "Q", "text", qdef["question"])
  end
  for i=1,10,1 do
    if answers[i] ~= nil then
      UI.setAttributes("ask" .. color .. "." .. tostring(i), {
        active = true,
        interactable = true,
        text = answers[i][1],
      })
    else
      UI.setAttribute("ask" .. color .. "." .. tostring(i), "active", "false")
    end
  end

  -- Special case for select:
  if (qdef["selects"] and qdef["selects"]["min"]
      and qdef["selects"]["min"] > 0) then
    UI.setAttribute("ask" .. color .. ".1", "interactable", "false")
    qdef["acceptable"] = false
  end

  showUI("ask" .. color, color)
end

function clickEndTurn(player)
  qdo(tryEndTurn, player)
end

function clickPlayAll(player)
  if GAMESTATE["state"] ~= RUNNING then return end
  local color = player.color
  qdo(doPlayAll, color)
end

function askOpponentDiscard(color, obj, cardname, count)
  local opps = getTargetOpponents(color)

  if howMany(opps) == 1 then
    for col, _ in pairs(opps) do
      makeDiscard(color, col, cardname, count)
    end
  else
    local choices = {}
    for col, _ in pairs(opps) do
      local name = playerName(col)
      choices[#choices+1] = {
        name .. "(" .. col .. ")",
        function() makeDiscard(color, col, cardname, count) end
      }
    end
    -- Nobody discards // default.
    choices[#choices+1] = {"Nobody", nil}
    askQuestion(
        obj.getGUID(),
        color,
        ("Target Opponent to discard " .. tostring(count) .. "\n" ..
         "(" .. cardname .. ")"),
        choices)
  end
end

