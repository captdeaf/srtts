IS_MENU_OPEN = false

function menuStart()
  if not IS_MENU_OPEN then return end
  IS_MENU_OPEN = false
  if not checkRules() then
    broadcastToAll("!! Game cannot start", {r=1.0, g=0.5, b=0.5})
    return
  end

  announceGame("Game starting with decks: %s", concatAnd(mapList(GAMESTATE["decks"], tostring)))

  -- On game start: Destroy all the cards, clear notecard
  if GAMESTATE["state"] ~= UNREADY then
    whine("menuStart called when not unready?")
    return
  end

  updateState(STARTING)
  qdo(gameStart)
end

function menuDeckSub(col, deckname)
  if not IS_MENU_OPEN then return end
  MENU_CHOICES["decks"][deckname] = (MENU_CHOICES["decks"][deckname] or 0) - 1

  if MENU_CHOICES["decks"][deckname] < 0 then
    MENU_CHOICES["decks"][deckname] = 0
  end
  populateMenu()
end

function menuDeckAdd(col, deckname)
  if not IS_MENU_OPEN then return end
  MENU_CHOICES["decks"][deckname] = (MENU_CHOICES["decks"][deckname] or 0) + 1

  if MENU_CHOICES["decks"][deckname] > 6 then
    MENU_CHOICES["decks"][deckname] = 6
  end
  populateMenu()
end

function createXMLDeckSelections()
  local ret = {}
  local bgs = {"#fffff0", "#fff0ff"}
  for idx, deck in ipairs(AVAILABLE_DECKS) do
    local bg = bgs[(idx % #bgs) + 1]
    local count = deck["count"]
    if MENU_CHOICES["decks"][deck["name"]] then
      count = MENU_CHOICES["decks"][deck["name"]]
    end
    ret[#ret+1] = XML("VerticalLayout", {
      padding = 10,
      color=bg,
    }, {
      XMLText("<b>" .. deck["name"] .. "</b>", "dname"),
      XML("Panel", {padding = 10}, {
        XML("Button",
          {
            onClick = "menuDeckSub(" .. deck["name"] .. ")",
            fontSize=12,
            height = 20, width = 20,
            textColor="#000000",
            rectAlignment="MiddleLeft",
          },
          "-"
        ),
        XML("Text", {
          text=tostring(count),
          id=deck["name"] .. ".count",
          fontSize=18.0,
          rectAlignment="MiddleCenter",
        }, false),
        XML("Button",
          {
            onClick = "menuDeckAdd(" .. deck["name"] .. ")",
            fontSize=12,
            height = 20, width = 20,
            textColor="#000000",
            rectAlignment="MiddleRight",
          },
          "+"
        ),
      })
    })
  end

  return XML("GridLayout", {
    spacing = "20 20",
    cellSize = "200 80",
    startCorner = "UpperLeft",
    rectAlignment = "MiddleCenter",
  }, ret)
end

function getTooltipDescription(text)
  -- text is usually from a multiline heredoc, such as:
  -- [[
  --   Start every player with two random copies of cards of cost 1 taken from
  --   the deck. (They aren't removed from the deck. Frequency in deck applies to
  --   chance of it being used)
  -- ]]
  --
  -- This looks a little awkward in two ways:
  -- 1) The leading newline is stripped
  -- 2) The first whitespace in each line isn't.
  -- 3) last newline isn't.
  --
  -- So this is a crummy workaround to make the tooltips look nicer.
  local edited = text:gsub("\n", "    \n")
  return ("\n" .. edited)
end

function createXMLChoiceInputFor(def)
  local id = def["id"]
  local gameopts = MENU_CHOICES["gameopts"] or {}
  local val = gameopts[id] or def["default"]

  local attrs = def["attrs"]
  attrs["id"] = id
  attrs["onValueChanged"] = "menuEnterChoice"

  local opt
  if def["valattr"] then
    attrs[def.valattr] = tostring(val)
    opt = XML(def["type"], attrs, false)
  else
    opt = XML(def["type"], attrs, tostring(val))
  end

  if def["label"] then
    return XML("HorizontalLayout", {
        childForceExpandWidth = false,
        childForceExpandHeight = false,
        childAlignment = "MiddleLeft",
        spacing = 8,
      }, {
        opt,
        XML("Text", {
          fontSize = 16,
        }, def["label"]),
      }
    )
  else
    return opt
  end
end

function menuEnterChoice(player, val, attrid)
  if not IS_MENU_OPEN then return end
  if not (PDATA["rulesopts"] and PDATA["rulesopts"][attrid]) then
    broadcastToAll("NO dice")
    return
  end
  local def = PDATA["rulesopts"][attrid]
  if not def then return end
  local convert = tostring
  if def["convert"] then convert = def["convert"] end
  if not MENU_CHOICES["gameopts"] then
    MENU_CHOICES["gameopts"] = {}
  end
  MENU_CHOICES["gameopts"][attrid] = convert(val)
  checkRules()
end

function uiBool(val)
  return val == "True"
end

