--[[ qdo and green wait

  This file contains two things:
    Implementation of the greenWait "green threads"
    Implementation of qdo, the player+game event queue.

  greenWait:
    Unlike some of the features of Wait.*, greenWait is entirely asynchronous.
    It is checked on every onUpdate() tick.

    greenWait({
      name = "waitforguid", -- For debugging.
      [qwait] = true, -- If the next qdo() should wait until this is completed.
      [time] = 4.4, -- wait 4.4 seconds.
      [frames] = 20, - wait 20 frames
      [condition] = function() return true end, -- checked every frame.
      [count] = 5, -- run 5 times.
      callback = function() ... end, what to run.
    })

    At least one of time, frames or condition must be added. If qwait is true,
    then count cannot be anything other than 1 (or nil, defaults 1)

  QDO:
    Thanks to TTS's spawning, movement, and sometimes inconsistent availability
    of callbacks, we can't depend on everything happening in a timely order.

    Enter qdo. qdo(func, ...) queues func() to be called only after everything
    that was qdo()'d before it is done. And qdo events are popped from the
    queue only if there are no waits or callbacks.

    `qWaitFor("name", func)` is a wrapper for callbacks. If we need to ensure
    something happens before the next qdo()'d function, wrap it in qWaitFor().
    "name" is purely for debugging issues - if it hangs for a while, then we'll
    complain about it.

    If there is no callback function available, first facepalm at TTS, then use
    `waitUntilSettled([callback])` (callback optional. If not provided, it just
    delays qdo until things are "settled")

    waitUntilSettled uses areAllSettled(), which checks to ensure nothing in
    the game is either spawning, or smoothMoving. It doesn't check resting, as
    that can take a long time for some objects, so areAllSettled trusts that
    once things are smoothMoved where they're going, we're good to play.

    isQOK() - returns true if qdo queue is empty and there are no pending qWaitFor
    callbacks to finish.

    updatePlayState() is defined here, as it is now just a request to the qdo
    list to perform an update when things are mostly settled.

  IMPLICATIONS OF QDO:

    One fairly major result of qdo's implementation: We can't guarantee that
    the state assumed at time of qdo is still valid when it is popped.

    As an example: qdo(playCard) qdo(endTurn) qdo(tryAttacking) -
      qdo(playCard) is executed, and endTurn and tryAttacking are queued.
      At the time of queueing, turn isn't yet ended, so tryAttacking might
      seem valid (it's player's turn, they have targets). But endTurn will
      make that state invalid for tryAttacking.

    Everything should check state after qdo, or use qdoIfTurn().

    qdoIfTurn(color, name, func, ...) - on remove from queue, only execute
    if it's currently color's turn.

  waitForGUID(obj, func) - immediately after spawning, object might not have
  a GUID. Wait until it does, then execute func.
]]--

function areAllSettled()
  local ignore_wait = {
    ["3D Text"] = true,
  }
  for _, obj in ipairs(getAllObjects()) do
    if not ignore_wait[obj.tag] then
      if obj.spawning then
        return false
      end
      if obj.isSmoothMoving() then
        return false
      end
    end
  end
  return true
end

-- QWAITON is a group of gwaits that need to finish before we do the next thing.
-- QLIST is a list of upcoming events triggered by players.
-- green* adds anything with qwait=true (default) to block qdo.
-- Anything queued by the current qdoing is inserted in front of the QLIST ...
-- AFTER QDOING is done.

function isQOK()
  return QOK and not hasAny(QWAITON) and not hasAny(CURRENT_QUESTION) and QDOUPDATE < 1
end

function qCleanup()
  QLIST = {}
  QWAITID = 1
  QWAITON = {}
  QOK = true
end

function qdoTick()
  local now = Time.time
  for qid, gwait in pairs(QWAITON) do
    if (now - gwait["ts"]) > 3.0 then
      printf("QWAITON stuck? Waiting for %s for %d seconds",
             gwait["name"],
             math.floor(now - gwait["ts"]))
    end
  end
end

function qWaitFor(name, fnc)
  -- We force tostring so we don't accidentally have
  -- lua creating massive arrays when QWAITID gets too high.
  local qid = tostring(QWAITID)

  QWAITON[qid] = {
    name = name,
    ts = Time.time
  }
  QWAITID = QWAITID + 1

  if fnc then
    return function(...)
      fnc(...)
      QWAITON[qid] = nil
    end
  else
    return function()
      QWAITON[qid] = nil
    end
  end
end

