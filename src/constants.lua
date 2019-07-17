-- constants.lua
--
-- This file contains data that really never is likely to change.
--
-- A lot of the values are strings, and they're used as keys, because
-- to Lua, a string is immutable, and all strings with the same value
-- are pointers to the same value / have the same key.

-- VERSION applies to structure of GAMESTATE and MENU_CHOICES.
-- Any changes at all basically need to bump version so the previous save(s)
-- won't cause errors.
VERSION = 5

----------
-- GAMESTATES:
----------

UNREADY = 0       -- Not yet started
STARTING = 10     -- Started. Player interaction at this time is a bad idea.
RUNNING = 20      -- Game in session, and under script control.
UNSCRIPTED = 30   -- Game in session, with limited scripting.
ENDED = 50        -- Game over, winner declared.

----------
-- Game state defaults. Whenever game is reset after ending
-- or "reset board" is clicked, just in case. This is duplicated
-- so should never change. (If it does, something's borked!)
----------
GAMESTATE_CLEAN = {
  state = UNREADY,
  -- Individual player state: musts, mays, etc.
  players = {},
  -- For 2 headed hydra/etc. Teams otherwise == Colors
  teams = {},
  -- Play state for the current hand. Is wiped clean at turn start.
  play = {},
  -- Current trade cards in trade row.
  tradecards = {},
  -- Play state data for the house rules.
  houserules = {},
  -- Which colors are AI?
  ai = {},

  -- Probably going away soon:
  canstart = false,
  tradedeck = {},
  decks = {},
}

----------
-- Constants for Gameplay.
----------
-- Card types.
ANY = "Any card"
SHIP = "Ship"
BASE = "Base"
BASES = "Base or Outpost" -- Don't use in card definition, it's for comparison
OUTPOST = "Outpost"
HERO = "Hero"
EVENT = "Event"
GAMBIT = "Gambit"
MISSION = "Mission"

-- Portrait = false, Landscape = true
ORIENTATIONS = {
  [SHIP]      = false,
  [HERO]      = false,
  [EVENT]     = false,
  [MISSION]   = false,

  [GAMBIT]    = true,
  [BASE]      = true,
  [OUTPOST]   = true,
}

-- FACTIONS - used by cards and effects.
UA = "Unaligned"
TF = "Trade Federation"
BB = "Blob"
MC = "Machine Cult"
SE = "Star Empire"

-- Faction map both ways:
FACTION_MAP = {
  ua=UA, [UA]="ua",
  tf=TF, [TF]="tf",
  bb=BB, [BB]="bb",
  mc=MC, [MC]="mc",
  se=SE, [SE]="se",
}

-- Where did a card come from? Where is it now?
-- This is all relative to the player involved.
-- S_PLAYER_DECK is the location of their deck,
-- other players' decks are S_UNKNOWN.
S_HAND = "hand"
S_TRADE = "trade deck"
S_DISCARD = "discard zone"
S_PLAYER_DECK = "player deck"
S_PLAYER_DISCARD = "player discard pile"
S_SCRAP = "scrap"
S_EXPLORER = "explorer pile"
S_PLAY = "in play (ship)"
S_PLAYER = "in play (your area)"
S_AUTO = "auto-play"
S_UNKNOWN = "unknown"

-- Destinations: When cards are purchased, where do they go?
TO_DISCARD = "to discard"
TO_TOP = "to top of deck"
TO_HAND = "to hand"
TO_PLAY = "to play"
TO_SCRAP = "to scrap"

