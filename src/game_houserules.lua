--[[
HouseRules have attributes called when:

(All "players" are lists of colors)

By default, teamnames are == colors.

isGameMode = true/false: Only one GameMode can be selected.
           (2h Hydra, 3h Hydra, Emperor, Hunter, ...)

Roughly in order of occurence:

(the check* and get*() functions are all unique. Any conflicts results in
 non-starting game)

canStart(): if game can be started with this house rule.
       If the game can start, return true. If it can't, any string returned
       is displayed in the UI.

getTeams(colors): return {{name, {player,player}, position, authority}, ...}
    This is used to create the Authority counters, e.g: for 2 v 2 Hydra,
    it could be: {{"Angry Hydra", {"White", "Brown"}, {x=0, y=5, z=-20}, 70},
                  {"Happy Hydra", {"Teal", "Green"},  {x=0, y=5, z= 20}, 70}}

getOpponents(team): return table of {enemyteam: true, ...}. Defaults to
    all teams other than current team.

getTargetOpponents(team): Defaults to getOpponents - returns a list of
    players who are valid targets for "target opponent" (e.g: "target
    opponent discards a card").

getTargets(team): Return a table of targets. Defaults to getOpponents()
    and their bases.

getTurnOrder(players): return colors and/or team names.

getStartHandSizes(players):
    return a number: All get same #
    return an array: first player gets 1st, second 2nd, and so on.
    return a map[color]=#: Be more specific.

getHandSize(player): return 5. Or 7 if player is Boss, etc.


-- Multiple house rules can use:

onSetup(Before setup, this can be used to alter individual hands
    players' hands, the trade deck, etc.

onReady(After the cards are all dealt and shuffled.

onTurnStart(teamname) ... self explanatory.
onTurnEnd(teamname)

--- Others will be added as needed.

]]--

DEFAULT_MODE_NAME = "Free for All"

function buildHouseRules()
  -- This is a function only so that the house rules below can reference
  -- functions that aren't defined yet.
  HOUSE_RULES = {}

  --------
  -- TWO HEADED HYDRA
  --------
  table.insert(HOUSE_RULES, {
    isGameMode = true,
    name = DEFAULT_MODE_NAME,
    description = [[
      Default Star Realms rules: Free for All.
    ]],
  })
  table.insert(HOUSE_RULES, {
    isGameMode = true,
    name = "Two Headed Hydra",
    description = [[
      You're all Ettins - shared health, separate playbases. Can you conquer
      the galaxy without losing your sanity at your friend? Requires an even
      number of players, teammates must be in adjacent seats.
      Shared trade+combat pool, shared health (default 75).
      Separate play fields+ships+allies.
      (White+Brown, Green+Teal for 4-players) (R+W, Br+O, Y+G, T+Bl as teams 3-4).
    ]],
    canStart = function()
      local thg = {}
      GAMESTATE["houserules"]["2hg"] = thg
      thg["pairs"] = {}
      local seated = {}
      for _, col in ipairs(getSeatedPlayers()) do
        seated[col] = true
      end
      local teams = {}
      local pairings = {
        {Red, White}, {Yellow, Green}, {Purple, Teal}, {Orange, Brown},
        {White, Brown}, {Green, Teal},
      }
      for _, pair in ipairs(pairings) do
        if seated[pair[1]] then
          if not seated[pair[2]] then
            return sprintf("%s must be partnered with %s", pair[1], pair[2])
          else
            table.insert(teams, pair)
            seated[pair[1]] = false
            seated[pair[2]] = false
          end
        end
      end
      if #teams < 2 then
        return "Did Brave Sir Robin already run away?"
      end
      thg["pairs"] = teams
      return true
    end,
    getTeams = function(colors)
      -- By default, teams are individuals.
      local thg = GAMESTATE["houserules"]["2hg"]
      local teamnames = {
        "Hydra", "Ettin", "Scylla", "Orthrus", "Cerberus", "Ladon",
        "Agni", "Dattatreya", "Kartikeya", "Janus", "Nehebkau",
        "Balaur", "Kucedra", "Svantevit", "Yamata no Orochi",
      }
      shuffle(teamnames)
      local teamsdata = {}
      for _, pair in ipairs(thg["pairs"]) do
        local name = table.remove(teamnames, 1)
        local auth = getHouseRule("getStartingAuthority", name, 75)
        table.insert(teamsdata, {
          name = name,
          colors = {[pair[1]] = true, [pair[2]] = true},
          authcolor = PLAYER_BG_COLOR[pair[1]],
          position = vecAvg({PDATA[pair[1]]["authloc"], PDATA[pair[2]]["authloc"]}),
          rotation = PDATA[pair[1]]["rot"],
          authority = auth,
        })
      end
      return teamsdata
    end,
  })

  --------
  -- HUNTER
  --------
  table.insert(HOUSE_RULES, {
    isGameMode = true,
    name = "Hunter",
    description = [[
      Star Realms' Hunter rules apply. You can only attack bases of the players
      on either side of you, and you can only damage the player on your left.
    ]],
    getOpponents = function(myteam)
      -- GAMESTATE.order is clockwise. team, as current player, is guaranteed
      -- to be order[#order]

      -- "Opponents" are only to your left and right.
      local opponents = {}
      local order = GAMESTATE["order"]
      for i=1,#order,1 do
        if order[i] == myteam then
          local right = order[(#order + i - 1) % #order]
          local left = order[(i + 1) % #order]
          opponents[right] = true
          opponents[left] = true
          return opponents
        end
      end
    end,
    getTargetOpponents = function(myteam)
      -- Unlike getOpponents, we only return the player on the left.
      local opponents = {}
      local order = GAMESTATE["order"]
      for i=1,#order,1 do
        if order[i] == myteam then
          local left = order[(i + 1) % #order]
          opponents[left] = true
          return opponents
        end
      end
    end,
    getTargets = function(myteam)
      -- Player on left is valid, player on right is not, but
      -- bases and outposts of either are valid.
      local order = GAMESTATE["order"]
      for i=1,#order,1 do
        if order[i] == myteam then
          local right = order[(#order + i - 1) % #order]
          local left = order[(i + 1) % #order]

          local alltargs = {}
          table.insert(alltargs, getTargetables(left, true))
          table.insert(alltargs, getTargetables(right, false))

          return mergeTables(alltargs)
        end
      end
    end
  })

  --------
  -- Dumb AI
  --------
  local aibutt = function(color)
    return {
      id = "fake" .. color,
      type = "Toggle",
      attrs = {
        colors = sprintf("%s|%s|%s", color, color, color),
      },
      valattr = "isOn",
      convert = uiBool,
      tooltipText = color,
    }
  end
  local player_cols = {Yellow, Green, Teal, Purple, Red, White, Brown, Orange}
  table.insert(HOUSE_RULES, {
    isGameMode = false,
    name = "Dumb AI Players",
    description = [[
      Dumb AI players. Really, really, really dumb. If you lose to them, I
      feel bad for you. Like, so dumb. Select which seats you want faked and
      under control of the dumb AI.
    ]],
    choiceLayout = "GridLayout",
    choiceAttrs = {
      spacing = "5 5",
      cellSize = "40 20",
      startCorner = "UpperLeft",
    },
    choices = mapList(player_cols, aibutt),
    getPlayers = function(colors)
      local isplaying = {}
      for _, color in ipairs(colors) do
        isplaying[color] = true
      end
      local opts = MENU_CHOICES["gameopts"] or {}
      for _, color in ipairs(player_cols) do
        if opts["fake" .. color] then
          if not isplaying[color] then
            table.insert(colors, color)
          end
        end
      end
      return colors
    end,
    onSetup = function()
      GAMESTATE["ais"] = {}
      local opts = MENU_CHOICES["gameopts"] or {}
      for _, color in ipairs(player_cols) do
        if opts["fake" .. color] then
          GAMESTATE["ais"][color] = true
        end
      end
    end,
  })

  --------
  -- FRINGE SKIRMISH
  --------
  table.insert(HOUSE_RULES, {
    isGameMode = false,
    name = "Fringe Skirmish",
    description = [[
      Out on the fringe, few ships and stations are available. This house rule
      removes all cards that cost more than 4 from the trade deck.
    ]],
    onSetup = function()
      local cheapcards = {}
      for idx, cardname in ipairs(GAMESTATE["tradedeck"]) do
        if ALL_CARDS[cardname]["cost"] <= 4 then
          cheapcards[#cheapcards+1] = cardname
        end
      end
      GAMESTATE["tradedeck"] = cheapcards
    end,
  })

  --------
  -- Respect mah Authoritay
  --------
  table.insert(HOUSE_RULES, {
    isGameMode = false,
    name = "Respect mah Authoritay",
    description = [[
      Start the game with something other than the default (50) authority.
    ]],
    canStart = function()
      local auth = ((MENU_CHOICES["gameopts"] or {})["authority"]) or 50
      if auth < 1 then return "Game starts, you all die immediately. Yay?" end
      if auth > 999 then return "Why not just go infinite health?" end
      return true
    end,
    getStartingAuthority = function(color, default)
      return ((MENU_CHOICES["gameopts"] or {})["authority"]) or 50
    end,
    choices = {
      {
        id = "authority",
        type = "InputField",
        convert = tonumber,
        default = 50,
        attrs = {
          characterLimit = 4,
          minWidth = 70,
          maxWidth = 70,
          minHeight = 36,
          fontSize = 20,
          characterValidation = "Integer",
          text = "50",
        },
        label = "Authority (1-999)"
      }
    },
  })

  --------
  -- Custom Start Cards
  --------

  table.insert(HOUSE_RULES, {
    isGameMode = false,
    name = "Custom Start Cards",
    description = [[
      Start the game with something other than the 8 scouts + 2 vipers.
      Really, this is just here so I can more easily debug when things
      go wrong. Comma-separated list of card names. Case- and space- insensitive,
      so "Death World,Brain World" will work as well as "deathworld,brainworld".
      It is also |-separated: hand|deck|inplay|discard. So "||Brain World" starts
      everybody with a Brain World in play.
    ]],
    choices = {
      {
        id = "customstart",
        type = "InputField",
        default = "",
        attrs = {
          characterLimit = 600,
          minHeight = 50,
          fontSize = 9,
          lineType = "MultiLineNewLine",
          placeholder = "Card In Hand|Card in Deck|Base in Play|Card in Discard",
        },
      },
    },
    canStart = function()
      local opts = (MENU_CHOICES["gameopts"] or {})
      local ccards = {}
      GAMESTATE["houserules"]["customcards"] = ccards
      if not opts.customstart then return end
      local st = opts.customstart
      local res = {}
      st = st:gsub("|", " | ")
      for str in st:gmatch("[^|]+") do
        table.insert(res, str)
      end
      local hand, deck, inplay, discard = unpack(res)
      local nametypes = {
        {"starthand", hand, {}},
        {"startdeck", deck, {}},
        {"startdiscard", discard, {}},
        {"startbases", inplay, {OUTPOST, BASE, HERO}},
      }
      local good = true
      for _, nts in ipairs(nametypes) do
        local key, val, _ = unpack(nts)
        if val and val ~= "" then
          local isgood, rets = convertCustomCardnames(val)
          good = good and isgood
          ccards[key] = rets
        end
      end
      if good then return true end
      return "invalid card names?"
    end,
    onSetup = function()
      local ccards = GAMESTATE["houserules"]["customcards"]
      for color, info in pairs(GAMESTATE["players"]) do
        mergeTables({info, ccards})
      end
    end,
  })

  --------
  -- Scavenger's Luck
  --------
  table.insert(HOUSE_RULES, {
    isGameMode = false,
    name = "Scavenger's Luck",
    description = [[
      Start every player with two random copies of cards of cost 1 taken from
      the deck. (They aren't removed from the deck. Frequency in deck applies to
      chance of it being used)
    ]],
    onSetup = function()
      local cheapcards = {}
      for idx, cardname in ipairs(GAMESTATE["tradedeck"]) do
        if ALL_CARDS[cardname]["cost"] == 1 then
          cheapcards[#cheapcards+1] = cardname
        end
      end
      for color, info in pairs(GAMESTATE["players"]) do
        table.insert(info["startdeck"], cheapcards[math.random(#cheapcards)])
        table.insert(info["startdeck"], cheapcards[math.random(#cheapcards)])
      end
    end,
  })

  --------
  -- Jump Start
  --------
  table.insert(HOUSE_RULES, {
    isGameMode = false,
    name = "Jump Start",
    description = [[
      No scouts or vipers, just explorers in your deck.
    ]],
    onSetup = function()
      for color, info in pairs(GAMESTATE["players"]) do
        local deck = info["startdeck"]
        for idx, cardname in ipairs(deck) do
          if cardname == "Scout" or cardname == "Viper" then
            deck[idx] = "Explorer"
          end
        end
      end
    end,
  })

  --------
  -- Fast Economy
  --------
  table.insert(HOUSE_RULES, {
    isGameMode = false,
    name = "Fast Economy",
    description = [[
      The economy moves fast, you better buy what you can while you
      can! At the end of every turn, the trade row will shift one
      card to the left, removing the leftmost card and adding a new
      card to the right.
    ]],
    onTurnEnd = function(_)
      local tradecards = GAMESTATE["tradecards"]
      local toscrapguid = table.remove(tradecards, 1)
      local toscrap = getObjectFromGUID(toscrapguid)
      local tcs = guidsToObjects(tradecards)
      local tsname = toscrap.getName()

      destroyCard(toscrap)
      for i=1,#tcs,1 do
        moveThen(tcs[i], PDATA["tradepos"][i])
      end
      announceGame("Fast Economy: trade row shifted, %s lost", tsname)
      dealToTrade(5, getTradeDeck())
    end,
  })

  --------
  -- Unstable Economy
  --------
  table.insert(HOUSE_RULES, {
    isGameMode = false,
    name = "Unstable Economy",
    description = [[
      The galactic economy is run by stable geniuses. Ergo, there is
      massive and unpredictable turnover in the market. At the end
      of every turn, some of the trade cards may be replaced.
      The more expensive a trade card is, the more likely it is to
      get replaced.
    ]],
    onTurnEnd = function(_)
      local tradecards = GAMESTATE["tradecards"]
      local tcs = guidsToObjects(tradecards)
      local td = getTradeDeck()

      for i=1,#tcs,1 do
        local card = ALL_CARDS[tcs[i].getName()]
        if math.random(card.cost + 7) <= card.cost then
          announceGame("Unstable Economy: %s removed from trade row", card.name)
          destroyCard(tcs[i])
          dealToTrade(i, td)
        end
      end
      waitUntilSettled()
    end,
  })

  --------
  -- Scout's Duty
  --------
  table.insert(HOUSE_RULES, {
    isGameMode = false,
    name = "Scout's Duty",
    description = [[
      In multiplayer games, first player (and sometimes second) player have
      fewer cards. This toggle ensures they have at least 3 non-vipers.
      (e.g: 2nd player in 3+, drawing 4, will have 1 viper at most)
    ]],
    getFirstHand = function(cards, handsize)
      -- Default: shuffle+size, but we want no vipers in first hand.
      if handsize > 4 then
        return shuffleAndDraw(cards, handsize)
      end
      local vipercount = handsize - 3
      local butvipers = {}
      local vipers = {}
      for _, card in ipairs(cards) do
        if card == "Viper" then
          if vipercount > 0 then
            table.insert(butvipers, card)
            vipercount = vipercount - 1
          else
            table.insert(vipers, card)
          end
        else
          table.insert(butvipers, card)
        end
      end
      local hand = {unpack(butvipers, 1, handsize)}
      local rest = {unpack(butvipers, handsize+1, #butvipers)}
      for _, v in ipairs(vipers) do
        table.insert(rest, v)
      end
      shuffle(rest)
      return hand, rest
    end,
  })

  --------
  -- DEFAULT RULES - THIS MUST BE LAST.
  --------
  table.insert(HOUSE_RULES, {
    -- Has no name, this is the "default" settings for anything that
    -- requires exactly one (e.g: )
    onSetup = function()
      GAMESTATE["houserules"]["default"] = {}
      local st = GAMESTATE["houserules"]["default"]

      if #GAMESTATE["order"] > 2 then
        st["hands"] = {3,4}
      else
        st["hands"] = {3}
      end
    end,
    getHandSize = function(team)
      local st = GAMESTATE["houserules"]["default"]
      if #st["hands"] == 0 then return 5 end
      return table.remove(st["hands"], 1)
    end,
    getFirstHand = shuffleAndDraw,
    getTurnOrder = getTeamOrderClockwise,
    getStartingAuthority = function(color, default)
      return default
    end,
    getPlayers = function(colors)
      return colors
    end,
    getTeams = function(colors)
      -- By default, teams are individuals.
      local teams = {}
      for _, col in ipairs(colors) do
        local auth = getHouseRule("getStartingAuthority", col, 50)
        table.insert(teams, {
          name = col,
          colors = {[col] = true},
          authcolor = PLAYER_BG_COLOR[col],
          position = PDATA[col]["authloc"],
          rotation = PDATA[col]["rot"],
          authority = auth,
        })
      end
      return teams
    end,
    getOpponents = function(myteam)
      local opponents = {}
      for enemyteam, enemytd in pairs(GAMESTATE["teams"]) do
        if enemytd["name"] ~= myteam and enemytd["authority"] > 0 then
          opponents[enemyteam] = true
        end
      end
      return opponents
    end,
    getTargetOpponents = function(myteam)
      return getHouseRule("getOpponents", myteam)
    end,
    getTargets = function(team)
      local alltargs = {}
      for enemyteam, _ in pairs(getOpponents(team)) do
        table.insert(alltargs, getTargetables(enemyteam, true))
      end

      return mergeTables(alltargs)
    end
  })
  -- DO NOT ADD MORE HOUSE RULES AFTER HERE. THIS MUST BE LAST.

  PDATA["rulesopts"] = {}
  for _, rules in ipairs(HOUSE_RULES) do
    if rules["choices"] and #rules["choices"] > 0 then
      for _, choice in ipairs(rules["choices"]) do
        PDATA["rulesopts"][choice["id"]] = choice
      end
    end
  end
end

function mapHouseRules()
  -- We iterate through HOUSE_RULES in order, so we apply them
  -- safely in order, I hope.
  PDATA["rules"] = {}
  for _, rules in ipairs(HOUSE_RULES) do
    -- default (nameless) is always included.
    if (rules["name"] == nil) or MENU_CHOICES["houserules"][rules["name"]] == true then
      table.insert(PDATA["rules"], rules)
    end
  end
end

function pickHouseGameMode(moderules)
  local hrs = MENU_CHOICES["houserules"]
  for _, rules in ipairs(HOUSE_RULES) do
    if rules.isGameMode then
      hrs[rules.name] = nil
    end
  end

  hrs[moderules.name] = true
end

function pickHouseRule(rules, selected)
  local hrs = MENU_CHOICES["houserules"]

  if selected then
    hrs[rules.name] = true
  else
    hrs[rules.name] = nil
  end
end

function getHouseRule(funcname, ...)
  -- This requires unique versions.
  for _, rules in ipairs(PDATA["rules"]) do
    if rules[funcname] and type(rules[funcname]) == "function" then
      return rules[funcname](...)
    end
  end
  return nil
end

function callHouseRules(funcname, ...)
  local ret = {}
  for _, rules in ipairs(PDATA["rules"]) do
    if rules[funcname] and type(rules[funcname]) == "function" then
      table.insert(ret, rules[funcname](...))
    end
  end
  return ret
end

function shuffleAndDraw(cards, handsize)
  shuffle(cards)
  local hand = {unpack(cards, 1, handsize)}
  local deck = {unpack(cards, handsize+1, #cards)}
  return hand, deck
end

function checkRules()
  if GAMESTATE["state"] ~= UNREADY then
    die("checkRules when not in unready state?")
    return false
  end

  GAMESTATE["canstart"] = false

  local has_full_set = false
  for _, v in ipairs(AVAILABLE_DECKS) do
    if (MENU_CHOICES["decks"][v.name] or 0) > 1 then
      has_full_set = true
    end
  end
  -- {name = "Core", count = 1, fullset=true},
  if not has_full_set then
    setMenuFailReason("A full set (Core, Colony Wars, or Frontier) must be present, or you won't have enough cards!")
    return false
  end

  mapHouseRules()

  local seatedcolors = getSeatedPlayers()
  local colors = getHouseRule("getPlayers", seatedcolors)

  if #colors < 2 then
    setMenuFailReason("Not enough players!")
    return false
  end

  local decks = {}
  for deckname, count in pairs(MENU_CHOICES["decks"]) do
    if count > 0 then
      for i = 1,count,1 do
        table.insert(decks, deckname)
      end
    end
  end
  GAMESTATE["decks"] = decks

  local rets = callHouseRules("canStart")
  for _, val in ipairs(rets) do
    if val ~= nil and val ~= true then
      setMenuFailReason(tostring(val))
      return false
    end
  end

  GAMESTATE["canstart"] = true
  setMenuFailReason("Play Star Realms!")

  return true
end

function getTargetables(enemyteam, includeteam)
  -- Get all targetables from enemy team, in the form of a table:
  -- {
  --   [teamname] = true, -- if no outposts
  --   [guid1] = 4 -- 4-defense base or outpost.
  --   [guid2] = 8 ... etc.
  -- }
  if includeteam == nil then includeteam = true end
  local teamtargets = {}
  local numoutposts = 0
  for col, _ in pairs(getTeamPlayers(enemyteam)) do
    local outposts = {}
    local bases = {}
    local existing = getBasesInPlay(col)

    if existing and #existing > 0 then
      for _, base in ipairs(existing) do
        local card = ALL_CARDS[base.getName()]
        if card then
          if card["type"] == OUTPOST then
            outposts[#outposts+1] = {base, card["effects"]["def"]}
          elseif card["type"] == BASE then
            bases[#bases+1] = {base, card["effects"]["def"]}
          end
        end
      end
    end
    if #outposts > 0 then
      numoutposts = numoutposts + #outposts
      for _, based in ipairs(outposts) do
        teamtargets[based[1].getGUID()] = based[2]
      end
    else
      if #bases > 0 then
        for _, based in ipairs(bases) do
          teamtargets[based[1].getGUID()] = based[2]
        end
      end
    end
  end

  -- All players on a team are only targetable if none of them have outposts.
  if includeteam and numoutposts < 1 then
    teamtargets[enemyteam] = true
  end
  return teamtargets
end

function getTargetOpponents(teamorcolor)
  local myteam = getTeamOf(teamorcolor)
  return getHouseRule("getTargetOpponents", myteam)
end

function getOpponents(teamorcolor)
  local myteam = getTeamOf(teamorcolor)
  return getHouseRule("getOpponents", myteam)
end

