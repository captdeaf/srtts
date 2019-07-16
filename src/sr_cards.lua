--[[

  Card definitions - pretty cramped since there's a LOT, so here's the key:

  {name, type, cost, {faction,list}, {effects}}

  type: SHIP, BASE, OUTPOST, HERO, GAMBIT, BOSS, EVENT

EFFECTS:
  An "effects" object is a simple table of key=value, of one or more
  of the below effects:

  Simple effects:
    def=5: 5 defense (for base or outpost only)
    a=2: Add 2 authority
    t=3: Add 3 trade (coin)
    d=4: Add 4 damage
    draw=2: Draw 2 Cards
    destroybase=1: Destroy target base
    tradescrap=2: Scrap up to 2 cards in trade row
    oppdiscard=1: Opponent discards 1
    mayscrap={HAND_ONLY, HAND_ONLY}: May Scrap 2 cards from hand
    mustscrap={HAND_ONLY, HAND_ONLY}: Must Scrap 2 cards from hand
    ally={TF}, allies TF until end of turn. Can't be removed for the turn. (Heroes)

  Special:
    mercenary=true -- If true, then this has a malleable faction.

  Ally effects:
    tf={effects}: Trade Fed ally Effects
    mc={effects}: Machine Cult ally Effects
    se={effects}: Star Empire ally Effects
    bb={effects}: Blob ally Effects
    union={ {{FAC1,FAC2},{effects}},...} - union of allies, e.g: SE _or_ TF
             (e.g: tf= can also be written as union={ {{TF},{...}} })

  Unique Effects:
    uniq={"name",...args} - unique execution in code path.

  Interactable: (card needs to be clicked, or player needs to choose a UI)
    choose={{effects1},{effects2}}: Pick between 2 trade or 2 authority
    onactivate={effects} - on clicking the card, player can choose to activate.
        (e.g: make base effects optional instead of mandatory)

  Triggered:
    buyto={tag, min, dest} - on purchase from trade row, deliver to {dest}
    onplay={effects} - when it first enters play (usually for a hero)
    onscrap={effects when scrapped}

  Conditional effects:
    check={tag, min, {effects}[, onnext]} - check a tag, if it's >= min, apply effects.
                  If onnext is true and tag fails check, then add a one-time
                  ontag event. (e.g: "has 3 bases now" vs "ever has 3 bases in
                  play this turn")
    ontag={tag, min, {effects}[, past]} - triggered every time a tag is set
                  if past is true, then triggers for each past tag.

  Not Yet Implemented:
    ondestroy={effects) - when card is destroyed.
    onreveal={effects} - when card is revealed (GAMBIT only?)
]]--

CARDDEFS = {
  -- Types: table of {name, is_sideways}
  { "Barter World", BASE, {TF}, 4, {def=4, choose={{a=2},{t=2}}, onscrap={d=5}}},
  { "Bioformer", BASE, {BB}, 4, {def=4, d=3, onscrap={t=3}}},
  { "Blob Wheel", BASE, {BB}, 3, {d=1, onscrap={t=3}, def=5}},
  { "Blob World", BASE, {BB}, 8, {def=7, choose={{d=5},{uniq={"blobworld"}}}}},
  { "Breeding Site", BASE, {BB}, 4, {def=7, check={"play:base", 1, {d=5}, true}}},
  { "Central Office", BASE, {TF}, 7, {def=6, t=2, uniq={"nextbuyto", SHIP, TO_TOP}, tf={draw=1}}},
  { "Central Station", BASE, {TF}, 4, {def=5, t=2, check={"my:base", 3, {a=4, draw=1}}}},
  { "Death World", BASE, {BB}, 7, {def=6, d=4, uniq={"scrapcycle", {from={S_HAND, S_PLAYER_DISCARD}, check={"factions", {SE, TF, MC}}, count=1, effects={draw=1}}}}},
  { "Embassy Base", BASE, {SE,TF}, 8, {def=6, onactivate={draw=2,mustdiscard=1}}},
  { "Exchange Point", BASE, {BB, MC}, 6, {def=7, d=2, union={{{MC,BB}, {choose={{tradescrap=1},{mayscrap={HAND_OR_DISCARD}}}}}}}},
  { "Fleet HQ", BASE, {SE}, 8, {def=8, ontag={"play:ship", {d=1}}}},
  { "Loyal Colony", BASE, {TF}, 7, {def=6, t=3, d=3, a=3}},
  { "Orbital Platform", BASE, {SE}, 3, {def=4, uniq={"recycle", 1}}, se={d=3}},
  { "Plasma Vent", BASE, {BB}, 6, {def=5, d=4, buyto={"play:bb", 1, TO_HAND}, onscrap={destroybase=1}}},
  { "Starbase Omega", BASE, {SE}, 4, {def=6, check={"play:base", 1, {oppdiscard=1}, true}}},
  { "Starmarket", BASE, {TF}, 4, {def=6, check={"play:base", 1, {choose={{a=5},{t=3}}}, true}}},
  { "Stellar Reef", BASE, {BB}, 2, {def=3, t=1, onscrap={d=3}}},
  { "Storage Silo", BASE, {TF}, 2, {def=3, a=2, tf={t=2}}},
  { "The Hive", BASE, {BB}, 5, {def=5, d=3, bb={draw=1}}},
  { "Trade Wheel", BASE, {BB}, 3, {def=5, t=1, bb={d=2}}},
  { "Union Cluster", BASE, {SE,BB}, 7, {def=8,d=4,union={{{SE,BB}, {draw=1}}}}},
  { "Union Stronghold", BASE, {BB, SE}, 5, {def=5, d=3, bb={tradescrap=1}, se={oppdiscard=1}}},

  { "Alliance Landing", OUTPOST, {TF,SE}, 5, {def=5, t=2, union={{{TF,SE},{d=2}}}}},
  { "Battle Station", OUTPOST, {MC}, 3, {def=5, onscrap={d=5}}},
  { "Border Fort", OUTPOST, {MC}, 4, {def=5, choose={{t=1},{d=2}}, mc={mayscrap={HAND_OR_DISCARD}}}},
  { "Brain World", OUTPOST, {MC}, 8, {def=6, uniq={"scrapcycle", {from={S_HAND, S_PLAYER_DISCARD}, count=2, effects={draw=1}}}}},
  { "Capitol World", OUTPOST, {TF}, 8, {def=6, a=6, draw=1}},
  { "Coalition Fortress", OUTPOST, {MC,TF}, 6, {def=6, t=2, union={{{TF,MC}, {choose={{d=2},{a=3}}}}}}},
  { "Command Center", OUTPOST, {SE}, 4, {def=4, t=2, ontag={"play:ship:se", {d=2}}}},
  { "Defense Center", OUTPOST, {TF}, 5, {def=5, choose={{a=3},{d=2}}, tf={d=2}}},
  { "Factory World", OUTPOST, {TF}, 8, {def=6, t=3, uniq={"nextbuyto", ANY, TO_HAND}}},
  { "Federation Shipyard", OUTPOST, {TF}, 6, {def=6, t=2, tf={uniq={"nextbuyto", ANY, TO_TOP}}}},
  { "Fighter Base", OUTPOST, {SE}, 3, {def=5, se={oppdiscard=1}}},
  { "Fortress Oblivion", OUTPOST, {MC}, 3, {def=4, check={"play:base", 1, {mayscrap={HAND_OR_DISCARD}}, true}}},
  { "Frontier Station", OUTPOST, {MC}, 6, {def=6, choose={{t=2},{d=3}}}},
  { "Imperial Palace", OUTPOST, {SE}, 7, {def=6, draw=1, oppdiscard=1, se={d=4}}},
  { "Junkyard", OUTPOST, {MC}, 6, {def=5, mayscrap={HAND_OR_DISCARD}}},
  { "Lookout Post", OUTPOST, {MC, TF}, 7, {def=6, draw=1}},
  { "Machine Base", OUTPOST, {MC}, 7, {def=6, onactivate={draw=1, mustscrap={HAND_ONLY}}}},
  { "Mech World", OUTPOST, {MC}, 5, {def=6, ally={MC, SE, TF, BB}}},
  { "Port of Call", OUTPOST, {TF}, 6, {def=6, t=3, onscrap={draw=1, destroybase=1}}},
  { "Recycling Station", OUTPOST, {SE}, 4, {def=4, choose={{uniq={"recycle", 2}},{t=1}}}},
  { "Royal Redoubt", OUTPOST, {SE}, 6, {def=6, d=3, se={oppdiscard=1}}},
  { "Secret Outpost", OUTPOST, {UA}, -1, {def=4, ondestroy={uniq={"scrapme"}}}},
  { "Space Station", OUTPOST, {SE}, 4, {def=4, d=2, se={d=2}, onscrap={t=4}}},
  { "Star Fortress", OUTPOST, {SE}, 7, {def=6, d=3, onactivate={draw=2,mustdiscard=1}, se={onactivate={draw=2,mustdiscard=1}}}},
  { "Stealth Tower", OUTPOST, {MC}, 5, {def=5, uniq={"stealthtower"}}},
  { "Supply Depot", OUTPOST, {SE}, 6, {def=5, uniq={"discardfor", 2, {choose={{t=2},{d=2}}}}, se={draw=1}}},
  { "The Incinerator", OUTPOST, {MC}, 8, {def=6, mayscrap={HAND_OR_DISCARD, HAND_OR_DISCARD}, mc={ontag={"scrap:handordiscard", {d=2}, true}}}},
  { "The Oracle", OUTPOST, {MC}, 4, {def=5, mayscrap={HAND_ONLY}, mc={d=3}}},
  { "Trading Post", OUTPOST, {TF}, 3, {def=4, choose={{a=1},{t=1}}, onscrap={d=3}}},
  { "Unity Station", OUTPOST, {BB,MC}, 7, {def=6,tradescrap=1,mayscrap={HAND_OR_DISCARD},union={{{TF,MC}, {d=4}}}}},
  { "Warning Beacon", OUTPOST, {MC}, 2, {def=2, d=2, buyto={"play:mc", 1, TO_HAND}}},
  { "War World", OUTPOST, {SE}, 5, {def=4, d=3, se={d=4}}},

  { "Black Hole", EVENT },
  { "Bombardment", EVENT },
  { "Comet", EVENT },
  { "Galactic Summit", EVENT },
  { "Quasar", EVENT },
  { "Supernova", EVENT },
  { "Trade Mission", EVENT },
  { "Warp Jump", EVENT },

  { "Acceptable Losses", GAMBIT, {UA}, -1, {onscrap={mayscrap={HAND_ONLY, HAND_ONLY}}}},
  { "Asteroid Mining", GAMBIT, {UA}, -1, {onreveal={t=1}, onscrap={draw=1}}},
  { "Black Market", GAMBIT, {UA}, -1, {uniq={"blackmarket", 1}}},
  { "Bold Raid", GAMBIT, {UA}, -1, {onscrap={destroybase=1, draw=1}}},
  { "Energy Shield", GAMBIT, {UA}, -1, {uniq={"damagereduction", 1}}},
  { "Exploration", GAMBIT, {UA}, -1, {onscrap={uniq={"explorationgambit"}}}},
  { "Frontier Fleet", GAMBIT, {UA}, -1, {d=1}},
  { "Hidden Base", GAMBIT, {UA}, -1, {onscrap={a=4}, uniq={"secretoutpost"}}},
  { "Political Maneuver", GAMBIT, {UA}, -1, {onscrap={t=2}}},
  { "Rapid Deployment", GAMBIT, {UA}, -1, {onscrap={t=1, uniq={"nextbuyto", SHIP, TO_TOP}}}},
  { "Rise to Power", GAMBIT, {UA}, -1, {onscrap={a=8, draw=1}}},
  { "Salvage Operation", GAMBIT, {UA}, -1, {onscrap={uniq={"discardtotop", {}}}}},
  { "Smuggling Run", GAMBIT, {UA}, -1, {onscrap={"freecard", {SHIP}, 4, TO_DISCARD}}},
  { "Surprise Assault", GAMBIT, {UA}, -1, {onscrap={d=8}}},
  { "Triumphant Return", GAMBIT, {UA}, -1, {onscrap={draw=1}}},
  { "Two-Pronged Attack", GAMBIT, {UA}, -1, {onreveal={d=2}, onscrap={d=3, draw=1}}},
  { "Unlikely Alliance", GAMBIT, {UA}, -1, {onscrap={draw=2}}},
  { "Veteran Pilots", GAMBIT, {UA}, -1, {ontag={"play:Viper", {d=2}}}},
  { "Wild Gambit", GAMBIT, {UA}, -1, {onscrap={uniq={"wildgambit"}}}},

  { "Admiral Rasmussen", HERO, {UA}, 2, {onscrap={draw=1, ally={SE}}}},
  { "Blob Overlord", HERO, {UA}, 2, {onscrap={d=4, ally={BB}}}},
  { "CEO Shaner", HERO, {UA}, 5, {onplay={ally={TF}, uniq={"freecard", {SHIP, OUTPOST, BASE}, 3, TO_TOP}}, onscrap={draw=1, ally={TF}}}},
  { "CEO Torres", HERO, {UA}, 2, {onscrap={a=7,ally={TF}}}},
  { "Chairman Haygan", HERO, {UA}, 3, {onplay={ally={TF}, a=4}, onscrap={a=4, ally={TF}}}},
  { "Chancellor Hartman", HERO, {UA}, 4, {onplay={ally={MC}, mayscrap={HAND_OR_DISCARD}}, onscrap={mayscrap={HAND_OR_DISCARD}, ally={MC}}}},
  { "Commander Klik", HERO, {UA}, 4, {onplay={ally={SE}, uniq={"recycle", 1}}, onscrap={uniq={"recycle", 1}, ally={SE}}}},
  { "Commodore Zhang", HERO, {UA}, 5, {onplay={ally={SE}, d=5, oppdiscard=1}, onscrap={draw=1, ally={SE}}}},
  { "Confessor Morris", HERO, {UA}, 5, {onplay={ally={MC}, mayscrap={HAND_OR_DISCARD,HAND_OR_DISCARD}}, onscrap={draw=1, ally={MC}}}},
  { "Cunning Captain", HERO, {UA}, 1, {onscrap={oppdiscard=1, ally={SE}}}},
  { "High Priest Lyle", HERO, {UA}, 2, {onscrap={mayscrap={HAND_OR_DISCARD}, ally={MC}}}},
  { "Hive Lord", HERO, {UA}, 5, {onplay={ally={BB}, d=2, tradescrap=5}, onscrap={draw=1, ally={BB}}}},
  { "Ram Pilot", HERO, {UA}, 1, {onscrap={d=2, ally={BB}}}},
  { "Screecher", HERO, {UA}, 3, {onplay={ally={BB}, d=2, tradescrap=1}, onscrap={tradescrap=1, d=2, ally={BB}}}},
  { "Special Ops Director", HERO, {UA}, 1, {onscrap={a=4, ally={TF}}}},
  { "War Elder", HERO, {UA}, 1, {onscrap={mayscrap={HAND_ONLY}, ally={MC}}}},

  { "Aging Battleship", SHIP, {SE}, 5, {d=5, se={draw=1}, onscrap={d=2, draw=2}}},
  { "Alliance Frigate", SHIP, {TF,SE}, 3, {d=4,se={d=3},tf={a=4}}},
  { "Alliance Transport", SHIP, {SE,TF}, 2, {t=2, se={oppdiscard=1}, tf={a=4}}},
  { "Assault Pod", SHIP, {SE,BB}, 2,{d=3, union={{{BB,SE}, {draw=1}}}}},
  { "Battle Barge", SHIP, {SE}, 4, {d=5, oppdiscard=1, check={"my:base", 2, {d=3, uniq={"mayreturn", {BASE, OUTPOST}, 1}}}}},
  { "Battle Blob", SHIP, {BB}, 6, {d=8, bb={draw=1}, onscrap={d=4}}},
  { "Battle Bot", SHIP, {MC}, 1, {d=2, mayscrap={HAND_ONLY}, mc={d=2}}},
  { "Battlecruiser", SHIP, {SE}, 6, {d=5, draw=1, se={oppdiscard=1}, onscrap={draw=1, destroybase=1}}},
  { "Battle Mech", SHIP, {MC}, 5, {d=4, mayscrap={HAND_OR_DISCARD}, mc={draw=1}}},
  { "Battle Pod", SHIP, {BB}, 2, {d=4, tradescrap=1, bb={d=2}}},
  { "Battle Screecher", SHIP, {BB}, 4, {d=5, tradescrap=5, bb={t=2}}},
  { "Blob Bot", SHIP, {BB, MC}, 3, {d=5, bb={t=2}, mc={mayscrap={HAND_OR_DISCARD}}}},
  { "Blob Carrier", SHIP, {BB}, 6, {d=7, bb={uniq={"freecard", {SHIP}, 100, TO_TOP}}}},
  { "Blob Destroyer", SHIP, {BB}, 4, {d=6, bb={destroybase=1, tradescrap=1}}},
  { "Blob Fighter", SHIP, {BB}, 1, {d=3, bb={draw=1}}},
  { "Mothership", SHIP, {BB}, 7, {d=6, draw=1, bb={draw=1}}},
  { "Cargo Launch", SHIP, {SE}, 1, {draw=1, onscrap={t=1}}},
  { "Cargo Pod", SHIP, {BB}, 3, {t=3, bb={d=3}, onscrap={d=3}}},
  { "Coalition Freighter", SHIP, {TF,MC}, 4, {t=3, tf={uniq={"nextbuyto", SHIP, TO_TOP}}, mc={mayscrap={HAND_OR_DISCARD}}}},
  { "Coalition Messenger", SHIP, {MC,TF}, 3, {t=2, union={{{MC,TF}, {uniq={"discardtotop", {check={"cost", 5}}}}}}}},
  { "Colony Seed Ship", SHIP, {TF}, 5, {t=3, d=3, a=3, buyto={"play:tf", 1, TO_HAND}}},
  { "Command Ship", SHIP, {TF}, 8, {draw=2, a=4, d=5, tf={destroybase=1}}},
  { "Construction Hauler", SHIP, {TF}, 6, {a=3, t=2, draw=1, tf={uniq={"nextbuyto", BASES, TO_PLAY}}}},
  { "Convoy Bot", SHIP, {MC}, 3, {d=4, mayscrap={HAND_OR_DISCARD}, mc={d=2}}},
  { "Corvette", SHIP, {SE}, 2, {d=1, draw=1, se={d=2}}},
  { "Customs Frigate", SHIP, {TF}, 4, {uniq={"freecard", {SHIP}, 4, TO_TOP}, tf={d=4}, onscrap={draw=1}}},
  { "Cutter", SHIP, {TF}, 2, {t=2, a=4, tf={d=4}}},
  { "Defense Bot", SHIP, {MC}, 2, {d=1, mayscrap={HAND_OR_DISCARD}, check={"my:base", 2, {d=8}}}},
  { "Dreadnaught", SHIP, {SE}, 7, {d=7, draw=1, onscrap={d=5}}},
  { "Embassy Yacht", SHIP, {TF}, 3, {a=3, t=2, check={"my:base", 2, {draw=2}}}},
  { "Emperor's Dreadnaught", SHIP, {SE}, 8, {d=8, draw=1, oppdiscard=1, buyto={"play:se", 1, TO_HAND}}},
  { "Explorer", SHIP, {UA}, 2, {t=2, onscrap={d=2}}},
  { "Falcon", SHIP, {SE}, 3, {d=2, draw=1, onscrap={oppdiscard=1}}},
  { "Federation Shuttle", SHIP, {TF}, 1, {t=2, tf={a=2}}, onscrap={oppdiscard=1}},
  { "Flagship", SHIP, {TF}, 6, {d=5, draw=1, tf={a=5}}},
  { "Freighter", SHIP, {TF}, 4, {t=4, tf={uniq={"nextbuyto", SHIP, TO_TOP}}}},
  { "Frontier Ferry", SHIP, {TF}, 4, {t=3, a=4, onscrap={destroybase=1}}},
  { "Gunship", SHIP, {SE}, 4, {d=5, oppdiscard=1, onscrap={t=4}}},
  { "Heavy Cruiser", SHIP, {SE}, 5, {d=4, draw=1, se={draw=1}}},
  { "Imperial Fighter", SHIP, {SE}, 1, {d=2, oppdiscard=1, se={d=2}}},
  { "Imperial Frigate", SHIP, {SE}, 3, {d=4, oppdiscard=1, se={d=2}, onscrap={draw=1}}},
  { "Imperial Trader", SHIP, {SE}, 5, {t=3, draw=1, se={d=4}}},
  { "Lancer", SHIP, {SE}, 2, {d=4, check={"enemy:base", 1, {d=2}}, se={oppdiscard=1}}},
  { "Leviathan", SHIP, {BB}, 8, {d=9, draw=1, destroybase=1, bb={uniq={"freecard", {SHIP}, 3, TO_HAND}}}},
  { "Mech Cruiser", SHIP, {MC}, 5, {d=6, mayscrap={HAND_OR_DISCARD}, mc={destroybase=1}}},
  { "Megahauler", SHIP, {TF}, 7, {a=5, uniq={"freecard", {SHIP}, 100, TO_TOP}, tf={draw=1}}},
  { "Mega Mech", SHIP, {MC}, 5, {d=6, uniq={"mayreturn", {BASE, OUTPOST}, 1}, mc={draw=1}}},
  { "Merc Cruiser", SHIP, {UA}, 3, {d=5, mercenary=true}},
  { "Mining Mech", SHIP, {MC}, 4, {t=3, mayscrap={HAND_OR_DISCARD}, mc={d=3}}},
  { "Missile Bot", SHIP, {MC}, 2, {d=2, mayscrap={HAND_OR_DISCARD}, mc={d=2}}},
  { "Missile Mech", SHIP, {MC}, 6, {d=6, destroybase=1, mc={draw=1}}},
  { "Moonwurm", SHIP, {BB}, 7, {d=8, draw=1, bb={uniq={"freecard", {}, 2, TO_HAND}}}},
  { "Obliterator", SHIP, {BB}, 6, {d=7, check={"enemy:base", 2, {d=6}}, bb={draw=1}}},
  { "Parasite", SHIP, {BB}, 5, {choose={{d=6},{uniq={"freecard", {}, 6, TO_DISCARD}}}, bb={draw=1}}},
  { "Patrol Bot", SHIP, {MC}, 2, {choose={{t=2},{d=4}}, mc={mayscrap={HAND_OR_DISCARD}}}},
  { "Patrol Cutter", SHIP, {TF}, 3, {t=2, d=3, tf={a=4}}},
  { "Patrol Mech", SHIP, {MC}, 4, {choose={{t=3},{d=5}}, mc={mayscrap={HAND_OR_DISCARD}}}},
  { "Peacekeeper", SHIP, {TF}, 6, {d=6, a=6, tf={draw=1}}},
  { "Predator", SHIP, {BB}, 2, {d=4, bb={draw=1}}},
  { "Ram", SHIP, {BB}, 3, {d=5, bb={d=2}, onscrap={t=3}}},
  { "Ravager", SHIP, {BB}, 3, {d=6, tradescrap=2}},
  { "Repair Bot", SHIP, {MC}, 2, {t=2, mayscrap={DISCARD_ONLY}, onscrap={d=2}}},
  { "Scout", SHIP, {UA}, 0, {t=1}},
  { "Solar Skiff", SHIP, {TF}, 1, {t=2, tf={draw=1}}},
  { "Spike Pod", SHIP, {BB}, 1, {d=3, tradescrap=2, onscrap={d=2}}},
  { "Star Barge", SHIP, {SE}, 1, {t=2, se={d=2, oppdiscard=1}}},
  { "Stealth Needle", SHIP, {MC}, 4 , {uniq={"stealthneedle"}}},
  { "Supply Bot", SHIP, {MC}, 3, {t=2, mayscrap={HAND_OR_DISCARD}, mc={d=2}}},
  { "Survey Ship", SHIP, {SE}, 3, {t=1, draw=1, onscrap={oppdiscard=1}}},
  { "Swarmer", SHIP, {BB}, 1, {d=3, tradescrap=1, bb={d=2}}},
  { "The Ark", SHIP, {MC}, 7, {d=5, uniq={"scrapcycle", {from={S_HAND, S_PLAYER_DISCARD}, count=2, effects={draw=1}}}, onscrap={destroybase=1}}},
  { "The Wrecker", SHIP, {MC}, 7, {d=6, mayscrap={HAND_OR_DISCARD, HAND_OR_DISCARD}, mc={draw=1}}},
  { "Trade Bot", SHIP, {MC}, 1, {t=1, mayscrap={HAND_OR_DISCARD}, mc={d=2}}},
  { "Trade Escort", SHIP, {TF}, 5, {a=4, d=4, tf={draw=1}}},
  { "Trade Hauler", SHIP, {TF}, 2, {t=3, tf={a=3}}},
  { "Trade Pod", SHIP, {BB}, 2, {t=3, bb={d=2}}},
  { "Trade Raft", SHIP, {TF}, 1, {t=1, tf={draw=1}, onscrap={t=1}}},
  { "Trade Star", SHIP, {BB, SE}, 1, {t=2, onscrap={d=2}}},
  { "Unity Fighter", SHIP, {MC,BB}, 1, {d=3, tradescrap=1, onscrap={mayscrap={HAND_OR_DISCARD}}}},
  { "Viper", SHIP, {UA}, 0, {d=1}},

  -- Frontier:
  { "Blob Alpha", SHIP, {BB}, 6, {d=10}},
  { "Blob Miner", SHIP, {BB}, 2, {t=3, tradescrap=1, onscrap={d=2}}},
  { "Burrower", SHIP, {BB}, 3, {d=5, bb={draw=1}, onscrap={uniq={"freecard", {}, 4, TO_DISCARD}}}},
  { "Crusher", SHIP, {BB}, 3, {d=6, bb={t=2}}},
  { "Hive Queen", SHIP, {BB}, 7, {d=7, draw=1, bb={d=3}, combo={{{bb=2}, {d=3}}}}},
  { "Infested Moon", BASE, {BB}, 6, {def=5, d=4, bb={draw=1}, combo={{{bb=2}, {draw=1}}}}},
  { "Moonwurm Hatchling", SHIP, {BB}, 4, {choose={{t=3},{destroybase=1}}, bb={d=3}, combo={{{bb=2},{d=3}}}}},
  { "Nesting Ground", BASE, {BB}, 4, {def=5, t=2, bb={d=4}}},
  { "Pulverizer", SHIP, {BB}, 5, {uniq={"scrapforcost", {from={S_TRADE}, effects={d=1}}}, bb={draw=1}}},
  { "Spike Cluster", BASE, {BB}, 2, {def=3, d=2, bb={t=1}}},
  { "Stinger", SHIP, {BB}, 1, {d=3, bb={d=3}, onscrap={t=1}}},
  { "Swarm Cluster", BASE, {BB}, 8, {def=8, d=5, bb={d=3}, combo={{{bb=2}, {d=3}}}}},

  { "Builder Bot", SHIP, {MC}, 1, {t=1, mayscrap={DISCARD_ONLY}, mc={t=1}, onscrap={d=2}}},
  { "Conversion Yard", OUTPOST, {MC}, 5, {def=4, uniq={"scrapcycle", {from={S_HAND}, count=1, effects={d=4}}}}},
  { "Defense System", OUTPOST, {MC}, 4, {def=5, d=2, mc={d=2}}},
  { "Destroyer Bot", SHIP, {MC}, 3, {d=5, mayscrap={DISCARD_ONLY}}},
  { "Enforcer Mech", SHIP, {MC}, 5, {d=5, mayscrap={HAND_OR_DISCARD}, mc={destroybase=1}, onscrap={draw=1}}},
  { "Integration Port", OUTPOST, {MC}, 3, {def=5, t=1}},
  { "Nanobot Swarm", SHIP, {MC}, 8, {d=5, draw=2, mayscrap={HAND_OR_DISCARD, HAND_OR_DISCARD}}},
  { "Neural Nexus", OUTPOST, {MC}, 7, {def=6, uniq={"scrapforcost", {from={S_HAND, S_PLAYER_DISCARD}, effects={d=1}}},  mc={draw=1}}},
  { "Plasma Bot", SHIP, {MC}, 2, {d=3, mayscrap={HAND_ONLY}, mc={d=2}}},
  { "Reclamation Station", OUTPOST, {MC}, 6, {def=6, mayscrap={DISCARD_ONLY}, onscrap={uniq="reclamation"}}},
  { "Repair Mech", SHIP, {MC}, 4, {choose={t=3, {uniq={"discardtotop", {check={"type", {BASE, OUTPOST}}}}}}, mc={mayscrap={HAND_OR_DISCARD}}}},

  { "Captured Outpost", OUTPOST, {SE}, 3, {def=3, draw=1, mustdiscard=1}},
  { "Cargo Craft", SHIP, {SE}, 2, {t=2, oppdiscard=1, se={d=4}}},
  { "Farm Ship", SHIP, {SE}, 4, {t=3, draw=1, mustdiscard=1, onscrap={d=4}}},
  { "Frontier Hawk", SHIP, {SE}, 1, {d=3, draw=1, mustdiscard=1}},
  { "Hammerhead", SHIP, {SE}, 5, {d=3, draw=1, oppdiscard=1, se={draw=1, mustdiscard=1}}},
  { "Imperial Flagship", SHIP, {SE}, 8, {d=7, draw=2, se={oppdiscard=1}}},
  { "Jamming Terminal", BASE, {SE}, 5, {def=6, d=2, oppdiscard=1}},
  { "Light Cruiser", SHIP, {SE}, 3, {d=4, oppdiscard=1, se={d=2}, combo={{{se=2},{draw=1}}}}},
  { "Orbital Gun Platform", OUTPOST, {SE}, 4, {def=4, d=3, onscrap={t=3}}},
  { "Siege Fortress", OUTPOST, {SE}, 7, {def=5, d=5, se={d=4}}},
  { "Warpgate Cruiser", SHIP, {SE}, 6, {uniq={"discardfor", 100, {d=2}}, draw=1, se={draw=1}}},

  { "Federation Battleship", SHIP, {TF}, 7, {d=5, a=5, draw=1, tf={destroybase=1}, onscrap={a=10}}},
  { "Federation Cruiser", SHIP, {TF}, 5, {d=5, a=4, tf={d=2, a=2}}},
  { "Frontier Runner", SHIP, {TF}, 1, {t=2, a=2}},
  { "Gateship", SHIP, {TF}, 6, {uniq={"freecard", {SHIP, OUTPOST, BASE}, 6, TO_TOP}, tf={a=5}}},
  { "Ion Station", OUTPOST, {TF}, 5, {def=5, t=2, tf={t=1}, combo={{{tf=2},{d=4,a=4}}}}},
  { "Long Hauler", SHIP, {TF}, 4, {t=3, tf={t=2}, onscrap={uniq={"nextbuyto", BASES, TO_TOP}}}},
  { "Mobile Market", OUTPOST, {TF}, 4, {def=4, t=2, onscrap={a=2, draw=1, uniq={"recoverme", TO_DISCARD}}}},
  { "Orbital Shuttle", SHIP, {TF}, 2, {t=3, check={"my:base", 2, {a=4, draw=1}}}},
  { "Outland Station", BASE, {TF}, 3, {def=4, choose={{t=1},{a=3}}, onscrap={draw=1}}},
  { "Patrol Boat", SHIP, {TF}, 3, {d=4, a=3, tf={a=2}}},
  { "Transit Nexus", BASE, {TF}, 8, {def=6, d=3, t=4, a=5}},
}