function createXMLHouseRuleChoice(idx, rules)
  local attrs = {
    onValueChanged="menuToggle",
    id="hr." .. tostring(idx),
    tooltip=getTooltipDescription(rules["description"]),
    tooltipBackgroundColor="rgba(0,0,0,1)",
    tooltipPosition = "Below",
    rectAlignment = "UpperLeft",
    alignment = "UpperLeft",
    childAlignment = "UpperLeft",
    tooltipOffset = 0.0,
    fontSize = 16,
  }
  if MENU_CHOICES["houserules"][rules["name"]] then
    attrs.isOn = "True"
  else
    attrs.isOn = "False"
  end
  local toggle = XML("Toggle", attrs, rules["name"])

  local choices = {toggle}
  if rules["choices"] and #rules["choices"] > 0 then
    if rules.choiceLayout then
      local kids = {}
      for _, def in ipairs(rules["choices"]) do
        table.insert(kids, createXMLChoiceInputFor(def))
      end
      table.insert(choices, XML(rules.choiceLayout, rules.choiceAttrs, kids))
    else
      for _, def in ipairs(rules["choices"]) do
        table.insert(choices, createXMLChoiceInputFor(def))
      end
    end
  end
  return XML("VerticalLayout", {
      spacing = 10,
      rectAlignment = "UpperLeft",
      childAlignment = "UpperLeft",
      childForceExpandHeight=false
    }, choices)
end

function createXMLHouseRules(isgamemode)
  -- HOUSE_RULES = {...}
  local rules_xml = {}
  for idx, rules in ipairs(HOUSE_RULES) do
    if rules["isGameMode"] == isgamemode and rules["name"] ~= nil then
      table.insert(rules_xml, createXMLHouseRuleChoice(idx, rules))
    end
  end
  return XML("GridLayout", {
    spacing = "20 20",
    cellSize = "200 80",
    startCorner = "UpperLeft",
    rectAlignment = "UpperLeft",
    alignment = "UpperLeft",
    childAlignment = "UpperLeft",
  }, rules_xml)
end

function hideMenu()
  IS_MENU_OPEN = false
  hideUI("rulesMenu")
end

function populateMenu()
  -- Populate the Menu choices
  local decks = MENU_CHOICES["decks"]
  for deckname, count in pairs(decks) do
    UI.setAttribute(deckname .. ".count", "text", tostring(count))
  end

  for idx, rules in ipairs(HOUSE_RULES) do
    if MENU_CHOICES["houserules"][rules["name"]] then
      UI.setAttribute("hr." .. tostring(idx), "isOn", "True")
    else
      UI.setAttribute("hr." .. tostring(idx), "isOn", "False")
    end
  end

  checkRules()
end

function createMenuStartButton()
  return XML("Button", {
    onclick="menuStart",
    rectAlignment="LowerCenter",
    alignment="MiddleCenter",
    minHeight=100,
    height=100,
    width="100%",
    ignoreLayout=true,
    color="#AA0000",
  }, {XML("Text", {fontsize=40, color="white", id="menuStart"}, "Let's Play!")})
end

function menuToggle(player, val, attrid)
  if not IS_MENU_OPEN then return end
  if attrid:sub(1,7) == "toggle." then
    MENU_CHOICES[attrid:sub(8, #attrid)] = (val == "True")
  elseif attrid:sub(1,3) == "hr." then
    local ruleid = tonumber(attrid:sub(4,#attrid), 10)
    local rules = HOUSE_RULES[ruleid]
    if not rules then return die("Picked invalid rules? (%s)", tostring(ruleid)) end
    if rules.isGameMode and val == "True" then
      pickHouseGameMode(rules)
    else
      pickHouseRule(rules, val == "True")
    end
  else
    whine("menuToggle for %s?", attrid)
    return
  end
  populateMenu()
end

function createXMLRulesMenu()
  -- Called when game is unready, it is used to define the rules for the
  -- new game.
  local menu = XML("Panel", {
      id = "rulesMenu",
      active = false,
      padding = 20,
      width = "900", height = "800",
      color = "#f0ead6",
      allowDragging = true, returnToOriginalPositionWhenReleased = false,
    }, {
      XML("VerticalLayout",
        {
          minWidth = 850,
          width = 850,
          rectAlignment = "UpperCenter",
          childAlignment = "UpperCenter",
          childForceExpandHeight=false
        }, {
          -- Title
          XML("Text", {
            color="#990000",
            alignment="UpperCenter",
            rectAlignment="UpperCenter",
            fontSize = "30",
            width="95%",
            minHeight=60,
          }, "<b>Star Realms (Scripted attempt)</b>"),

          -- Deck selections
          createXMLDeckSelections(),

          -- Multiplayer and House Rules.
          XML("Text", {
            color="#990000",
            alignment="LeftCenter",
            rectAlignment="MiddleLeft",
            fontSize = "24",
            width="95%",
            minHeight=30,
          }, "<b>Game Mode:</b>"),

          XML("ToggleGroup", {
              minHeight = 40,
            },
            createXMLHouseRules(true)
          ),

          XML("Text", {
            color="#990000",
            alignment="LeftCenter",
            rectAlignment="MiddleLeft",
            fontSize = "24",
            width="95%",
            minHeight=30,
          }, "<b>Game Rules:</b>"),
          createXMLHouseRules(false),
        }
      ),
      createMenuStartButton(),
      XML("Button",
        {
          onClick="hideMenu",
          rectAlignment="UpperRight",
          width=35, height=35,
          ignoreLayout=true,
          fontSize="24",
        }, "X"),
      }
    )

  local defaults = XML("Defaults", {
    XML("Text", {
      class="dname",
      resizeTextForBestFit="false",
      color="#000000",
      alignment="UpperCenter",
      fontSize=18,
    }, false),
  })

  UI.setXmlTable({defaults, menu})
end

function setMenuFailReason(text, ...)
  local msg = text:format(...)
  UI.setAttribute("menuStart", "text", msg)
end

function clickCleanup(obj, playercol, _)
  cleanupGame()
end

function clickStart(obj, playercol, _)
  showUI("rulesMenu")
  populateMenu()
  -- Don't allow adjustments during show. ToggleGroup
  -- overrides everything it can.
  greenWait({
    frames = 10,
    callback = function() IS_MENU_OPEN = true end,
  })
end

function ignoreInput(_obj, _playercol, _)
end


