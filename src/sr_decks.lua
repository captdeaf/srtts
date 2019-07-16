AVAILABLE_DECKS = {
  {name = "Core", count = 1},
  {name = "Colony Wars", count = 0},
  {name = "Year 1 Promos", count = 0},
  {name = "Bases & Battleships", count = 0},
  {name = "Heroes", count = 0},
  {name = "Fleets & Fortresses", count = 0},
  {name = "Command", count = 0},
  {name = "United: Heroes", count = 0},
  {name = "Assault", count = 0},
}

DECKS = {}

DECKS["STARTDECK"] = {
  "Scout", "Scout", "Scout", "Scout", "Scout", "Scout", "Scout", "Scout",
  "Viper", "Viper",
}

DECKS["Core"] = {
  -- Star Empire
  "Imperial Fighter", "Imperial Fighter", "Imperial Fighter", "Corvette",
  "Corvette", "Imperial Frigate", "Imperial Frigate", "Imperial Frigate",
  "Survey Ship", "Survey Ship", "Survey Ship", "Battlecruiser", "Dreadnaught",
  "Recycling Station", "Recycling Station", "Space Station", "Space Station",
  "War World", "Royal Redoubt", "Fleet HQ",

  -- Trade Fed
  "Federation Shuttle", "Federation Shuttle", "Federation Shuttle", "Cutter",
  "Cutter", "Cutter", "Embassy Yacht", "Embassy Yacht", "Freighter",
  "Freighter", "Trade Escort", "Flagship", "Command Ship", "Trading Post",
  "Trading Post", "Barter World", "Barter World", "Defense Center",
  "Port of Call", "Central Office",

  -- Blob
  "Blob Fighter", "Blob Fighter", "Blob Fighter", "Battle Pod", "Battle Pod",
  "Trade Pod", "Trade Pod", "Trade Pod", "Ram", "Ram", "Blob Destroyer",
  "Battle Blob", "Blob Carrier", "Blob Mothership", "Blob Wheel", "Blob Wheel",
  "Blob Wheel", "The Hive", "Blob World",

  -- Machine Cult
  "Trade Bot", "Trade Bot", "Trade Bot", "Missile Bot", "Missile Bot",
  "Missile Bot", "Supply Bot", "Supply Bot", "Supply Bot", "Patrol Mech",
  "Patrol Mech", "Stealth Needle", "Battle Mech", "Missile Mech",
   "Battle Station", "Mech World", "Junkyard", "Machine Base", "Brain World",
}

DECKS["Colony Wars"] = {
  -- Star Empire
  "Star Barge", "Star Barge", "Star Barge", "Lancer", "Lancer", "Lancer",
  "Orbital Platform", "Orbital Platform", "Orbital Platform", "Falcon",
  "Falcon", "Gunship", "Supply Depot", "Command Center", "Command Center",
  "Heavy Cruiser", "Aging Battleship", "Imperial Palace",
  "Emperor's Dreadnaught",

  -- Trade Federation
  "Solar Skiff", "Solar Skiff", "Solar Skiff", "Trade Hauler", "Trade Hauler",
  "Trade Hauler", "Storage Silo", "Storage Silo", "Patrol Cutter",
  "Patrol Cutter", "Patrol Cutter", "Frontier Ferry", "Frontier Ferry",
  "Central Station", "Central Station", "Colony Seed Ship", "Peace Keeper",
  "Federation Shipyard", "Loyal Colony", "Factory World",

  -- Blob
  "Swarmer", "Swarmer", "Swarmer", "Stellar Reef", "Stellar Reef",
  "Stellar Reef", "Predator", "Predator", "Predator", "Cargo Pod", "Cargo Pod",
  "Cargo Pod", "Ravager", "Ravager", "Bioformer", "Bioformer", "Parasite",
  "Plasma Vent", "Moonwurm", "Leviathan",

  -- Machine Cult
  "Battle Bot", "Battle Bot", "Battle Bot", "Warning Beacon", "Warning Beacon",
  "Warning Beacon", "Repair Bot", "Repair Bot", "Repair Bot", "Convoy Bot",
  "Convoy Bot", "Convoy Bot", "The Oracle", "Mining Mech", "Mining Mech",
  "Stealth Tower", "Mech Cruiser", "Frontier Station", "The Wrecker",
  "The Incinerator",
}

DECKS["Year 1 Promos"] = {
  "Fortress Oblivion", "Fortress Oblivion", "Merc Cruiser", "Merc Cruiser",
  "Merc Cruiser", "Battle Barge", "Battle Barge", "Battle Screecher",
  "Battle Screecher", "Breeding Site", "Starbase Omega", "Starmarket",
  "Starmarket", "Megahauler", "The Ark",
}

DECKS["Bases & Battleships"] = {
  "Trade Raft", "Trade Raft", "Defense Bot", "Defense Bot",
  "Fighter Base", "Fighter Base", "Trade Wheel", "Trade Wheel",
  "Imperial Trader", "Mega Mech", "Construction Hauler", "Obliterator",
}

DECKS["Events"] = {
  "Black Hole",
  "Bombardment",
  "Comet",
  "Comet",
  "Galactic Summit",
  "Quasar",
  "Quasar",
  "Supernova",
  "Trade Mission",
  "Trade Mission",
  "Warp Jump",
  "Warp Jump",
}

DECKS["Heroes"] = {
  "Cunning Captain", "Cunning Captain", "Ram Pilot", "Ram Pilot",
  "Special Ops Director", "Special Ops Director", "War Elder", "War Elder",
  "Admiral Rasmussen", "Blob Overlord", "CEO Torres", "High Priest Lyle",
}

DECKS["Fleets & Fortresses"] = {
  "Cargo Launch", "Cargo Launch", "Spike Pod", "Spike Pod", "Patrol Bot",
  "Patrol Bot", "Border Fort", "Customs Frigate", "Customs Frigate",
  "Death World", "Star Fortress", "Capitol World",
}

-- DECKS["Year 2 Promos"] = {
-- "Federal Transport", "Federal Transport", "Imperial Smuggler",
-- "Imperial Smuggler", "Probe Bot", "Probe Bot", "War Kite",
-- "War Kite", "Mercenary Garrison", "Security Craft", "Security Craft",
-- "Bounty Hunter", "Cargo Mech", "Knightstar", "Stellar Ray",
-- "Merc Battlecruiser",
-- }

DECKS["Command"] = {
  "Unity Fighter", "Unity Fighter", "Assault Pod", "Assault Pod",
  "Alliance Frigate", "Alliance Frigate", "Coalition Freighter",
  "Coalition Freighter", "Alliance Landing", "Coalition Fortress",
  "Unity Station", "Union Cluster",
}

DECKS["United: Heroes"] = {
  "Chairman Haygan", "Chairman Haygan", "Screecher", "Screecher",
  "Chancellor Hartman", "Chancellor Hartman", "Commander Klik",
  "Commander Klik", "CEO Shaner", "Commodore Zhang", "Confessor Morris",
  "Hive Lord",
}

DECKS["Assault"] = {
  "Trade Star", "Trade Star", "Alliance Transport", "Alliance Transport",
  "Blob Bot", "Blob Bot", "Coalition Messenger", "Coalition Messenger",
  "Union Stronghold", "Exchange Point", "Lookout Post", "Embassy Base",
}

function getCardsOfDecks(decks)
  local cardcount = 0
  local allcards = {}
  for _, deckname in ipairs(decks) do
    for _, cardname in ipairs(DECKS[deckname]) do
      cardcount = cardcount + 1
      allcards[cardcount] = cardname
    end
  end

  return allcards
end