function qdo(func, ...)
  local qitem = {
    func = func,
    args = {...},
    n = select('#', ...),
    ts = Time.time,
  }
  QOK = false
  table.insert(QLIST, qitem)
end

QDOUPDATE = 0
function updatePlayState()
  updatePlayStateNow(false)
end

function qdopop()
  if GAMESTATE["state"] ~= RUNNING and GAMESTATE["state"] ~= STARTING then
    return
  end
  if isQOK() then
    die("qdopop while QOK?")
    return
  end
  if hasAny(QWAITON) then return end
  if #QLIST > 0 then
    local qitem = table.remove(QLIST, 1)
    safecall(function()
      qitem["func"](unpack(qitem["args"], 1, qitem["n"]))
      QDOUPDATE = 3
    end)
    return
  end
  -- We also check QWAITON after we call the qdo, in case it adds more waits.
  if #QLIST > 0 then return end
  if hasAny(QWAITON) then return end
  if areAllSettled() and QDOUPDATE < 1 then
    for qid, gwait in pairs(QWAITON) do
      die("QWAITON while QOK??")
    end
    QOK = true
    if isQOK() then
      checkGameSanity()
    end
  end
end

function greenRunTick(gwait)
  if gwait["framesLeft"] > 0 then
    gwait["framesLeft"] = gwait["framesLeft"] - 1
    if gwait["framesLeft"] > 0 then
      return false
    end
  end
  if gwait["stime"] > Time.time then
    return false
  end
  if gwait["condition"] and not gwait["condition"]() then
    return false
  end
  return true
end

-- GREEN_WAITS = {}
function greenTick()
  if QDOUPDATE > 0 then
    QDOUPDATE = QDOUPDATE - 1
    if QDOUPDATE == 0 then
      updatePlayStateNow(true)
    end
  end
  if not QOK and areAllSettled() then
    qdopop()
  end
  if #GREEN_WAITS < 1 then return end
  local newwait = {}
  for _, gwait in ipairs(GREEN_WAITS) do
    if greenRunTick(gwait) then
      if not safecall(gwait["callback"]) then return end
      if not gwait["qid"] then
        if gwait["count"] ~= 0 then
          greenWaitQueue(newwait, gwait)
        end
      end
    else
      table.insert(newwait, gwait)
    end
  end
  GREEN_WAITS = newwait
end

function greenWaitQueue(queue, gwait)
  if gwait["count"] > 0 then
    gwait["count"] = gwait["count"] - 1
  end
  gwait["framesLeft"] = gwait["frames"] or 0
  gwait["stime"] = gwait["stime"] + gwait["time"]
  table.insert(queue, gwait)
end

function greenWait(args)
  local good = false
  for _, arg in ipairs({"condition", "time", "frames"}) do
    good = true
  end

  if args["count"] and args["count"] ~= 1 and args["qwait"] then
    whine("greenWait qwait + count: booo!")
    good = false
  end
  if args["qwait"] and isQOK() then
    die("qwait %s with QOK?", args["name"])
    return
  end

  if args["count"] ~= nil and args["count"] ~= 1 then
    good = false
    for _, arg in ipairs({"time", "frames"}) do
      good = true
    end
  end
  if not args["callback"] then whine("greenWait needs a callback") return end
  if not good then
    die("greenWait misused?")
    return
  end

  local gwait = {
    name = args["name"] or "No name?",
    stime = Time.time,
    count = args["count"] or 1,
    time = args["time"] or 0.0,
    frames = args["frames"] or 0,
    condition = args["condition"],
    callback = args["callback"],
    ts = Time.time,
    args = args,
  }

  if args["qwait"] == true then
    gwait["callback"] = qWaitFor(gwait["name"], gwait["callback"])
  end

  greenWaitQueue(GREEN_WAITS, gwait)
end

function waitForGUID(obj, cb)
  local ocheck = function()
    return obj.getGUID() ~= nil and obj.getGUID() ~= ""
  end
  if ocheck() then
    cb(obj)
    return
  end
  greenWait({
    name = "waitforguid",
    qwait = true,
    condition = ocheck,
    callback = function() cb(obj) end,
  })
end

function dummyCallback() end

function waitUntilSettled(callback)
  -- "arg" is a hidden parameter from '...''
  greenWait({
    name = "waituntilsettled",
    qwait = true,
    frames = 3, -- to let anthing spawning start.
    condition = areAllSettled,
    callback = callback or dummyCallback,
  })
end

function onUpdate()
  greenTick()
end

