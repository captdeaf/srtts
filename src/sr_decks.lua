AVAILABLE_DECKS = {
  {name = "Core Set", count = 1, fullset=true},
  {name = "Colony Wars", count = 0, fullset=true},
  {name = "Frontiers", count = 0, fullset=true},
  {name = "Year 1 Promos", count = 0},
  {name = "Crisis: Bases & Battleships", count = 0},
  {name = "Crisis: Heroes", count = 0},
  {name = "Crisis: Fleets and Fortresses", count = 0},
  {name = "United: Command", count = 0},
  {name = "United: Heroes", count = 0},
  {name = "United: Assault", count = 0},
}

DECKS = {}

DECKS["STARTDECK"] = {
  "Scout", "Scout", "Scout", "Scout", "Scout", "Scout", "Scout", "Scout",
  "Viper", "Viper",
}

function getCardsOfDecks(decks)
  local cardcount = 0
  local allcards = {}
  for _, deckname in ipairs(decks) do
    printf("deckname: %s", deckname)
    for _, cardname in ipairs(DECKS[deckname]) do
      cardcount = cardcount + 1
      allcards[cardcount] = cardname
    end
  end

  return allcards
end

-- Below here: All generated by generatedecks
DECKS["Core Set"] = {"Battle Blob", "Battle Pod", "Battle Pod", "Blob Carrier", "Blob Destroyer", "Blob Destroyer", "Blob Fighter", "Blob Fighter", "Blob Fighter", "Blob Wheel", "Blob Wheel", "Blob Wheel", "Blob World", "Mothership", "Ram", "Ram", "The Hive", "Trade Pod", "Trade Pod", "Trade Pod", "Battle Mech", "Battle Station", "Battle Station", "Brain World", "Junkyard", "Machine Base", "Mech World", "Missile Bot", "Missile Bot", "Missile Bot", "Missile Mech", "Patrol Mech", "Patrol Mech", "Stealth Needle", "Supply Bot", "Supply Bot", "Supply Bot", "Trade Bot", "Trade Bot", "Trade Bot", "Battlecruiser", "Corvette", "Corvette", "Dreadnaught", "Fleet HQ", "Imperial Fighter", "Imperial Fighter", "Imperial Fighter", "Imperial Frigate", "Imperial Frigate", "Imperial Frigate", "Recycling Station", "Recycling Station", "Royal Redoubt", "Space Station", "Space Station", "Survey Ship", "Survey Ship", "Survey Ship", "War World", "Barter World", "Barter World", "Central Office", "Command Ship", "Cutter", "Cutter", "Cutter", "Defense Center", "Embassy Yacht", "Embassy Yacht", "Federation Shuttle", "Federation Shuttle", "Federation Shuttle", "Flagship", "Freighter", "Freighter", "Port of Call", "Trade Escort", "Trading Post", "Trading Post"}
DECKS["Year 1 Promos"] = {"Battle Barge", "Battle Barge", "Battle Screecher", "Battle Screecher", "Breeding Site", "Fortress Oblivion", "Fortress Oblivion", "Megahauler", "Starbase Omega", "Starmarket", "Starmarket", "The Ark"}
DECKS["Promo Pack 1"] = {"Battle Barge", "Battle Barge", "Battle Screecher", "Battle Screecher", "Breeding Site", "Fortress Oblivion", "Fortress Oblivion", "Megahauler", "Mercenary Garrison", "Security Craft", "Security Craft", "Starbase Omega", "Starmarket", "Starmarket", "The Ark"}
DECKS["Gambit"] = {"Merc Cruiser", "Merc Cruiser", "Merc Cruiser"}
DECKS["Crisis: Bases & Battleships"] = {"Construction Hauler", "Defense Bot", "Defense Bot", "Fighter Base", "Fighter Base", "Imperial Trader", "Mega Mech", "Obliterator", "Trade Raft", "Trade Raft", "Trade Wheel", "Trade Wheel"}
DECKS["Crisis: Fleets and Fortresses"] = {"Border Fort", "Capitol World", "Cargo Launch", "Cargo Launch", "Customs Frigate", "Customs Frigate", "Death World", "Patrol Bot", "Patrol Bot", "Spike Pod", "Spike Pod", "Star Fortress"}
DECKS["Crisis: Heroes"] = {"Admiral Rasmusson", "Blob Overlord", "CEO Torres", "Cunning Captain", "Cunning Captain", "High Priest Lyle", "Ram Pilot", "Ram Pilot", "Special Ops Director", "Special Ops Director", "War Elder", "War Elder"}
DECKS["Colony Wars"] = {"Bioformer", "Bioformer", "Cargo Pod", "Cargo Pod", "Cargo Pod", "Leviathan", "Moonwurm", "Parasite", "Plasma Vent", "Ravager", "Ravager", "Stellar Reef", "Stellar Reef", "Stellar Reef", "Battle Bot", "Battle Bot", "Battle Bot", "Convoy Bot", "Convoy Bot", "Convoy Bot", "Frontier Station", "Mech Cruiser", "Mining Mech", "Mining Mech", "Repair Bot", "Repair Bot", "Repair Bot", "Stealth Tower", "The Incinerator", "The Oracle", "The Wrecker", "Warning Beacon", "Warning Beacon", "Warning Beacon", "Aging Battleship", "Command Center", "Command Center", "Emperor's Dreadnaught", "Falcon", "Falcon", "Gunship", "Gunship", "Heavy Cruiser", "Imperial Palace", "Lancer", "Lancer", "Lancer", "Orbital Platform", "Orbital Platform", "Orbital Platform", "Star Barge", "Star Barge", "Star Barge", "Supply Depot", "Central Station", "Central Station", "Colony Seed Ship", "Factory World", "Federation Shipyard", "Frontier Ferry", "Frontier Ferry", "Loyal Colony", "Patrol Cutter", "Patrol Cutter", "Patrol Cutter", "Peacekeeper", "Solar Skiff", "Solar Skiff", "Solar Skiff", "Storage Silo", "Storage Silo", "Trade Hauler", "Trade Hauler", "Trade Hauler"}
DECKS["United: Assault"] = {"Alliance Transport", "Alliance Transport", "Blob Bot", "Blob Bot", "Coalition Messenger", "Coalition Messenger", "Embassy Base", "Exchange Point", "Lookout Post", "Trade Star", "Trade Star", "Union Stronghold"}
DECKS["United: Command"] = {"Alliance Frigate", "Alliance Frigate", "Alliance Landing", "Assault Pod", "Assault Pod", "Coalition Fortress", "Coalition Freighter", "Coalition Freighter", "Union Cluster", "Unity Fighter", "Unity Fighter", "Unity Station"}
DECKS["United: Heroes"] = {"CEO Shaner", "Chairman Haygan", "Chairman Haygan", "Chancellor Hartman", "Chancellor Hartman", "Commander Klik", "Commander Klik", "Commodore Zhang", "Confessor Morris", "Hive Lord", "Screecher", "Screecher"}
DECKS["Frontiers"] = {"Blob Alpha", "Blob Miner", "Blob Miner", "Blob Miner", "Burrower", "Burrower", "Crusher", "Crusher", "Hive Queen", "Infested Moon", "Moonwurm Hatchling", "Moonwurm Hatchling", "Nesting Ground", "Pulverizer", "Spike Cluster", "Spike Cluster", "Stinger", "Stinger", "Stinger", "Swarm Cluster", "Builder Bot", "Builder Bot", "Builder Bot", "Conversion Yard", "Defense System", "Defense System", "Destroyer Bot", "Destroyer Bot", "Destroyer Bot", "Enforcer Mech", "Integration Port", "Integration Port", "Nanobot Swarm", "Neural Nexus", "Plasma Bot", "Plasma Bot", "Plasma Bot", "Reclamation Station", "Repair Mech", "Repair Mech", "Captured Outpost", "Captured Outpost", "Cargo Craft", "Cargo Craft", "Cargo Craft", "Farm Ship", "Farm Ship", "Frontier Hawk", "Frontier Hawk", "Frontier Hawk", "Hammerhead", "Imperial Flagship", "Jamming Terminal", "Light Cruiser", "Light Cruiser", "Light Cruiser", "Orbital Gun Platform", "Orbital Gun Platform", "Siege Fortress", "Warpgate Cruiser", "Federation Battleship", "Federation Cruiser", "Frontier Runner", "Frontier Runner", "Frontier Runner", "Gateship", "Ion Station", "Long Hauler", "Long Hauler", "Mobile Market", "Mobile Market", "Orbital Shuttle", "Orbital Shuttle", "Orbital Shuttle", "Outland Station", "Outland Station", "Outland Station", "Patrol Boat", "Patrol Boat", "Transit Nexus"}
DECKS["Year 2 Promos"] = {"Bounty Hunter", "Cargo Mech", "Federal Transport", "Federal Transport", "Imperial Smuggler", "Imperial Smuggler", "Knightstar", "Probe Bot", "Probe Bot", "Stellar Ray", "War Kite", "War Kite"}
DECKS["Frontiers Kickstarter Promos"] = {"Assimilator", "Assur 4", "Blockade Runner", "Blockade Runner", "Blockade Runner", "Cargo Rocket", "Cargo Rocket", "Cargo Rocket", "Converter", "Demolisher", "Freight Raft", "Freight Raft", "Imperial Defender", "Imperial Defender", "Midgate Station", "Plague Pod", "Plague Pod", "Plague Pod", "Recycle Bot", "Recycle Bot", "Recycle Bot", "Sentinel", "Sentinel", "Spawning Wurm", "Swarming Point", "Temple Guardian", "Temple Guardian", "The Colossus", "Trade Envoy"}
DECKS["Command Deck: The Alignment"] = {"Mech Battleship", "Imperial Talon", "Imperial Viper", "Ranger", "Salvage Drone", "Scout Bot", "Stellar Falcon", "Welder Drone"}
DECKS["Command Deck: The Alliance"] = {"Super Freighter", "Cargo Boat", "Diplomatic Shuttle", "Federation Scout", "Imperial Viper", "Ranger", "Stellar Falcon", "Tribute Transport"}
DECKS["Command Deck: The Coalition"] = {"Mech Command Ship", "Cargo Boat", "Federation Scout", "Frontier Tug", "Laser Drone", "Ranger", "Salvage Drone", "Viper Bot"}
DECKS["Command Deck: The Pact"] = {"Super Carrier", "Cluster Scout", "Diplomatic Shuttle", "Escort Viper", "Frontier Tug", "Ranger", "Ripper", "Swarmling"}
DECKS["Command Deck: The Union"] = {"Meganaut", "Cluster Viper", "Imperial Scout", "Imperial Talon", "Protopod", "Ranger", "Ripper", "Tribute Transport"}
DECKS["Command Deck: The Unity"] = {"Mech Wurm", "Cluster Viper", "Laser Drone", "Protopod", "Ranger", "Scout Bot", "Swarmling", "Welder Drone"}
DECKS["Command Deck: Lost Fleet"] = {"Lost Dreadnaught", "Assault Shard", "Assault Shard", "Assault Shard", "Command Shard", "Command Shard", "Recon Shard", "Recon Shard", "Recon Shard", "Salvage Shard", "Salvage Shard", "Salvage Shard", "Transport Shard", "Transport Shard", "Transport Shard"}
DECKS["Stellar Allies"] = {"Alignment Bot", "Alignment Bot", "The Citadel", "Missile Silo", "Needle Lancer", "Needle Lancer", "Pact Pod", "Pact Pod", "Pact Warship", "Pact Warship", "Summit Site", "Trade Hive"}
DECKS["Universal Storage Box"] = {"Brooder", "Brooder", "Embassy Transport", "Embassy Transport", "Orbital Crane", "Orbital Crane", "Recovery Mech", "Recovery Mech"}
DECKS["Promo (Deck Box)"] = {"Mercenary Garrison"}
DECKS["Promo (Dice Tower)"] = {"Security Craft"}
DECKS["Promo (Storage Box)"] = {"Merc Battlecruiser"}
DECKS["Promo (Base Set Kickstarter)"] = {"Merc Cruiser"}
