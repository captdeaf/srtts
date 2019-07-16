function getSeatedPlayers()
  if MENU_CHOICES["fakeplayers"] then
    return {White, Brown, Yellow, Purple, Red, Green, Teal, Orange}
  end
  local cols = {}
  for _, player in ipairs(Player.getPlayers()) do
    if PLAYER_ZONE[player.color] then
      table.insert(cols, player.color)
    end
  end
  return cols
end

function getTeamOrderClockwise(teams)
  local teammap = {}
  for _, team in ipairs(teams) do
    for col, _ in pairs(team["colors"]) do
      teammap[col] = team["name"]
    end
  end
  local done = {}

  local clockwise_order = {
    "Yellow", "Green", "Teal", "Purple",
    "Orange", "Brown", "White", "Red",
  }

  local start_idx = math.random(1, #clockwise_order)

  local order = {}
  for idx=0,7,1 do
    local col = clockwise_order[((start_idx+idx)%8)+1]
    local teamname = teammap[col]
    if teamname and not done[teamname] then
      table.insert(order, teamname)
      done[teamname] = true
    end
  end
  return order
end

function setupTeams(teaminfo)
  local tts_teams = {"Clubs", "Diamonds", "Hearts", "Spades", "Jokers"}
  -- Create default gamestate and player information.
  -- teaminfo is a list, GAMESTATE["teams"] a map.
  GAMESTATE["teams"] = {}
  for _, team in ipairs(teaminfo) do
    if howMany(team["colors"]) > 1 then
      local ttsteam = table.remove(tts_teams, 1)
      for color in pairs(team["colors"]) do
        Player[color].team = ttsteam
      end
    end
    GAMESTATE["teams"][team["name"]] = team
  end
  GAMESTATE["order"] = getHouseRule("getTurnOrder", teaminfo)

  for _, team in pairs(GAMESTATE["teams"]) do
    createTeamAuthToken(team)
  end
end

function getTeamOf(teamorcolor)
  if GAMESTATE["teams"][teamorcolor] then
    return teamorcolor
  else
    return GAMESTATE["players"][teamorcolor]["team"]
  end
end

function getOpponentBases(team)
  local allenemybases = {}
  for col, _ in pairs(getOpponents(team)) do
    local existing = getBasesInPlay(col)

    if existing and #existing > 0 then
      for _, base in ipairs(existing) do
        allenemybases[#allenemybases+1] = base
      end
    end
  end

  return allenemybases
end

function isLivePlayer(color)
  if GAMESTATE["order"] and #GAMESTATE["order"] > 0 then
    for _, team in ipairs(GAMESTATE["order"]) do
      local teamp = getTeamPlayers(team)
      if teamp[color] then return true end
    end
  end
  return false
end

function teamOf(color)
  return color
end

function playerName(color)
  if PLAYER_ZONE[color] and Player[color] and Player[color].seated then
    return Player[color].steam_name
  end
  local fakeNames = {
    -- top
    Yellow = "Senator Banana",
    Green = "Doctor Lime",
    Teal = "Dame Tealy",
    Purple = "Professor Grape",
    -- bottom
    Red = "Boy Blush",
    White = "Boo D. Ghost",
    Brown = "Mr. Hanky",
    Orange = "Officer T. Cone",
  }
  return fakeNames[color] or color
end

function teamName(teamname)
  -- Most common: teamname is a color.
  if PLAYER_ZONE[teamname] then return playerName(teamname) end

  -- Otherwise: teamname is really just a placeholder for "X and X"
  local teammap = GAMESTATE["teams"]
  if not teammap[teamname] then
    whine("teamName called for non-team? %s?", tostring(teamname))
    return playerName(teamname)
  end

  local pnames = {}
  for color in pairs(getTeamPlayers(teamname)) do
    table.insert(pnames, playerName(color))
  end
  if #pnames == 1 then return pnames[1] end
  return concatAnd(pnames, "and")
end

function allSeatedColors()
  return pairs(GAMESTATE["players"])
end

function isPlaying(color)
  local inteam = getCurrentPlayers()
  return inteam[color]
end

function getTeamPlayers(team)
  return GAMESTATE["teams"][team]["colors"]
end

function getCurrentPlayers()
  return getTeamPlayers(GAMESTATE["playing"])
end

