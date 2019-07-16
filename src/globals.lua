-- Default options. Uh, these aren't going to be very useful since the json
-- saves are distributed with save states? Overridden by the start menu,
-- unless there is a VERSION mismatch.
MENU_CHOICES = {
  decks = {
    ["Core"] = 1,
  },
  houserules = {
    ["Free for All"] = true,
  },
  gameopts = {},
}

-- Overridden on load or start, with a copy of GAMESTATE_CLEAN (in constants)
GAMESTATE = nil

-- QUESTIONs are the UI dialogs during games: pick a selected card,
-- pick a target opponent, or choose a card effect, etc.
--
-- QUESTION_CHECKS ensure we don't somehow accidentally ask the
-- same question twice.
CURRENT_QUESTION = {}
QUESTIONS = {}
QUESTION_CHECKS = {}

HOUSE_RULES = {}

-- qdo serializes the game's events so not everything is happening at once.
-- QWAITON is a group of gwaits that need to finish before we do the next thing.
-- QLIST is a list of upcoming events triggered by players.
-- green* adds anything with qwait=true (default) to block qdo.
-- Anything queued by the current qdoing is inserted in front of the QLIST ...
-- AFTER QDOING is done.
QLIST = {}
QWAITID = 1
QWAITON = {}
QOK = true

-- A list of all greenWait()s currently active.
GREEN_WAITS = {}

-- CARDSTATES and PICKINGS are set in onObjectPickUp and cleared
-- in onObjectDrop. CARDSTATES for returning the object to where
-- it's supposed to be, PICKINGS to track the fake "clicks". They
-- will probably be combined into one eventually.
CARDSTATES = {}
PICKINGS = {}
-- Decks that players are currently searching, for
-- discard-to-scrap use.
SEARCHING = {}

