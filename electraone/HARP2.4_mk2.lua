-- Arpeggiator
-- Pattern (ref 2) is 14 modes: Up, Down, Up/Down, Up/Down Rpt Ends, Up -8ve,
-- Down -8ve, Up/Down -8ve, UpDwn Rpt -8ve, Step Up, Step Down, Random,
-- Random2, Random3, As Played - see PATTERN_* below (named Alt/Alt2
-- internally, for "alternating") and orderedNotes()/advanceStep() for what
-- each does.
-- References: 1 Tempo, 2 Pattern; 3/4/5 source iface/port/chan; 6/7/8 dest iface/port/chan;
--             9 Latch, 10 Octaves, 11 Gate Length, 12 Swing,
--             13 Sync Rate, 16 Chance,
--             59 ARP VEL - 0 plays each step at the velocity it was struck
--             with (the old, only behaviour); 1-127 overrides every step to
--             that fixed velocity instead, before Accent or Groove ever see
--             it - so with an override set, Accent and Groove vary around a
--             constant baseline instead of around however hard each key
--             happened to be hit. See the velocity line in advanceStep()
--             below.
--             66/67 Groove Template/Amount - a 16-step feel template, one
--             of fourteen (Straight, Shuffle, Lazy, Push, Halftime, Clave,
--             Trance Gate, Waltz Lilt, Afrobeat, Glitch Stutter, Reggae
--             Skank, Breakbeat Roll, Dilla Bounce, Samba Push - see the
--             `grooves` table below for what each one does and why) that
--             nudges each step's timing,
--             velocity and gate length; Amount (-120..120%) crossfades from
--             dead straight (0, the default) to the template's own numbers
--             in full (100), continuing on past 100 up to 120 to exaggerate
--             the template's own accents/gate shaping beyond its authored
--             extremes, and inverting the template below 0 - a negative
--             Amount makes a step the template quietens louder and a step
--             it shortens longer, AND genuinely rushes the beat rather than
--             sitting on the grid: see the comment above grooveValuesAt()
--             below for how a negative offset is realised by delaying the
--             PRECEDING step instead, the same trick Swing (ref 12) uses
--             for its own negative values. Independent of, and additive
--             with, Swing - a fixed delay on every second step only.
--             57/58 Euclid Length/Pulses - a deterministic rhythmic gate, an
--             alternative/supplement to Chance, usable together with it (see
--             euclidGateHit() below). Defaults (16/16) are "every step is an
--             onset" - no gating - so the arp is unaffected until Pulses is
--             brought below Length.
--             63/64/65 Accent Length/Pulses/Amount% - a second, independent
--             Euclidean pattern built with the exact same generator as the
--             gate, but boosting velocity on a hit instead of muting it.
--             Amount defaults to 0%, which keeps the arp unaffected
--             whatever Length/Pulses are set to - see the Accent comment in
--             advanceStep() below. Both generators place their first onset
--             on step 1 (euclidPattern() is built so pulses=1 always reads
--             as "accent/gate the 1", the conventional way a Euclidean
--             rhythm is written - E(1,4) = X..., E(3,8) = X..X..X.).
--             18 Transpose Octave, 19 Transpose Semitone, 29 Arp On/Off, 32 Arp Reset,
--             33 Tonic, 34 Scale Shape, 27 Mode, 36 Shape, 37 Harmony Mode, 40 Inversion
--             (Shape mode only - see applyInversion() below), 53 HOLD (see onHoldChange
--             below - keeps a directly-sounding Shape/SATB chord ringing
--             after the key is released; mutually exclusive with the arp).
--             60/61 Min/Max Note (Config page, keyboard split). 15 RETRIGGER (Legato/
--             Retrigger - see regenerateShapeNotes()/retriggerOnShapeChange() below).
--             22 SHAPE UPDATE (Config page; Immediate/On Next Chord - see
--             shapeUpdateIsImmediate() below: gates whether regenerateShapeNotes() runs
--             when Shape/Inversion or Root Degree/Cantus Primus/Position change under a
--             chord already sounding. Always visible, unlike Shape's/SATB's own params).
--             71 STRUM RAMP - a bipolar velocity crescendo/decrescendo across a
--             strummed chord's notes, on top of Strum Time/Direction - see
--             STRUM_RAMP_REF below. 72 STRUM ACCEL - a bipolar timing
--             curve across the same notes, independent of STRUM RAMP -
--             see STRUM_ACCEL_REF/strumTimingFraction() below. 73 ACCEL
--             CURVE (Config page) - how strongly 100% Accel warps the
--             timing; see STRUM_ACCEL_CURVE_REF below. 75 STRUM JITTER
--             (Config page) - a random +/- nudge on every strummed
--             note's delay, 0 = off; see STRUM_JITTER_REF below. 76 STRUM
--             GATE / 77 STRUM GATE TAPER (Config page) - a gate-length
--             taper across a strummed chord's notes, a later-struck note
--             getting progressively less ring time than the first, the
--             way a strumming hand's own motion keeps damping what it
--             already played; see STRUM_GATE_REF below. 78 HARMONY
--             KEYBOARD (Harmony page, top row, spanning down through the
--             next two) - a read-only on-screen piano highlighting every
--             note the harmony engine currently has sounding or pooled
--             (plain passthrough, a generated Shape/SATB chord, or a
--             strummed set alike); see HARMONY_KEYBOARD_REF below. It
--             sits in the top rows of the Harmony page, with the rest of
--             this page's own controls (Harmony Mode, Shape, SATB,
--             Strum, ...) beneath it.
--
-- Tonic (ref 33) is a 25-item list, C to C to C (two octaves of pitch class,
-- -12..+12), centred on the middle C (value 0, the default) rather than the
-- old 12-item C..B - so turning the knob down from C reaches B, A#, ... in
-- one step each, exactly as turning it up reaches C#, D, ..., instead of
-- needing 11 turns to go "down" to B the long way round through C#. Every
-- reader of cfgList(33) (nearestScaleMatch's `(note - tonic) % 12`) is
-- insensitive to a Tonic value 12 apart, so C at -12, 0 and +12 are musically
-- identical; only which one is nearest the knob's current position differs.
--
-- Harmony Mode (ref 37) is Off, hape or SATB, and decides what a struck key 
-- turns into for the ARP ITSELF - not a separate tool.
--
-- SATB (refs 50/51/52: ROOT DEGREE, CANTUS PRIMUS, POSITION) builds a
-- common-practice four-part harmonization. ROOT DEGREE does NOT pick one
-- fixed chord every note gets forced onto - it names the ROLE the struck
-- note plays in its OWN chord (I: the note is the root; III: the note is
-- the third, so the actual root is found two scale-steps below it; and so
-- on - see satbChordForNote()), so walking a scale produces a different,
-- diatonically correct chord quality for every note, the same way
-- Shape's Triad already varies by scale degree. The note is assigned
-- exactly to the voice CANTUS PRIMUS names, and the other three voices
-- are filled in by POSITION: Closed or Open (satbClosedOrOpen() - Soprano
-- is worked out from whichever voice Cantus Primus actually names, so the
-- struck note is transposed into place as that voice, then Alto/Tenor/Bass
-- stack below it as always), or one of four Tintinnabuli-style positions
-- after Arvo Part (satbTintinnabuli() - the same idea, generalized from
-- Alto instead of Soprano since that is Tintinnabuli's own reference
-- voice). Either way changing Cantus Primus genuinely changes the pitches
-- sent, not just which voice label is attached to them. SATB plugs
-- into the exact
-- same output machinery as Shape - joins the arp's pool when the arp is
-- on, sounds directly (through Strum Time if set) when it is off, and
-- shares Note Priority so one held key sounds at a time.
--
-- Tonic/Mode/Scale Shape are not Shape-specific - the plain arp quantizes
-- every step through them too (see quantizeToScale() below) - so they
-- stay visible under every Harmony Mode, Off included. Only Shape's own
-- two (Shape, Inversion) and SATB's three (Root Degree/Cantus
-- Primus/Position) are shown/hidden by mode: Off hides both groups,
-- Shape shows its two and hides SATB's three, SATB shows its three and
-- hides Shape's two. See updateChordParamVisibility() below.
--
--   Off   - the arp sees exactly the notes you hold, same as always. Play
--           a Cmaj7 yourself (C E G B) and the arp arpeggiates those four.
--   Shape - every key you strike is expanded, the moment it goes down,
--           into the selected Shape's full set of notes - NOT by
--           transposing the shape's semitone intervals onto the raw key,
--           but by snapping the key to the nearest tone of the current
--           Tonic/Scale Shape/Mode and then stacking the shape's degrees (1st,
--           3rd, 5th, ...) from THAT scale position (see notesForKey(),
--           scaleStepOffset() and nearestScaleMatch() below). This means
--           the chord's quality follows the scale, not just its root: with
--           Tonic C / Scale Shape Major / Shape "Seventh", striking C gives Cmaj7
--           (the I chord), but striking D gives Dm7, not Dmaj7 - D is the
--           2nd degree of C major, and the diatonic seventh chord on a
--           major scale's 2nd degree is minor, exactly as a chord built by
--           hand in that key would be. Changing Tonic or Scale Shape only affects
--           the NEXT struck key, not one already sounding - unlike Shape or
--           Inversion changing (see regenerateShapeNotes()), nothing
--           re-reads Key/Scale for a note already in the pool. The arp
--           then arpeggiates the generated set, not the one key. See
--           addGeneratedNotes() and removeGeneratedNotes() below for how a
--           physical key's generated notes are tracked so releasing it
--           releases exactly what it added, even when two struck keys
--           generate an overlapping pitch between them.
--
-- Tonic/Scale Shape is a quantizer shared by the arp and the degree numbers Shape
-- reads: every note the arp is about to send is snapped to the nearest
-- note of the chosen scale, rooted on Tonic, before it goes out - see
-- SCALE_OFFSETS and quantizeToScale() below. Scale Shape "Chromatic" (the
-- default) allows every note, i.e. quantizes nothing.
--             (14, 15 and 17 are group labels added in the editor - not controls this script reads.)

-- Every table that tracks what is currently held or sounding - the raw
-- key state and the Shape/SATB "active key" bookkeeping alike - lives on
-- this one Notes table, rather than another half-dozen top-level locals.
-- Same reasoning as the `Ref` table above.
local Notes = {}
Notes.held = {}                      -- note -> velocity, the notes being arpeggiated
Notes.pressOrder = {}                -- notes in the order pressed ("As Played")
Notes.keysDown = {}                  -- note -> true, the keys physically held (for latch)
Notes.noteRefCount = {}              -- generated note -> how many struck keys currently contribute it
Notes.keyGeneratedNotes = {}         -- struck note -> { generated note numbers... } it added to `Notes.held`
Notes.keyVelocity = {}               -- struck note -> the velocity it was struck with, for regenerating later
-- Everything about where the arp is in its various cycles - which step,
-- which direction, the Euclid/Accent/Groove cycle positions, the note
-- currently sounding and its gate timer, and swing parity - lives on this
-- one ArpState table, rather than another half-dozen top-level locals.
-- Same reasoning as the `Ref` table above.
local ArpState = {}
ArpState.stepIndex, ArpState.direction = 0, 1
ArpState.euclidStep = 0              -- position in the Euclid Gate cycle (refs 57/58),
                                      -- independent of stepIndex - reset alongside it
ArpState.accentStep = 0              -- position in the Accent cycle (refs 63/64), likewise
                                      -- independent of stepIndex and of euclidStep - its own
                                      -- Length/Pulses can differ from the gate's entirely
ArpState.grooveStep = 0              -- position in the Groove cycle (refs 66/67), its own
                                      -- 16-step loop, independent of stepIndex/euclidStep/
                                      -- accentStep - see grooveValuesAt() below
ArpState.currentNote = nil           -- the one note sounding on the destination
ArpState.gateHandle = nil            -- schedule.after handle for the gate-off
ArpState.swingParity = 0             -- 0 = on-beat step, 1 = off-beat step
ArpState.nextDueAt = nil             -- Internal clock only: the schedule.now()-space
                                      -- absolute time the NEXT step is due. Advanced by
                                      -- exactly basePeriodMs() every real step, independent
                                      -- of when the polling timer tick that notices it
                                      -- actually runs - see the comment above ARP_POLL_MS.

-- The arp's own timer runs on the application thread (preset-lua reference
-- section 4/20) and is exactly the kind of clock the firmware itself warns
-- against trusting for precise output: "timer... may experience delays...
-- should be used for activities that may experience jitter and for
-- backwards compatibility. Look at transport clock related functions and
-- midi event scheduling (the `at` function)... decouple UI from the MIDI
-- messaging." Those are already how this file drives the downstream clock
-- OUTPUT (transport.enableClock()/startClock(), the real MIDI schedule
-- thread, see Clock.startOutput() below) and how Swing/Groove/Strum delay
-- a note (midi.at()). The arp's own STEP cadence used not to follow that
-- rule: it polled once per step on the timer and sent the note
-- synchronously from inside that callback, so the note's real-world
-- timing was only ever as good as that one tick's own jitter.
--
-- ARP_POLL_MS decouples the two: the timer now polls far faster than any
-- musical step is ever likely to be, and a step is only actually fired
-- once schedule.now() is within ARP_LOOKAHEAD_MS of its own precise,
-- independently-advancing due time (ArpState.nextDueAt) - at which point
-- its note-on is scheduled with midi.at(dueAt) (see advanceStep()'s
-- `dueAt` parameter), handing the real send to the MIDI schedule thread
-- instead of to whatever moment this poll happened to run. A poll that
-- finds nothing due yet does nothing. ARP_LOOKAHEAD_MS is kept comfortably
-- above ARP_POLL_MS so a due step is never missed between two polls.
--
-- Trade-off, disclosed rather than hidden: this makes `timer.onTick()`
-- itself no longer "one call always advances exactly one step" - a poll
-- that finds nothing due yet fires nothing. The project's own debugTick()
-- (further down) is redefined to force a step unconditionally, exactly as
-- it always did, so manual/debug stepping is unaffected; the firmware's
-- own test.tick(), which calls timer.onTick() directly, now inherits the
-- same real-clock gating a real instrument has, rather than a fixed
-- one-call-one-step simulation.
-- Measured on the instrument: a 10 ms poll (100 Hz) logged "timer.onTick
-- ... is in trouble ... 19.3% of the run loop, 4 ticks too late, 2 could
-- not get into the script". 20 ms (50 Hz, the fast end of the reference's
-- own "33 to 50 a second is comfortable", preset-lua 20.4) still logged
-- the same warning, accumulating "too late" ticks over time rather than
-- settling - this controller does not have headroom for a lookahead poll
-- that fast while connected and being probed. 30 ms (33 Hz, the slow end
-- of that range) is where it stopped.
local ARP_POLL_MS = 30        -- the Internal timer's own period - still
                               -- far faster than any real step length,
                               -- and cheap since a poll that finds nothing
                               -- due does no painting and no MIDI at all
local ARP_LOOKAHEAD_MS = 35   -- a step is fired once it is this close to
                               -- due; kept a little above ARP_POLL_MS so
                               -- none is ever skipped between two polls

-- CLOCK SRC (ref 42, I/O Config page): Internal (the timer, driven by TEMPO
-- ref 1 and SYNC ref 13 as always) or External (incoming MIDI clock on the
-- arp's own source route - cfgList(3)/cfgList(4), interface/port only;
-- clock has no channel). External ignores TEMPO outright - the step rate
-- comes from counting clock pulses against SYNC's beat value instead of
-- from basePeriodMs() - and Internal ignores incoming clock. Switching
-- between the two stops whatever is sounding and resets the step position,
-- the same as any other routing change here (recipe 33.13).
--
-- Everything clock-related - the Internal/External constants, the pulse
-- counter and the routing functions - lives on this one Clock table,
-- rather than another half-dozen top-level locals. Same reasoning as the
-- `Ref` table above.
local Clock = {}
Clock.INTERNAL, Clock.EXTERNAL = 0, 1
Clock.OFF = 3   -- CLOCK OUT IFACE's own "Off" item - see Clock.outputEnabled() below

-- Every control's reference number lives here, in one table, rather than as
-- scores of separate top-level locals - the Lua compiler caps a single
-- chunk's local-variable registers at 200 (see the comment above `Disp`
-- further down, where the same trick was first applied in this file), and
-- this file was close enough to that ceiling to apply it everywhere a
-- cluster of plain numeric ref constants existed. Pure bookkeeping: every
-- field here is exactly the number the old same-named CONST_REF local held;
-- nothing about how any of them is read changes.
local Ref = {
  CLOCK_SRC         = 42,  -- CLOCK SRC (Config page)
  CLOCK_IFACE       = 54,  -- CLOCK IFACE: the clock's own route, independent of
  CLOCK_PORT        = 55,  -- the note source (3/4) - a footswitch/clock box is
                           -- commonly on a different port from the keyboard.
  CLOCK_OUT_IFACE   = 74,  -- CLOCK OUT IFACE (Config page)
  CLOCK_OUT_PORT    = 81,  -- CLOCK OUT PORT (Config page)
  CLOCK_MONITOR     = 86,  -- CLOCK MONITOR (Config page)
  SHAPE_UPDATE      = 22,  -- SHAPE UPDATE (Config page)
  VOICE_SPLIT       = 80,  -- VOICE SPLIT (Harmony page)
  STRUM_RAMP        = 71,  -- STRUM RAMP (Harmony page)
  STRUM_ACCEL       = 72,  -- STRUM ACCEL (Harmony page)
  STRUM_ACCEL_CURVE = 73,  -- ACCEL CURVE (Config page)
  STRUM_JITTER      = 75,  -- STRUM JITTER (Config page)
  STRUM_GATE        = 76,  -- STRUM GATE (Config page)
  STRUM_GATE_TAPER  = 77,  -- STRUM GATE TAPER (Config page)
  HARMONY_KEYBOARD  = 78,  -- HARMONY KEYBOARD (Harmony page)
  HOLD_MODE         = 79,  -- HOLD MODE (Config page)
  GROOVE_AMOUNT     = 67,  -- GROOVE AMT (ARP page)
  GROOVE_TEMPLATE   = 68,  -- GROOVE (ARP page)
  ARP_VELOCITY      = 59,  -- ARP VEL (ARP page)
  CLOCK_OUT_ENABLE  = 150, -- CLOCK OUT ENABLE (Config page) - master on/off for
                           -- sending Start/Stop/Clock to downstream gear at all,
                           -- independent of CLOCK OUT IFACE/PORT's own route.
                           -- Default off: starting the arp must NOT nudge a
                           -- downstream device's transport unless this is
                           -- explicitly turned on. See Clock.outputEnabled().
}

-- This preset's layouts (mk2-6x6 built first, mini-4x2 built later) place
-- the SAME logical control under two different numeric references - the
-- editor will not let two tiles share a reference, so the Mini layout's
-- copies are declared ref+300. Every control lookup in this file goes
-- through rc() (or cfgList()/cfgValue(), which call it) so one script runs
-- unmodified on either device: resolveOffset() asks whether the mk2
-- reference exists and picks 0 or 300 once, the first time anything is
-- looked up, then every call just adds that offset - read paths
-- (cfgList/cfgValue) and write/paint paths (rc()) are therefore identical
-- whichever device loaded the preset. A control not yet declared on a
-- given device (e.g. a Mini page not built yet) still raises exactly as a
-- bad reference always has - this only removes the device/reference
-- mismatch, not a genuinely missing control.
local ModelOffset = nil

local function resolveOffset()
  if ModelOffset == nil then
    local ok = pcall(controls.get, 34)   -- SCALE SHAPE: on the Harmony page of every device built so far
    ModelOffset = ok and 0 or 300
  end
  return ModelOffset
end

local function rc(ref)
  return controls.get(ref + resolveOffset())
end

-- Harmony <-> Arp page shortcut: pressing the knob switch under the
-- HARMONY KEYBOARD (Harmony page, top row) jumps to the Arp section's
-- first page; pressing the switch under ARP STEP DISPLAY (Arp page, top
-- row) jumps back. Page numbers differ by device - mk2 keeps Harmony and
-- Arp as pages 1/2; Mini splits each section across several numbered
-- sub-pages, so its Harmony/Arp each start at page 1/3 - resolveOffset()
-- already tells us which device loaded. Only Mini and keyboard knobs have
-- a push-switch to press at all (control-package reference 5): on mk2
-- this callback is harmlessly attached and simply never fires.
local function hopToArpPage()
  pages.display((resolveOffset() == 0) and 2 or 3)
end

local function hopToHarmonyPage()
  pages.display(1)
end

-- A second shortcut, same two controls: knob 3's switch jumps straight to
-- Config and stops there (no return leg the way knob 4's Harmony<->Arp
-- toggle has - "terminating there", not another toggle). mk2's Config is
-- one page (3); Mini splits it into several numbered sub-pages, so its
-- shortcut lands on the first of them (7, "CONFIG 1").
local function hopToConfigPage()
  pages.display((resolveOffset() == 0) and 3 or 7)
end

-- Both controls now carry THREE pot inputs for the same single value
-- ("value") - knob 4 (potId 4) for the Harmony<->Arp toggle, knob 3
-- (potId 3) for the Config shortcut, knob 2 (potId 2) for PANIC (see
-- onPanic() further down - the same function the standalone PANIC pad
-- used to call) - so one switch callback on each has to tell the three
-- knobs apart. event.id is the PotEvent's own id, zero based (the one pot
-- id in this API that counts from zero - preset-lua reference 5.9/9.8), so
-- physical knob 2 arrives as id 1, knob 3 as id 2, knob 4 as id 3.
-- onPanic() itself is declared later in the file (it is a value function,
-- wired to the PANIC pad's own control for mk2 and for any device that
-- still carries one); called directly here with a synthetic "pressed"
-- value exactly as that pad's own press would.
local function onHarmonyKeyboardSwitch(control, event)
  if event.type ~= 1 then return end   -- 1 pressed, 3 released - act on press only
  if event.id == 3 then
    hopToArpPage()
  elseif event.id == 2 then
    hopToConfigPage()
  elseif event.id == 1 then
    onPanic(nil, 1)
  end
end

local function onArpStepDisplaySwitch(control, event)
  if event.type ~= 1 then return end
  if event.id == 3 then
    hopToHarmonyPage()
  elseif event.id == 2 then
    hopToConfigPage()
  elseif event.id == 1 then
    onPanic(nil, 1)
  end
end

-- A handful of config reads (destination route, Arp On/Off, external switch
-- route, Shape Update mode, clock source...) are read from Harmony-page
-- functions even before the Arp/Config pages exist on a device this preset
-- is only partly ported to (the Mini today). rcOrNil() is the tolerant
-- cousin of rc(): nil instead of a raise when the control is not there yet,
-- so cfgList()/cfgValue()/isArpOn() can fall back to a safe default (0 /
-- off) rather than taking the whole calling function down. Once a page is
-- actually built on that device this is never reached - controls.get()
-- finds the real control, same as rc().
local function rcOrNil(ref)
  local ok, c = pcall(controls.get, ref + resolveOffset())
  if ok then return c end
  return nil
end

-- CLOCK OUT IFACE/PORT (refs 74/81, Config page): where this preset sends
-- MIDI clock OUT, so it can act as the master clock for the rest of a rig -
-- or simply relay an incoming external clock on to a second device. Two
-- entirely different mechanisms depending on CLOCK SRC (ref 42):
--   Internal - transport.enableClock()/setClockOutputs() generate a real
--     24 PPQN clock off the controller's own MIDI schedule thread, tempo-
--     locked to TEMPO (ref 1), started/stopped alongside ARP ON/OFF (see
--     startClockOutput()/stopClockOutput(), called from onArpToggle below).
--   External - nothing is generated; each incoming clock/Start/Stop/
--     Continue on the clock's OWN route (CLOCK IFACE/PORT, not the note
--     source) is simply relayed to CLOCK OUT IFACE/PORT as it arrives (see
--     midi.onClock/onStart/onStop/onContinue below) - a clock repeater,
--     independent of whether this preset's own arp happens to be running.
Clock.extCount = 0              -- MIDI clock pulses (24 PPQN) seen since the last step
Clock.pendingTimingApply = false -- a SYNC/TEMPO change armed at the control's touch end,
                                  -- committed only at the next step boundary - see
                                  -- Clock.commitTimingIfPending() below
Clock.currentTicksPerStep = nil  -- the committed pulses-per-step for External stepping,
                                  -- refreshed only at a step boundary, never mid-step

-- Forward declared: isArpOn() is defined near the bottom (by the Arp
-- On/Off control's own section) but addGeneratedNotes()/removeGeneratedNotes()/
-- regenerateShapeNotes(), much higher up, need to call it to decide whether
-- a Shape-mode key should sound its generated chord directly (no arp
-- running to arpeggiate it) or just join the arp's held-notes pool (arp
-- running, current behaviour unchanged).
local isArpOn

-- Note priority (ref 49): which physically-held key drives the sounding
-- chord when more than one is down at once. Last: whichever was struck
-- most recently (the usual mono-synth behaviour); Highest/Lowest: whichever
-- of the currently-held keys is pitched highest/lowest, regardless of
-- press order. Whichever key "wins" sounds the chord; the others are held
-- in reserve and take over, retriggering, if the winner is released while
-- they are still down - see activeShapeNote() below.
local CHORD_PRIORITY_LAST, CHORD_PRIORITY_HIGHEST, CHORD_PRIORITY_LOWEST = 0, 1, 2

-- Pattern list, in the order the control shows them. One table, not 14
-- separate top-level locals - see the comment above the `Ref` table for why
-- (the same register-pressure reasoning applies here).
local Pattern = {
  UP        = 0,
  DOWN      = 1,
  ALT       = 2,   -- bounces up/down, does not repeat the end notes
  ALT2      = 3,   -- bounces up/down, repeats the end notes
  UP_8VE    = 4,
  DOWN_8VE  = 5,
  ALT_8VE   = 6,
  ALT2_8VE  = 7,
  STEP_UP   = 8,
  STEP_DOWN = 9,
  RANDOM    = 10,
  RANDOM2   = 11,  -- random, never the same note twice running
  RANDOM3   = 12,  -- a shuffled permutation, reshuffled each pass
  ASPLAYED  = 13,
}

-- Random3's state: a shuffled permutation of note indices, and where in it
-- the next step reads from. Rebuilt whenever it runs out or the note count
-- changes under it.
ArpState.shuffledOrder = nil
ArpState.shuffledPos = 1

local LATCH_OFF, LATCH_NORMAL, LATCH_CHORD = 0, 1, 2
local HARMONY_MODE_OFF, HARMONY_MODE_SHAPE, HARMONY_MODE_SATB = 0, 1, 2

-- SHAPE UPDATE (ref 22): whether changing Shape/Inversion (Shape mode) or
-- Root Degree/Cantus Primus/Position (SATB mode) while a chord is already
-- sounding updates it on the spot (Immediate, the default and the old,
-- only behaviour) or leaves it ringing exactly as it was until the next
-- struck key builds a fresh chord (On Next Chord). Either way a freshly
-- struck key always uses whatever the controls say right now - this only
-- changes whether an ALREADY-sounding chord is brought up to date too.
-- Read live, like every other config value here. (shapeUpdateIsImmediate()
-- itself is defined below, once cfgList() exists.)
local SHAPE_UPDATE_IMMEDIATE, SHAPE_UPDATE_NEXT_CHORD = 0, 1
-- It now lives on the Config page (moved there in the editor), so it is
-- always visible, like every other Config control - not shown/hidden with
-- Harmony Mode the way Shape's and SATB's own params are.

-- The controls that only make sense under one Harmony Mode or the other -
-- shown/hidden together by updateChordParamVisibility() below, so the
-- grid only ever shows parameters the current mode actually reads.
-- Key/Scale Mode/Scale are NOT Shape-specific - they are the quantizer the
-- plain arp uses too (see the comment on quantizeToScale() above) AND the
-- degree numbers both Shape and SATB read, so they stay visible always,
-- regardless of Harmony Mode. Only Shape and Inversion are Shape-only.
local ALWAYS_VISIBLE_REFS = { 34 }               -- Scale. Key and Mode's own visibility
                                                  -- depend on the scale - see rebuildModeOverlay())
local SHAPE_PARAM_REFS    = { 36, 40 }           -- Shape, Inversion
local SATB_PARAM_REFS     = { 50, 51, 52 }       -- Root Degree, Cantus Primus, Position
local CHORD_PARAM_REFS    = { 80 }               -- VOICE SPLIT - meaningful under either chord
                                                  -- engine (Shape or SATB), pointless under Off
                                                  -- (there is only ever one note to split), so it
                                                  -- is shown for both rather than filed under just
                                                  -- one of SHAPE_PARAM_REFS/SATB_PARAM_REFS.

-- Beats (quarter notes) each step takes, indexed as the SYNC list's values.
-- Each is MIDI ticks / 24 (24 PPQN), from the published sync rate table -
-- slowest (8 beats) at index 0 down to fastest (32nd triplet) at index 18.
local syncRates = {
  [0]  = 192 / 24,  -- 8 beats     (1 cycle per 2 bars)
  [1]  = 144 / 24,  -- 6 beats     (1 cycle per 6 beats)
  [2]  = 128 / 24,  -- 5 + 1/3     (3 cycles per 4 bars)
  [3]  = 96 / 24,   -- 4 beats     (1 cycle per 1 bar)
  [4]  = 72 / 24,   -- 3 beats     (1 cycle per 3 beats)
  [5]  = 64 / 24,   -- 2 + 2/3     (3 cycles per 2 bars)
  [6]  = 48 / 24,   -- 2nd         (2 cycles per 1 bar)
  [7]  = 36 / 24,   -- 4th dotted  (2 cycles per 3 beats)
  [8]  = 32 / 24,   -- 1 + 1/3     (3 cycles per 1 bar)
  [9]  = 24 / 24,   -- 4th         (4 cycles per 1 bar)
  [10] = 18 / 24,   -- 8th dotted  (4 cycles per 3 beats)
  [11] = 16 / 24,   -- 4th triplet (6 cycles per 1 bar)
  [12] = 12 / 24,   -- 8th         (8 cycles per 1 bar)
  [13] = 9 / 24,    -- 16th dotted (8 cycles per 3 beats)
  [14] = 8 / 24,    -- 8th triplet (12 cycles per 1 bar)
  [15] = 6 / 24,    -- 16th        (16 cycles per 1 bar)
  [16] = 4 / 24,    -- 16th triplet (24 cycles per 1 bar)
  [17] = 3 / 24,    -- 32nd        (32 cycles per 1 bar)
  [18] = 2 / 24,    -- 32nd triplet (48 cycles per 1 bar)
}

-- The scales offered by Key/Scale, as semitone offsets from the root (Key).
-- Each set is exactly the degrees given in the published scale table.
-- Chromatic (index 0) is a full 12 - every note is already "in scale".
-- Bebop scales (4 below): fixed 8-note scales with a chromatic passing tone
-- added to a diatonic 7-note mode, NOT modally rotated the way Major/Harm
-- Minor/Melodic Minor are - the passing tone only makes sense anchored
-- where it is written, so Mode is hidden for all four
-- (modeChoiceCountForScale() below) rather than offering rotations nobody
-- asks for by these names. Bebop Dorian has two conventional passing-tone
-- choices (a natural 7th, or a natural 3rd) and is offered as two separate
-- scales rather than one scale with a sub-choice, the same way Blues and
-- Major Blues are two scales rather than one with a variant switch.
local Scale = {}

Scale.OFFSETS = {
  [0]  = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 },  -- Chromatic
  [1]  = { 0, 2, 4, 5, 7, 9, 11 },                  -- Major
  [2]  = { 0, 2, 3, 5, 7, 8, 11 },                  -- Harmonic Minor
  [3]  = { 0, 2, 3, 5, 7, 9, 11 },                  -- Melodic Minor (ascending/jazz minor)
  [4]  = { 0, 2, 4, 7, 9 },                          -- Pentatonic
  [5]  = { 0, 3, 5, 6, 7, 10 },                      -- Blues (hexatonic: 1 b3 4 b5 5 b7)
  [6]  = { 0, 2, 3, 4, 7, 9 },                       -- Major Blues (hexatonic: 1 2 b3 3 5 6)
  [7]  = { 0, 2, 4, 5, 7, 9, 10, 11 },               -- Bebop Dominant (Mixolydian + nat7)
  [8]  = { 0, 2, 4, 5, 7, 8, 9, 11 },                -- Bebop Major (Major + b6)
  [9]  = { 0, 2, 3, 5, 7, 9, 10, 11 },               -- Bebop Dorian, nat7 (Dorian + nat7)
  [10] = { 0, 2, 3, 4, 5, 7, 9, 10 },                -- Bebop Dorian, nat3 (Dorian + nat3)
  [11] = { 0, 2, 3, 5, 6, 8, 9, 11 },                -- Fully Diminished
  [12] = { 0, 1, 3, 4, 6, 7, 9, 10 },                -- Dominant Dim
  [13] = { 0, 3, 4, 7, 8, 11 },                      -- Augmented
  [14] = { 0, 2, 4, 6, 8, 10 },                      -- Whole Tone
  [15] = { 0, 2, 4, 5, 7, 8, 11 },                   -- Harmonic Major (Major with b6)
  [16] = { 0, 1, 4, 5, 7, 8, 11 },                   -- Double Harmonic Major (b2 and b6; aka Byzantine/Arabic).
                                                      -- Mode 4 of this (Mode control value 3) IS the Hungarian
                                                      -- Gypsy / Double Harmonic Minor scale note-for-note -
                                                      -- confirmed on the instrument: quantizing every note of an
                                                      -- octave through Scale=16/Mode=3 and through a separate
                                                      -- Harm-Minor-with-#4 scale gave identical results. So that
                                                      -- scale is NOT declared separately here - it is reached as
                                                      -- this one's 4th mode, same as any other mode of any other
                                                      -- scale, rather than duplicated as its own Scale entry.
}

-- Scale ID constants, mode names, the rotation cache and scaleInfoText are
-- all fields/methods of this same Scale table declared above, rather than
-- 20-odd further top-level locals - see the comment above the `Ref` table
-- for why.
Scale.CHROMATIC, Scale.MAJOR, Scale.HARM_MINOR = 0, 1, 2
Scale.MELODIC_MINOR = 3
Scale.PENTATONIC, Scale.BLUES, Scale.MAJOR_BLUES = 4, 5, 6
Scale.BEBOP_DOMINANT, Scale.BEBOP_MAJOR = 7, 8
Scale.BEBOP_DORIAN_NAT7, Scale.BEBOP_DORIAN_NAT3 = 9, 10
Scale.FULL_DIM, Scale.DOM_DIM, Scale.AUGMENTED, Scale.WHOLE_TONE = 11, 12, 13, 14
Scale.HARM_MAJOR, Scale.DOUBLE_HARM_MAJOR = 15, 16

-- Rotates a scale's interval pattern to start from its mode-th degree,
-- keeping the same root (Key) as offset 0 - this is what turns Major's
-- offsets into Dorian's, Phrygian's, etc, and does the equivalent rotation
-- for every other scale too. `mode` is the Mode control's own raw value,
-- 0-based, and wraps on the scale's own note count: mode 0 is always the
-- scale exactly as SCALE_OFFSETS declares it (Ionian, for Major).
--
-- Method: turn the offsets into their step sizes (the gaps between one
-- degree and the next, wrapping the last gap back to the octave), rotate
-- the step list to start at the chosen degree, then rebuild offsets from
-- that rotated step list, root back at 0.
Scale.rotatedCache = {}   -- "scale:mode" -> offsets, memoised

function Scale.rotatedOffsets(scale, mode)
  local offsets = Scale.OFFSETS[scale]
  if not offsets then return nil end

  local L = #offsets
  if L <= 1 then return offsets end

  local modeIndex = mode % L          -- 0-based degree this mode starts on
  if modeIndex == 0 then return offsets end  -- mode 0: unrotated, exactly as declared

  local key = scale .. ":" .. mode
  local cached = Scale.rotatedCache[key]
  if cached then return cached end

  local steps = {}
  for i = 1, L - 1 do
    steps[i] = offsets[i + 1] - offsets[i]
  end
  steps[L] = 12 - offsets[L]           -- the gap back up to the root's octave

  local rotated = { 0 }
  local running = 0
  for i = 1, L - 1 do
    local step = steps[((modeIndex + i - 1) % L) + 1]
    running = running + step
    rotated[i + 1] = running
  end

  Scale.rotatedCache[key] = rotated
  return rotated
end

-- Everything that builds a Shape-mode chord - the shape table, the Diatonic
-- Alt tables, Voice Split, and the functions that use them - lives on this
-- one Chord table, rather than another dozen-odd top-level locals. Same
-- reasoning as the `Ref` table above.
local Chord = {}

-- The chord shapes, in the order the Shape control lists them. Each entry
-- is a list of { degree, extraOctaves } pairs: `degree` is a 1-based scale
-- degree (1 is the root) read against whatever the current Key/Scale/
-- Mode's rotated offsets are, and `extraOctaves` is how many further
-- octaves to add on top of that degree's own octave (negative drops it an
-- octave instead, as Jazz Triad 1/2's own root does) - this is how
-- "1(8ve)" and "2(8ve)" in the shape table are expressed, rather than as a
-- literal semitone count, so every shape stays correct as Key/Scale/Mode
-- change under it.
Chord.SHAPES = {
  [0]  = { { 1, 0 } },                                   -- None
  [1]  = { { 1, 0 }, { 1, 1 } },                          -- Octave
  [2]  = { { 1, 0 }, { 1, 1 }, { 1, 2 } },                 -- Two Octaves
  [3]  = { { 1, 0 }, { 5, 0 } },                          -- Root/Fifth
  [4]  = { { 1, 0 }, { 5, 0 }, { 1, 1 } },                 -- Root/Fifth + 8ve
  [5]  = { { 1, 0 }, { 3, 0 }, { 5, 0 } },                 -- Triad
  [6]  = { { 1, 0 }, { 3, 0 }, { 5, 0 }, { 1, 1 } },        -- Triad + 8ve
  [7]  = { { 1, 0 }, { 2, 0 }, { 5, 0 } },                 -- Sus2
  [8]  = { { 1, 0 }, { 2, 0 }, { 5, 0 }, { 1, 1 } },        -- Sus2 + 8ve
  [9]  = { { 1, 0 }, { 4, 0 }, { 5, 0 } },                 -- Sus4
  [10] = { { 1, 0 }, { 4, 0 }, { 5, 0 }, { 1, 1 } },        -- Sus4 + 8ve
  [11] = { { 1, 0 }, { 3, 0 }, { 5, 0 }, { 6, 0 } },        -- Sixth
  [12] = { { 1, 0 }, { 3, 0 }, { 5, 0 }, { 6, 0 }, { 1, 1 } }, -- Sixth + 8ve
  [13] = { { 1, 0 }, { 3, 0 }, { 5, 0 }, { 7, 0 } },        -- Seventh
  [14] = { { 1, 0 }, { 3, 0 }, { 5, 0 }, { 7, 0 }, { 1, 1 } }, -- Seventh + 8ve
  [15] = { { 1, 0 }, { 3, 0 }, { 5, 0 }, { 7, 0 }, { 2, 1 } }, -- Ninth
  [16] = { { 1, -1 }, { 3, 1 }, { 7, 0 } },                    -- Jazz Triad 1
  [17] = { { 1, -1 }, { 3, 0 }, { 7, 0 } },                    -- Jazz Triad 2
  [18] = { { 1, -1 }, { 3, 1 }, { 5, 0 }, { 7, 0 } },          -- Jazz Tetrad 1
  [19] = { { 1, -1 }, { 3, 0 }, { 5, 0 }, { 7, 0 } },          -- Jazz Tetrad 2
  [20] = { { 1, 0 }, { 3, 0 }, { 5, 0 }, { 2, 1 } },           -- Add9 (1 3 5 9, no 7th)
  [21] = { { 1, 0 }, { 3, 0 }, { 5, 0 }, { 6, 0 }, { 2, 1 } }, -- Six/Nine (1 3 5 6 9)
  [22] = { { 1, 0 }, { 4, 0 }, { 5, 0 }, { 7, 0 } },           -- 7sus4 (1 4 5 b7/7)
  [23] = { { 1, 0 }, { 4, 0 }, { 5, 0 }, { 7, 0 }, { 2, 1 } }, -- 9sus4 (1 4 5 7 9)
  [24] = { { 1, 0 }, { 4, 0 }, { 7, 0 } },                     -- Quartal Triad (stacked 4ths: 1 4 7)
  [25] = { { 1, 0 }, { 4, 0 }, { 7, 0 }, { 3, 1 } },           -- Quartal Tetrad (1 4 7 10 - degree 10 wraps to 3+8ve)
  [26] = { { 1, 0 }, { 3, 0 }, { 5, 0 }, { 7, 0 }, { 2, 1 }, { 4, 1 } }, -- Eleventh (1 3 5 7 9 11)
  [27] = { { 1, 0 }, { 3, 0 }, { 5, 0 }, { 7, 0 }, { 2, 1 }, { 6, 1 } }, -- Thirteenth (1 3 5 7 9 13)
}

-- Diatonic Alt 1/2 (Shape values 20/21, only offered when the current Scale
-- has exactly 7 degrees - see rebuildShapeOverlay() below). Unlike every
-- other Shape, these two do not apply one fixed chord quality to whatever
-- degree is struck - the quality itself changes with the scale degree
-- (I..VII) the struck note lands on, same as a chord built by hand from a
-- diatonic harmonization table would. Indexed 0..6 exactly the way
-- nearestScaleMatch()'s degreeIndex0 is: 0 = I, 6 = VII.
Chord.ALT1, Chord.ALT2 = 28, 29

Chord.ALT_TRIAD   = { { 1, 0 }, { 3, 0 }, { 5, 0 } }
Chord.ALT_SEVENTH = { { 1, 0 }, { 3, 0 }, { 5, 0 }, { 7, 0 } }
Chord.ALT_SIXTH   = { { 1, 0 }, { 3, 0 }, { 5, 0 }, { 6, 0 } }

-- Alt 1: I=triad, II=7th, III=triad, IV=triad, V=7th, VI=7th, VII=6th.
Chord.ALT1_BY_DEGREE = {
  [0] = Chord.ALT_TRIAD,
  [1] = Chord.ALT_SEVENTH,
  [2] = Chord.ALT_TRIAD,
  [3] = Chord.ALT_TRIAD,
  [4] = Chord.ALT_SEVENTH,
  [5] = Chord.ALT_SEVENTH,
  [6] = Chord.ALT_SIXTH,
}

-- Alt 2: I=7th, II=7th, III=triad, IV=7th, V=7th, VI=6th, VII=7th.
Chord.ALT2_BY_DEGREE = {
  [0] = Chord.ALT_SEVENTH,
  [1] = Chord.ALT_SEVENTH,
  [2] = Chord.ALT_TRIAD,
  [3] = Chord.ALT_SEVENTH,
  [4] = Chord.ALT_SEVENTH,
  [5] = Chord.ALT_SIXTH,
  [6] = Chord.ALT_SEVENTH,
}

-- The semitone offset, counted from a root that is already sitting AT one
-- of this scale's own degrees, to the degree `steps` places above it (0 =
-- the root itself) - wrapping past the array's own length by adding whole
-- octaves, so a scale with 7 degrees (or 6, or 8 - SCALE_OFFSETS has scales
-- of several lengths) all stack correctly. `offsets` is a rotated-offsets
-- array (1-based, ascending, offsets[1] == 0); `startIndex0` is the
-- 0-based index of the root WITHIN that array - not a semitone count, a
-- degree count, which is what makes this diatonic: a Triad built on the
-- 2nd degree of a major scale comes out minor, not a transposed copy of
-- the Triad built on the 1st. See nearestScaleMatch() below for where
-- `startIndex0` comes from.
function Chord.scaleStepOffset(offsets, startIndex0, steps)
  local L = #offsets
  local total = startIndex0 + steps
  local idx0 = total % L
  local octave = total // L
  return (offsets[idx0 + 1] + 12 * octave) - offsets[startIndex0 + 1]
end

-- A list control's display value is its 0-based index; toMidi() translates
-- that to the overlay item's actual labelled value (e.g. index 0 -> channel
-- 1). Use this only for list controls.
--
-- A NEGATIVE labelled value comes back wrapped as an unsigned 16-bit number
-- (seen on the Transpose Octave list: item value -2 reads back as 65534,
-- -1 as 65535) - the firmware stores an overlay item's value as uint16
-- regardless of what the project declares. Un-wrap it with the standard
-- two's-complement trick so a list is free to use negative item values.
local function cfgList(ref)
  local c = rcOrNil(ref)
  if not c then return 0 end
  local v = c:getValue()
  local raw = v:toMidi(v:getValue())
  if raw > 32767 then raw = raw - 65536 end
  return raw
end

-- A proportional control's display value already IS the number the script
-- wants (BPM, a percent, a semitone count, ...) - no translation needed.
-- Do NOT route this through toMidi(): the firmware clamps a message's min
-- to 0 even when the project declares a negative one (seen on Swing and
-- Transpose, both bipolar), so toMidi() on a fader with a negative range
-- silently returns the wrong, non-negative number. getValue() is unaffected
-- - it reads the control's own display range, which is stored correctly.
local function cfgValue(ref)
  local c = rcOrNil(ref)
  if not c then return 0 end
  return c:getValue():getValue()
end

-- Some IFACE/PORT pairs (SRC, DST, CLOCK IN) may now be combined two-value
-- "I/O" custom controls instead of separate list controls (see IoKnob
-- further down) - reading them by control reference the way cfgList()
-- does would see nothing once a reference like the old SRC IFACE's own
-- disappears that way. Read the underlying PARAMETER instead: it exists
-- and is kept current by whichever control - separate list or combined
-- knob - currently writes it, so route-matching never cares which one is
-- actually on screen. Every one of these parameters is virtual and 1-32
-- is never used for more than device 1 in this preset.
local function cfgParam(parameterNumber)
  local raw = parameterMap.get(1, PT_VIRTUAL, parameterNumber)
  if raw == MIDI_VALUE_DO_NOT_SEND then return 0 end
  return raw
end

-- SRC/DST/CLOCK IN: on the Mini these are combined onto one knob each (turn
-- selects the interface, the knob's own push-switch toggles the port) to
-- save three slots; on mk2, where there is room, they stay two separate
-- controls exactly as before. cfgRoutedIface()/cfgRoutedPort() read the
-- right shape for whichever device loaded the preset, so srcMatches(),
-- destRoute() and Clock.srcPortMatches() do not have to know which layout
-- is active. `mergedRef` is the Mini's own combined control's reference
-- directly (not offset - it is not mk2Ref+300, since mk2 has no equivalent
-- single tile); `mk2Ref` is read through the usual cfgList() on mk2.
local function cfgRoutedIface(mk2Ref, mergedRef)
  if resolveOffset() == 0 then
    return cfgList(mk2Ref)
  end
  local ok, c = pcall(controls.get, mergedRef)
  if not ok then return 0 end
  local v = c:getValue("iface")
  local raw = v:toMidi(v:getValue())
  if raw > 32767 then raw = raw - 65536 end
  return raw
end

local function cfgRoutedPort(mk2Ref, mergedRef)
  if resolveOffset() == 0 then
    return cfgList(mk2Ref)
  end
  local ok, c = pcall(controls.get, mergedRef)
  if not ok then return 0 end
  local v = c:getValue("port")
  local raw = v:toMidi(v:getValue())
  if raw > 32767 then raw = raw - 65536 end
  return raw
end

-- The combined SRC/DST/CLOCK IN knob (Mini only): a `custom` control, not a
-- `list` - a plain list silently aliases any value id it does not recognise
-- back to its first value (found on the instrument: getValue("port") on a
-- list was actually handing back the "iface" value, so the "press" toggle
-- was corrupting the interface instead of touching the port at all), while
-- a custom control resolves named values correctly (10.6/9.6). So this
-- paints itself, and a pot/switch callback stand in for what a list would
-- have done for free - attached once per control in preset.onReady(),
-- since callbacks do not survive a reload.
function paintRoutedKnob(control)
  local b = control:getBounds()
  local w, h = b[WIDTH], b[HEIGHT]

  graphics.setColor(0x101010)
  graphics.fillRect(0, 0, w, h)

  local ifaceValue = control:getValue("iface")
  local portValue = control:getValue("port")
  local label = ifaceValue:getOverlay():getLabel(ifaceValue:getValue()) or "?"
  local portLabel = (portValue:getValue() == 0) and "P1" or "P2"

  graphics.setBackgroundColor(0x101010)
  graphics.setColor(control:getColor())
  graphics.print(0, (h // 2) - 16, label, w, CENTER, REGULAR, SMALL)
  graphics.setColor(0xB0B0B0)
  graphics.print(0, (h // 2) + 2, portLabel, w, CENTER, REGULAR, SMALL)
end

-- Turning the knob: a custom control does not move its own values, so this
-- is what makes the turn actually change the interface at all.
function onRoutedKnobTurn(control, event)
  if event.delta == 0 then return end   -- a touch, not a turn
  local ifaceValue = control:getValue("iface")
  local wanted = math.floor(helpers.clamp(ifaceValue:getValue() + event.delta,
                                          ifaceValue:getMin(), ifaceValue:getMax()))
  ifaceValue:setValue(wanted)
  control:repaint()
end

-- The knob's own push-switch (a Mini has one, an mk2 does not - 9.8):
-- toggles the hidden port value. One function, reused by every combined
-- knob (SRC/DST/CLOCK IN).
function onRoutedKnobSwitch(control, event)
  if event.type ~= 1 then return end   -- 1 pressed, 3 released - act on press only
  local portValue = control:getValue("port")
  local newPort = (portValue:getValue() == 0) and 1 or 0
  portValue:setValue(newPort)
  control:repaint()
end

-- Reference numbers for the "combined IFACE/PORT" custom controls (see
-- IoKnob much further down) - declared this early so the ordinary (iface,
-- port) readers just below can prefer a combo control's own setting over
-- the separate mirrored list it replaced, rather than that list's own
-- tolerant fallback (now silently 0, since the control it names is gone)
-- winning instead. nil until a pair is combined; ioRoute() falls back to
-- the separate controls otherwise, so an un-combined route (every mk2
-- route, and any Mini route not yet converted) is unaffected.
local ComboRef = {
  SRC       = 440,
  DST       = 441,
  CLOCK_IN  = 442,
  CLOCK_OUT = 443,
}

local function comboControlOrNil(ref)
  if not ref then return nil end
  local ok, c = pcall(controls.get, ref)
  if ok then return c end
  return nil
end

-- Reads an (interface, port) pair that may be two separate list controls
-- or one combined custom knob - whichever actually exists wins.
local function ioRoute(comboRef, ifaceRef, portRef)
  local combo = comboControlOrNil(comboRef)
  if combo then
    return combo:getValue("iface"):getValue(), combo:getValue("port"):getValue()
  end
  return cfgList(ifaceRef), cfgList(portRef)
end

-- See the comment above SHAPE_UPDATE_REF.
local function shapeUpdateIsImmediate()
  return cfgList(Ref.SHAPE_UPDATE) == SHAPE_UPDATE_IMMEDIATE
end

-- LFO engine (mk2 Page 4 / Mini Page 9, both named MOD): two step-synced
-- LFOs that modulate an ARP parameter already read live, fresh, every
-- step - GATE LENGTH, SWING AMOUNT, CHANCE, ARP VEL, ACC AMOUNT, GROOVE
-- AMT. The Mini's copies sit on references 500-507 (ref+300 of mk2's
-- 200-207, the same mirroring every other Mini control uses) - see
-- Lfo.RATE_REF etc below, read through cfgList()/cfgValue(), which already
-- add resolveOffset() for us. Because every one of
-- those is read through cfgValue()/cfgList() at the moment it is used,
-- rather than cached, an LFO only has to write a new number into the
-- destination control (value:updateValue()) before advanceStep() runs -
-- nothing about the arp engine itself changes.
--
-- There is one timer per preset, and it only runs while the arp is
-- stepping (Internal or External clock alike) - see preset.onReady()/
-- onArpToggle()/onClockSourceChange(). So RATE is counted in ARP STEPS,
-- not Hz: both LFOs are always locked to the exact clock the arp itself
-- steps on, and neither one runs, or needs to, while the arp is off -
-- Harmony Engine parameters (Transpose, Strum shaping) are read only at
-- the moment a chord/strum is generated, not continuously, so modulating
-- those usefully needs a separate, always-on clock; left for later.
--
-- Each destination's BASE - the value the player actually set by hand -
-- is tracked separately from whatever the LFO is currently displaying on
-- that control, in Lfo.base[ref]. It is only ever written from that
-- control's own onChange (a real turn, or an incoming MIDI set) - never
-- from the LFO's own value:updateValue() call, which does not run the
-- control's function at all (10.3) - so the two never fight: the LFO
-- always offsets from the player's last real setting, never from its own
-- last output.
--
-- Two LFOs aimed at the SAME destination are not summed - whichever is
-- applied second (LFO 2) simply overwrites LFO 1's write for that step.
-- Point them at different parameters for two independent motions.
local Lfo = {}

Lfo.REF_GATE, Lfo.REF_SWING, Lfo.REF_CHANCE = 11, 12, 16
Lfo.REF_ARPVEL, Lfo.REF_ACCAMT, Lfo.REF_GROOVEAMT = Ref.ARP_VELOCITY, 65, Ref.GROOVE_AMOUNT

-- LFO DEST list values (0 = None) -> the ref they modulate.
Lfo.DEST_BY_VALUE = {
  [1] = Lfo.REF_GATE,
  [2] = Lfo.REF_SWING,
  [3] = Lfo.REF_CHANCE,
  [4] = Lfo.REF_ARPVEL,
  [5] = Lfo.REF_ACCAMT,
  [6] = Lfo.REF_GROOVEAMT,
}

-- Each destination's own display range, exactly matching its control's
-- declared min/max - the LFO is clamped to this and can never write
-- anything the control could not hold by hand.
Lfo.RANGE = {
  [Lfo.REF_GATE]      = { min = 1,    max = 100 },
  [Lfo.REF_SWING]     = { min = -80,  max = 80 },
  [Lfo.REF_CHANCE]    = { min = 10,   max = 100 },
  [Lfo.REF_ARPVEL]    = { min = 0,    max = 127 },
  [Lfo.REF_ACCAMT]    = { min = 0,    max = 100 },
  [Lfo.REF_GROOVEAMT] = { min = -120, max = 120 },
}

Lfo.base = {}   -- ref -> the player's own last-set value, independent of any LFO output

function Lfo.captureBase(ref, value)
  Lfo.base[ref] = value
end

-- LFO RATE list values (0..14) -> arp steps per full cycle. Not powers of
-- two only: 3/6/12/24/48/72 reach a 3-bar-style cycle (or any other
-- multiple of 3) against a straight SYNC the same way the power-of-two
-- values reach 1/2/4/8-bar cycles - Lfo.advanceStep() just divides the
-- phase by whatever integer sits here, with no restriction on what that
-- integer is. Default (index 7) is "16 steps".
Lfo.RATE_STEPS = {
  [0] = 1,  [1] = 2,  [2] = 3,  [3] = 4,  [4] = 6,   [5] = 8,   [6] = 12,
  [7] = 16, [8] = 24, [9] = 32, [10] = 48, [11] = 64, [12] = 72, [13] = 96, [14] = 128,
}

Lfo.WAVE_SINE, Lfo.WAVE_TRI, Lfo.WAVE_SAW_UP, Lfo.WAVE_SAW_DOWN, Lfo.WAVE_SQUARE, Lfo.WAVE_SH =
  0, 1, 2, 3, 4, 5

-- This preset's two LFO controls (mk2 Page 4 / Mini Page 9, MOD):
-- RATE/SHAPE/DEPTH/DEST. These are mk2 references; cfgList()/cfgValue()
-- add resolveOffset() (+300 on the Mini) when reading them, so the Mini's
-- own copies at 500-507 are found without any special-casing here.
Lfo.RATE_REF  = { 200, 204 }
Lfo.SHAPE_REF = { 201, 205 }
Lfo.DEPTH_REF = { 202, 206 }
Lfo.DEST_REF  = { 203, 207 }

Lfo.state = {
  { phase = 0, shValue = 0 },
  { phase = 0, shValue = 0 },
}

function Lfo.waveform(shape, phase, shValue)
  if shape == Lfo.WAVE_SINE then
    return math.sin(phase * 2 * math.pi)
  elseif shape == Lfo.WAVE_TRI then
    if phase < 0.5 then return -1 + 4 * phase else return 3 - 4 * phase end
  elseif shape == Lfo.WAVE_SAW_UP then
    return 2 * phase - 1
  elseif shape == Lfo.WAVE_SAW_DOWN then
    return 1 - 2 * phase
  elseif shape == Lfo.WAVE_SQUARE then
    return (phase < 0.5) and 1 or -1
  elseif shape == Lfo.WAVE_SH then
    return shValue or 0
  end
  return 0
end

-- Advances both LFOs' phase by one arp step. Called once per actual step
-- elapsed - including once per step the catch-up loop in timer.onTick
-- walks over, the same way ArpState.stepIndex itself is walked there -
-- so phase always stays locked to real elapsed steps, not to how often
-- this happens to be called.
function Lfo.advanceStep()
  for i = 1, 2 do
    local st = Lfo.state[i]
    local stepsPerCycle = Lfo.RATE_STEPS[cfgList(Lfo.RATE_REF[i])] or 4
    st.phase = st.phase + (1 / stepsPerCycle)
    if st.phase >= 1 then
      st.phase = st.phase % 1
      st.shValue = math.random() * 2 - 1   -- a fresh Sample & Hold value once per cycle
    end
  end
end

-- Writes each active LFO's current output into its destination control -
-- called once per actual step, after Lfo.advanceStep() and before the
-- arp's own advanceStep() reads the destination fresh.
function Lfo.apply()
  for i = 1, 2 do
    local destValue = cfgList(Lfo.DEST_REF[i])
    local ref = Lfo.DEST_BY_VALUE[destValue]
    if ref then
      local range = Lfo.RANGE[ref]
      local base = Lfo.base[ref]
      if base == nil then
        base = cfgValue(ref)
        Lfo.base[ref] = base
      end
      local st = Lfo.state[i]
      local shape = cfgList(Lfo.SHAPE_REF[i])
      local depth = cfgValue(Lfo.DEPTH_REF[i]) / 100   -- -1..1
      local wave = Lfo.waveform(shape, st.phase, st.shValue)
      local amplitude = (range.max - range.min) / 2
      local newValue = math.floor(helpers.clamp(base + wave * amplitude * depth, range.min, range.max))
      rc(ref):getValue():updateValue(newValue)
    end
  end
end

-- Picking a destination or a rate starts that LFO's cycle fresh, at phase
-- 0 - otherwise a phase advanced while the destination was None (the arp
-- keeps both LFOs' phase moving regardless of what they target) can leave
-- a whole-cycle-per-step rate (1, 2, 4, ... steps) stuck at a non-zero
-- fractional offset forever: adding a whole number of cycles never clears
-- a fractional remainder, only an explicit reset does. Found by a test
-- that changed RATE and DEST and expected the next step to land on phase
-- 0, immediately after load - it did not, until this.
function onLfo1DestChange(valueObject, value)
  Lfo.state[1].phase, Lfo.state[1].shValue = 0, 0
end

function onLfo2DestChange(valueObject, value)
  Lfo.state[2].phase, Lfo.state[2].shValue = 0, 0
end

function onLfo1RateChange(valueObject, value)
  Lfo.state[1].phase, Lfo.state[1].shValue = 0, 0
end

function onLfo2RateChange(valueObject, value)
  Lfo.state[2].phase, Lfo.state[2].shValue = 0, 0
end

function formatLfoDepth(valueObject, value)
  if value > 0 then return "+" .. value .. " %" end
  return value .. " %"
end

-- The familiar mode names for Major, Natural Minor and Harmonic Minor - the
-- three seven-note scales that get named modes rather than plain numbers.
-- Each table is indexed 0..6 to match the Mode control's own raw value;
-- modeNamesForScale() below picks the right table (or none) for the
-- current Scale Shape, and modeChoiceCountForScale() limits the Mode control to
-- exactly as many choices as the table has, so turning past "7" is not
-- possible for these three scales - see onScaleChange() and
-- preset.onReady().
Scale.MAJOR_MODE_NAMES = {
  [0] = "Ionian",
  [1] = "Dorian",
  [2] = "Phrygian",
  [3] = "Lydian",
  [4] = "Mixolydian",
  [5] = "Aeolian",
  [6] = "Locrian",
}

-- Pentatonic's 5 modes - the same 5-note scale rotated to start on each of
-- its own degrees, named the way players actually ask for them rather than
-- by scale-degree number: mode 0 is the major pentatonic itself (1 2 3 5 6),
-- mode 1 rotates to its 2nd degree (the "Suspended" pentatonic, no 3rd),
-- mode 2 to its 3rd (Blues Minor), mode 3 to its 4th (Blues Major), and
-- mode 4 to its 5th - the relative minor pentatonic, the one every guitarist
-- already knows as "the" pentatonic scale.
Scale.PENTATONIC_MODE_NAMES = {
  [0] = "Major Pentatonic",
  [1] = "Suspended",
  [2] = "Blues Minor",
  [3] = "Blues Major",
  [4] = "Minor Pentatonic",
}

-- Melodic Minor (ascending/jazz minor)'s 7 modes - same rotation mechanism
-- as Harmonic Minor above, named with their usual jazz-theory labels.
-- Mode 3 (Lydian Dominant) and mode 6 (Altered) are the two most played:
-- Lydian Dominant for a dominant-7#11 sound, Altered for an altered
-- dominant (b9/#9/#11/b13) resolving down a fifth.
Scale.MELODIC_MINOR_MODE_NAMES = {
  [0] = "Melodic Minor",
  [1] = "Dorian b2",
  [2] = "Lydian Augmented",
  [3] = "Lydian Dominant",
  [4] = "Mixolydian b6",
  [5] = "Locrian nat2",
  [6] = "Altered",
}

-- Blues (hexatonic: 1 b3 4 b5 5 b7) - unlike Pentatonic, this is offered as
-- a single scale rather than 6 rotations: the gaps between its degrees are
-- uneven enough (3,2,1,1,3,2 semitones) that the rotations do not read as
-- recognisable named scales the way the pentatonic's do, and in practice
-- players reach for "the" blues scale from its own root rather than
-- modally. See modeChoiceCountForScale() below.
Scale.BLUES_MODE_NAMES = {
  [0] = "Blues",
}

-- Major Blues (hexatonic: 1 2 b3 3 5 6) - major pentatonic with the b3
-- "blue note" added, the major-key counterpart to Blues above (which is
-- built around a b3/b5/b7 minor tonality). Same reasoning as Blues: its
-- gaps are uneven enough that the rotations are not useful named scales,
-- so it is offered as a single scale rather than modally.
Scale.MAJOR_BLUES_MODE_NAMES = {
  [0] = "Major Blues",
}

-- Accidentals are written in plain ASCII ("#" for sharp, "b"/"bb" for
-- flat/double-flat, "nat" for natural) rather than the Unicode natural/
-- sharp/flat glyphs (U+266E/266F/266D): the controller's screen font has
-- no glyph for any of the three, so they drew as nothing at all - found
-- on the instrument, not in the editor or the log, which both show the
-- bytes just fine. ASCII also sidesteps the overlay label's 20-byte limit
-- that a double-flat written as two 3-byte UTF-8 sequences blew past,
-- silently dropping "Super-Locrian"'s trailing "7".
Scale.HARM_MINOR_MODE_NAMES = {
  [0] = "Aeolian nat7",
  [1] = "Locrian nat6",
  [2] = "Ionian #5",
  [3] = "Dorian #4",
  [4] = "Phrygian Dominant",
  [5] = "Lydian #2",
  [6] = "Super-Locrian bb7",
}

-- Harmonic Major's 7 modes - the same rotation mechanism as Harmonic
-- Minor's above, named with their usual theory labels. Mode 0 is Harmonic
-- Major itself (Major with a b6).
Scale.HARM_MAJOR_MODE_NAMES = {
  [0] = "Harmonic Major",
  [1] = "Dorian b5",
  [2] = "Phrygian b4",
  [3] = "Lydian b3",
  [4] = "Mixolydian b2",
  [5] = "Lydian #2 #5",
  [6] = "Locrian bb7",
}

-- Double Harmonic Major's 7 modes, likewise. Mode 3 (Hungarian Minor) is
-- the Hungarian Gypsy / Double Harmonic Minor scale - see the comment on
-- SCALE_OFFSETS[16] above: it is reached here, as this scale's 4th mode,
-- rather than declared as a separate Scale entry. "Dbl Harm Major" rather
-- than the full "Double Harmonic Major" for mode 0, to stay inside the
-- overlay label's 20-byte limit (see the ASCII-accidentals comment above
-- HARM_MINOR_MODE_NAMES) - the full name is 21 bytes and would be
-- silently truncated.
Scale.DOUBLE_HARM_MAJOR_MODE_NAMES = {
  [0] = "Dbl Harm Major",
  [1] = "Lydian #2 #6",
  [2] = "Ultraphrygian",
  [3] = "Hungarian Minor",
  [4] = "Asian",
  [5] = "Ionian Aug. #2",
  [6] = "Locrian bb3 bb7",
}

-- The named-mode table for a scale, or nil when that scale's modes are
-- shown as plain numbers (Chromatic, Dominant, the diminished/augmented
-- scales, Whole Tone).
function Scale.modeNames(scale)
  if scale == Scale.MAJOR then return Scale.MAJOR_MODE_NAMES end
  if scale == Scale.HARM_MINOR then return Scale.HARM_MINOR_MODE_NAMES end
  if scale == Scale.PENTATONIC then return Scale.PENTATONIC_MODE_NAMES end
  if scale == Scale.MELODIC_MINOR then return Scale.MELODIC_MINOR_MODE_NAMES end
  if scale == Scale.BLUES then return Scale.BLUES_MODE_NAMES end
  if scale == Scale.MAJOR_BLUES then return Scale.MAJOR_BLUES_MODE_NAMES end
  if scale == Scale.HARM_MAJOR then return Scale.HARM_MAJOR_MODE_NAMES end
  if scale == Scale.DOUBLE_HARM_MAJOR then return Scale.DOUBLE_HARM_MAJOR_MODE_NAMES end
  return nil
end

-- How many Mode choices make sense for a scale: the three named sets are
-- limited to exactly their 7 modes; Whole Tone, Full Dim and Dom Dim are
-- all symmetrical (repeating every 2-4 semitones), so rotating them by a
-- scale degree just gives the same set of pitches back - 1 choice each;
-- Augmented repeats every minor third (4 semitones) but, unlike those
-- three, alternates between two distinct note sets as you rotate through
-- it one degree at a time (the augmented triad's own two inversions) - 2
-- choices; everything else keeps the full 12.
function Scale.modeChoiceCount(scale)
  if scale == Scale.MAJOR or scale == Scale.HARM_MINOR or scale == Scale.MELODIC_MINOR
    or scale == Scale.HARM_MAJOR or scale == Scale.DOUBLE_HARM_MAJOR then
    return 7
  end
  if scale == Scale.CHROMATIC or scale == Scale.WHOLE_TONE or scale == Scale.FULL_DIM
    or scale == Scale.DOM_DIM or scale == Scale.BLUES or scale == Scale.MAJOR_BLUES
    or scale == Scale.BEBOP_DOMINANT or scale == Scale.BEBOP_MAJOR
    or scale == Scale.BEBOP_DORIAN_NAT7 or scale == Scale.BEBOP_DORIAN_NAT3 then
    return 1
  end
  if scale == Scale.AUGMENTED then
    return 2
  end
  if scale == Scale.PENTATONIC then
    return 5
  end
  return 12
end

-- Limiting a List's choices takes more than value:setMax() - the picker a
-- tap opens lists every item the OVERLAY has, regardless of the value's
-- own max, so the overlay itself has to be rebuilt to the right size.
-- overlays.create() then re-binds every bound List value's min/max to the
-- new item count and repaints it automatically (preset-lua reference,
-- 14.4) - which is also why this replaces the formatter/setOverride
-- approach a plain value:setMax() needed: the overlay's own labels are
-- what is shown, no override required, and they are correct the moment
-- the overlay changes.
--
-- The overlay id to rebuild is read from the control itself, live
-- (value:getOverlayId()), NEVER taken from the project file's own
-- overlayId - the compiled preset renumbers overlays on export/load, so
-- the id a control ends up bound to on the instrument is not necessarily
-- the id the editor declared. Hard-coding the project's number once
-- clobbered the SHAPE control's overlay (a different control that,
-- after renumbering, happened to end up on the id Mode's project file
-- declared) - found by checking every control's live getOverlayId() on
-- the instrument after the choices showed garbage.
function Scale.rebuildModeOverlay()
  local scale = cfgList(34)
  local names = Scale.modeNames(scale)
  local count = Scale.modeChoiceCount(scale)
  local modeValue = rc(27):getValue()
  local overlayId = modeValue:getOverlayId()

  local items = {}
  for i = 0, count - 1 do
    items[i + 1] = { value = i, label = (names and names[i]) or tostring(i + 1) }
  end
  overlays.create(overlayId, items)

  -- A scale with only one Mode choice (Chromatic, Whole Tone, the two
  -- symmetrical diminished scales) has nothing for Mode to do - every
  -- rotation gives back the identical note set - so the control is hidden
  -- rather than shown with one unchangeable option.
  rc(27):setVisible(count > 1)

  -- Tonic makes no difference under Chromatic: Scale.OFFSETS[0] is every
  -- semitone (0..11), an unbroken arithmetic run of step 1, so
  -- quantizeToScale() always finds an exact match (shift 0, nothing is
  -- quantized - see the comment on Scale.OFFSETS) and scaleStepOffset()'s
  -- result for any step count works out to exactly that many semitones
  -- REGARDLESS of which degree it started counting from - the degree
  -- index itself cancels out of `offsets[idx0+1] - offsets[startIndex0+1]`
  -- when the offsets are consecutive integers. So neither the arp's
  -- quantizer nor Shape/SATB's chord-stacking ever read a different result
  -- for a different Tonic once Scale Shape is Chromatic, and the control is hidden
  -- rather than shown with no audible effect.
  rc(33):setVisible(scale ~= Scale.CHROMATIC)

  -- Defensive: pull the stored value back into the new overlay's range.
  -- overlays.create() rebinds the value's own min/max to the new item
  -- count, but the raw value it leaves behind can land outside 0..count-1
  -- on either side - seen going negative, not just too high - so clamp
  -- both ends rather than only guarding the top.
  local current = modeValue:getValue()
  if current > (count - 1) then
    modeValue:updateValue(count - 1)
  elseif current < 0 then
    modeValue:updateValue(0)
  end
end

-- The base Shape labels, 0..19, exactly as the project declares them -
-- kept here too so the overlay can be rebuilt (same mechanism as
-- rebuildModeOverlay() above) to add or remove the two Diatonic Alt
-- shapes without touching the other twenty.
Chord.BASE_LABELS = {
  [0] = "None", [1] = "Octave", [2] = "Two Octaves", [3] = "Root/Fifth",
  [4] = "Root/Fifth + 8ve", [5] = "Triad", [6] = "Triad + 8ve", [7] = "Sus2",
  [8] = "Sus2 + 8ve", [9] = "Sus4", [10] = "Sus4 + 8ve", [11] = "Sixth",
  [12] = "Sixth + 8ve", [13] = "Seventh", [14] = "Seventh + 8ve", [15] = "Ninth",
  [16] = "Jazz Triad  1", [17] = "Jazz Triad 2", [18] = "Jazz Tetrad 1",
  [19] = "Jazz Tetrad 2", [20] = "Add9", [21] = "Six/Nine", [22] = "7sus4",
  [23] = "9sus4", [24] = "Quartal Triad", [25] = "Quartal Tetrad",
  [26] = "Eleventh", [27] = "Thirteenth", [28] = "Diatonic Alt 1",
  [29] = "Diatonic Alt 2",
}

-- Diatonic Alt 1/2 (Shape values 20/21) only make sense on a 7-note scale -
-- see the comment above SHAPE_ALT1_BY_DEGREE. Rebuilt on every Scale change
-- and on load, same as Mode's overlay, and for the same reason: the
-- picker shows whatever the overlay holds regardless of the value's own
-- max, so narrowing the choices means rebuilding the overlay itself.
function Chord.rebuildOverlay()
  local scale = cfgList(34)
  local baseOffsets = Scale.OFFSETS[scale]
  local scaleLen = baseOffsets and #baseOffsets or 12
  local count = (scaleLen == 7) and 30 or 28

  local shapeValue = rc(36):getValue()
  local overlayId = shapeValue:getOverlayId()

  local items = {}
  for i = 0, count - 1 do
    items[i + 1] = { value = i, label = Chord.BASE_LABELS[i] or tostring(i) }
  end
  overlays.create(overlayId, items)

  -- Defensive, same as rebuildModeOverlay(): pull a stored value that is
  -- now out of range (e.g. Alt 1/2 was selected, then Scale moved away
  -- from a 7-note scale) back inside the new overlay.
  local current = shapeValue:getValue()
  if current > (count - 1) then
    shapeValue:updateValue(count - 1)
  elseif current < 0 then
    shapeValue:updateValue(0)
  end
end

-- Scale-degree names for each semitone 0..11 above the root, standard
-- notation (flats only, no sharps - matching the ASCII-accidentals
-- convention used elsewhere in this file, e.g. HARM_MINOR_MODE_NAMES).
Scale.DEGREE_NAMES = {
  [0] = "1", [1] = "b2", [2] = "2", [3] = "b3", [4] = "3", [5] = "4",
  [6] = "b5", [7] = "5", [8] = "b6", [9] = "6", [10] = "b7", [11] = "7",
}

-- What the chosen Scale Shape (and, for a scale with named modes, the
-- current Mode's rotation of it) means in scale-degree terms - shown in
-- the info bar so a player can see at a glance what Shape/SATB are
-- actually built from. Chromatic has nothing useful to add beyond its own
-- name. Whole Tone and the two diminished scales are symmetrical and read
-- far more clearly as their whole/half-step pattern than as a list of
-- degrees - everything else is the CURRENT rotation's own degrees (so a
-- Major-scale Mode change, say to Dorian, updates this too), joined
-- "1-2-b3-...". info.setText() truncates at 20 characters; the longest
-- string this produces (an 8-note scale's full degree list) comes in at
-- 18, so nothing here is ever cut.
function Scale.infoText()
  local scale = cfgList(34)

  if scale == Scale.CHROMATIC then
    return "Chromatic"
  elseif scale == Scale.WHOLE_TONE then
    return "W-W-W-W-W-W"
  elseif scale == Scale.FULL_DIM then
    return "W-H-W-H-W-H-W-H"
  elseif scale == Scale.DOM_DIM then
    return "H-W-H-W-H-W-H-W"
  end

  local offsets = Scale.rotatedOffsets(scale, cfgList(27))
  if not offsets then return "" end

  local degrees = {}
  for _, semitone in ipairs(offsets) do
    degrees[#degrees + 1] = Scale.DEGREE_NAMES[semitone % 12] or tostring(semitone)
  end
  return table.concat(degrees, "-")
end

function Scale.updateInfoText()
  info.setText(Scale.infoText())
end

-- Strum Time/Direction (refs 43/44) - spreading a chord's notes out in time
-- instead of sounding them all at once. Read live, like every other config
-- value here - cfgValue(43)/cfgList(44) always reflect the current knob.
--
-- Everything strum-related - the direction constants, the gate-handle
-- bookkeeping, and the shaping/sending functions - lives on this one Strum
-- table, rather than another dozen-odd top-level locals. Same reasoning as
-- the `Ref` table above.
local Strum = {}
Strum.UP, Strum.DOWN, Strum.ALT = 0, 1, 2

-- STRUM RAMP (ref 71): a velocity crescendo/decrescendo across a strummed
-- chord's notes, independent of the struck key's own velocity - the same
-- idea as a ratchet's velocity ramp, applied here to a chord's notes
-- instead of repeats of one note.
--
-- Bipolar -100..100%, default 0 (no shaping: every note at the struck
-- velocity). The end anchored at the struck velocity never moves; only
-- the OTHER end scales down by the ramp's magnitude - so 0 is always flat
-- and the struck velocity is always the loudest note in the strum,
-- whichever sign is chosen:
--   positive -> crescendo: the first note (in STRUM DIR's order) is
--               quietest, the last note is at the full struck velocity
--   negative -> decrescendo: the first note is at the full struck
--               velocity, the last note is quietest
-- Read live, like every other config value here.
--
-- Originally this same knob also warped the strum's timing (a "macro"),
-- on the theory that a real stroke's loud end is also its fast end. In
-- practice the two wanted different ranges to be useful at once - a
-- timing curve strong enough to feel like acceleration made the velocity
-- ramp's useful range collapse with it - so the timing half now has its
-- own control, STRUM ACCEL (ref 72, just below), moved for free when
-- room opened up next to INVERSION. The two can still be played together,
-- they just no longer have to move together.

-- STRUM ACCEL (ref 72): a timing curve across a strummed chord's notes,
-- independent of STRUM RAMP's velocity shaping and of the struck key's
-- velocity. See strumTimingFraction() below for the curve itself.
--
-- Bipolar -100..100%, default 0 (no warp: notes land evenly spaced across
-- Strum Time, the original, only behaviour). The end anchored at Strum
-- Time's own fixed grid never moves; only how the OTHER notes are spaced
-- leading up to it changes:
--   positive -> accelerating: the first note (in STRUM DIR's order) is
--               most spread out, and the notes bunch up tight as they
--               approach the last - a stroke picking up speed as it
--               builds.
--   negative -> decelerating: the notes start bunched tight and spread
--               out toward the last - a fast attack that trails off.
-- This interacts with STRUM DIR by design, not by accident: Down +
-- positive Accel means the highest note starts spread-out and the lowest
-- ends bunched, the way a real downstroke's speed actually builds. Read
-- live, like every other config value here.

-- STRUM JITTER (ref 75, Config page): a small random timing offset on top
-- of everything else - Strum Time/Direction, STRUM RAMP's velocity curve
-- and STRUM ACCEL's timing curve all stay exactly as they are; jitter is
-- added last, in sendStrummedNotes() itself, as a further +/- nudge to
-- each note's already-computed delay. 0..30ms, default 0 (off - no
-- randomness at all, bit-for-bit what the strum did before this existed),
-- same "0 is off" idiom as every other shaping control here.
--
-- An ABSOLUTE number of milliseconds, deliberately not a percentage of
-- Strum Time - that was tried first and played wrong: a human hand's own
-- timing noise is a fixed quantity, a handful of milliseconds, regardless
-- of how fast or slow the overall stroke is. Scaled as a percentage, a
-- short Strum Time kept that noise small (sounded fine even near the top
-- of the range) but a long Strum Time blew the same percentage out to
-- tens of milliseconds of real, audible lateness - sloppy rather than
-- human, and the longer Strum Time was set to, the worse it got, which is
-- backwards: a slower strum should not need a STEADIER hand to sound
-- clean. An absolute value gives the same few milliseconds of looseness
-- at every Strum Time, which is what a real hand actually contributes.
-- Measured on the instrument before this was fixed: above roughly 10% of
-- a long Strum Time read as "wrong note, late" rather than "human"; the
-- same absolute lateness at a short Strum Time was unnoticeable, because
-- the whole gesture was already over quickly.
--
-- Clamped so a large negative jitter can never push a note's delay below
-- 0 - midi.at() would just send a past time at once rather than erroring,
-- but a floor here keeps the result predictable rather than merely
-- harmless.

-- ACCEL CURVE (ref 73, Config page): how strongly |STRUM ACCEL| = 100%
-- warps the timing - the exponent cap p_max in strumTimingFraction()
-- below. Stored as tenths (10..30) so it can be a plain integer fader;
-- read back as 1.0..3.0. Exposed as its own control, rather than picked
-- once and baked in, because the "right" amount of warp turned out to be
-- a matter of taste and of how it was going to be played - 1.5 read as
-- natural in some use, too subtle in others, and the only way to find out
-- was to put it under a knob and listen. Default 15 (p_max = 1.5), the
-- value arrived at before this was split out; the usable range this
-- control allows (1.0..3.0) spans flat-linear-but-pointless-to-turn-up at
-- one end to the "two of three notes nearly simultaneous at 100% Accel"
-- compression measured and rejected while tuning STRUM_ACCEL_REF, at the
-- other - see strumTimingFraction() for why a high p needs disproportionately
-- more Strum Time to stay audible.

-- STRUM GATE (ref 76, Config page) and STRUM GATE TAPER (ref 77, Config
-- page): a gate-length taper across a strummed chord's notes, independent
-- of STRUM RAMP/ACCEL/JITTER above - those all shape the ATTACK (velocity,
-- onset timing); this shapes how long each note is allowed to RING once it
-- has sounded.
--
-- The idea: a guitarist's strumming hand keeps moving after it plucks a
-- string, and the strings it struck first are the ones its fingers/pick
-- have since moved on from - so by the time the stroke reaches the LAST
-- string, the hand is already lifting off the strum altogether and that
-- last string gets damped again almost at once, while the first string,
-- struck a moment before the hand had anywhere else to be, got to ring the
-- longest. STRUM GATE TAPER models that: the first-struck note always
-- gets STRUM GATE's full length; later notes get progressively less of
-- it, the last note the least.
--
-- STRUM GATE (ms, 0..2000, default 0): the base ring time, applied to the
-- FIRST note of the strum and, with TAPER at 0, to every other note too.
-- 0 is off - no auto-gate at all, notes ring exactly as they always did,
-- until something else releases them (the key, Latch, HOLD's release,
-- Panic, ...). Same "0 is off" idiom as STRUM_JITTER_REF.
--
-- STRUM GATE TAPER (%, 0..100, default 0): how much shorter each
-- successively-struck note's gate becomes, linearly, down to the last
-- note. 0 means no taper - every note gets STRUM GATE's length unchanged
-- (so TAPER alone does nothing until GATE is also turned up). 100% means
-- the last note's gate shrinks toward almost nothing (floored at a small
-- minimum, so it is still audible rather than inaudibly short), while the
-- first note is unaffected either way - the taper only ever shortens the
-- OTHER end, the same anchoring idiom STRUM_RAMP_REF/STRUM_ACCEL_REF use.
--
-- This only ever applies to a chord sounding DIRECTLY (Shape/SATB with the
-- arp off, the only case sendStrummedNotes() is ever called for) - the
-- arp has its own, entirely separate GATE LENGTH (ref 11).
--
-- Implementation: each auto-gated note's note-off is scheduled with
-- schedule.after(), tracked in strumGateHandles by MIDI note number so a
-- later event that legitimately silences the same pitch first (a key
-- release, Latch, a destination change, Panic, ...) can cancel the stale
-- timer - see cancelStrumGate()/cancelAllStrumGates() below (their actual
-- bodies are assigned once releaseNote() exists, further down; forward
-- declared here so sendStrummedNotes() can already call them). Without
-- that cancellation a stale timer could fire AFTER the same pitch had
-- already been struck again and silently cut the new note short.
-- A known simplification: this does not resolve the case of a stale timer
-- and a fresh re-strike of the very same pitch landing in the same
-- millisecond - that race is not guarded against here.

-- HARMONY KEYBOARD (ref 78, Harmony page, top rows): a read-only
-- piano-keyboard display, drawn by paintHarmonyKeyboard() below, that
-- highlights every note the harmony engine currently has sounding or
-- pooled - a plain passthrough note (Harmony Mode Off), a generated
-- Shape/SATB chord, or a strummed set, all alike. It mirrors `held`
-- directly: that one table already carries every one of those paths (see
-- its own declaration comment near the top of this file), so nothing
-- extra is tracked to tell one source from another - and nothing further
-- is needed when a new source is added later, as long as it goes through
-- pressNote()/releaseNote() like everything else here.
--
-- The control's home slot is slot 6 - row 1, the PAGE'S OWN FIRST control
-- row - which is, empirically, the only slot on this page a custom
-- control actually paints in: every other row tried for a custom control
-- came back solid black on the real instrument, paint callback running
-- cleanly and reporting correct bounds, nothing reaching the screen. The
-- keyboard stays anchored there and reaches its real size (span 6, full
-- width; vspan 1, extending down through the next two rows, to 981x146)
-- by spanning OUT from that one working anchor - control:setBounds() to
-- relocate a control already anchored elsewhere did not work, matching a
-- known-working preset's own custom keyboard, which never calls
-- setBounds() either. The rest of this page's own controls (Harmony Mode,
-- Shape, SATB, Strum, ...) are ordinary list/fader/pad controls, not
-- custom ones, so the row restriction above does not apply to them - they
-- sit beneath the keyboard on the same page without issue.
-- paintHarmonyKeyboard() below still reads control:getBounds() fresh each
-- time rather than assuming the numbers above, so it draws correctly
-- whatever the declared size actually turns out to be.

-- The default, idle view: one octave, C3..C4 (using middle C = C4 = 60).
-- A fixed window would clip a chord that reaches outside it, which is
-- worse than a keyboard that is sometimes wider than it needs to be - so
-- this only ever grows to include every held note, never drops one off
-- the edge, and always grows by whole octaves so the two ends are always
-- a C, never a note stuck mid-octave at the edge of the drawing.
local KEYBOARD_DEFAULT_LOW, KEYBOARD_DEFAULT_HIGH = 36, 96

-- true/false for each of the 12 semitones of an octave, C first - the
-- standard white/black key pattern.
local KEYBOARD_IS_WHITE = {
  [0] = true, [1] = false, [2] = true, [3] = false, [4] = true, [5] = true,
  [6] = false, [7] = true, [8] = false, [9] = true, [10] = false, [11] = true,
}

local function roundDownToC(n) return n - (n % 12) end
local function roundUpToC(n)
  local r = n % 12
  if r == 0 then return n end
  return n + (12 - r)
end

-- The note range to draw, given a set of notes (note -> truthy). Starts
-- from the default window and only ever grows outward to include every
-- note in `notes`, each end rounded out to the nearest C.
local function keyboardRangeFor(notes)
  local low, high = KEYBOARD_DEFAULT_LOW, KEYBOARD_DEFAULT_HIGH
  for n in pairs(notes) do
    if n < low then low = n end
    if n > high then high = n end
  end
  return roundDownToC(low), roundUpToC(high)
end

-- Runs on the display thread - draw only, nothing computed beyond what
-- keyboardRangeFor() above already works out from plain arithmetic.
local function paintHarmonyKeyboard(control)
  local b = control:getBounds()
  local w, h = b[WIDTH], b[HEIGHT]

  -- Draw in the control's own coordinates - (0,0) is its own top left
  -- corner, not the screen's (preset-lua reference 26.3/26.7). This used
  -- to draw from bounds[X]/bounds[Y], which draws the control at twice
  -- its real offset; it happened to still be mostly visible only because
  -- that offset was smaller than the control's own height, so it was
  -- shifted and clipped at the edges rather than invisible outright - the
  -- same bug Clock.paintMonitor had, just less obviously.
  graphics.setColor(0x101010)
  graphics.fillRect(0, 0, w, h)

  local low, high = keyboardRangeFor(Notes.held)

  -- White keys set the width grid; black keys are drawn on top, centred
  -- over the boundary between the white key below them and the one above.
  local whiteNotes = {}
  for n = low, high do
    if KEYBOARD_IS_WHITE[n % 12] then whiteNotes[#whiteNotes + 1] = n end
  end
  local whiteCount = #whiteNotes
  if whiteCount == 0 then return end
  local whiteW = w // whiteCount

  local whiteIndexOf = {}
  for i, n in ipairs(whiteNotes) do whiteIndexOf[n] = i - 1 end

  for i, n in ipairs(whiteNotes) do
    local kx = (i - 1) * whiteW
    local on = Notes.held[n] ~= nil
    graphics.setColor(on and control:getColor() or WHITE)
    graphics.fillRect(kx + 1, 0, whiteW - 2, h)
  end

  local blackW = (whiteW * 3) // 5
  local blackH = (h * 3) // 5
  for n = low, high do
    if not KEYBOARD_IS_WHITE[n % 12] then
      local wi = whiteIndexOf[n - 1]   -- the white key directly below this one
      if wi then
        local kx = (wi + 1) * whiteW - blackW // 2
        local on = Notes.held[n] ~= nil
        graphics.setColor(on and control:getColor() or 0x000000)
        graphics.fillRect(kx, 0, blackW, blackH)
      end
    end
  end
end
-- ARP STEP DISPLAY (ref 83) / ARP GROOVE DISPLAY (ref 84) / ARP RHYTHM
-- DISPLAY (ref 85), ARP page, first/third/fifth control rows - the only
-- three slots confirmed, by throwaway test controls, to actually paint on
-- this page (the same finding as HARMONY_KEYBOARD_REF above, on the
-- Harmony page). Every field below lives on ONE table, `Disp`, rather than
-- as separate top-level locals: the Lua compiler caps a single chunk's
-- local-variable registers at 200, this whole file is one chunk, and it
-- is already close to that ceiling - a dozen more named locals does not
-- fit where one table, costing a single register regardless of how many
-- fields it grows, does.
--
-- ARP STEP DISPLAY: one box per note in the sequence the arp is currently
-- stepping through (orderedNotes()'s own output, so RANGE's octave
-- stacking and Pattern's note set are both in it), each labelled with its
-- note name. The box the arp just visited is outlined in white; its fill
-- says what happened to it - a dark fill for a step the Euclid Gate or
-- Chance rested, the control's own colour for a plain hit, orange for one
-- Accent boosted. Idle (arp off, or nothing held) shows a preview of what
-- WOULD play, with nothing outlined. Status is remembered per box position
-- across ticks and only reset when the sequence's own length changes (a
-- new chord, Pattern or RANGE), so it reads as a short history rather than
-- flickering blank every tick.
--
-- ARP GROOVE DISPLAY: the current GROOVE template's own 16-step shape at
-- GROOVE AMT's live setting - bar height is the velocity multiplier, bar
-- dimness is the gate multiplier, and a small cyan tick along the top of
-- each box is the timing offset, shifted left of centre for an early step
-- and right for a late one - with the step the arp is currently on
-- highlighted white (bar and tick both).
--
-- ARP RHYTHM DISPLAY: the Euclid Gate's own pattern (refs 57/58) on top,
-- the Accent's own pattern (refs 63/64) below it - each its own
-- independent Length, shown as its own hit/rest row, so dialling in
-- "Length 7, Pulses 3" is visual rather than arithmetic. This complements
-- ARP STEP DISPLAY above, which shows gate/accent's EFFECT on whichever
-- note is currently playing; this shows the generators' own SHAPE,
-- regardless of what notes are held. The current position in each cycle
-- (euclidStep/accentStep, already plain module locals) is highlighted
-- white.
--
-- Every paint function reads only Disp's own plain fields, never a
-- control - see 26.7 of the Lua reference (draw only; compute elsewhere
-- and store it). Disp.refreshStepPreview/refreshGrooveDisplay/
-- refreshRhythmDisplay do the computing, filled in further down once
-- orderedNotes()/grooveValuesAt()/euclidPattern() exist for them to call -
-- a table field needs no forward declaration the way a local upvalue
-- would (unlike the isArpOn/cancelStrumGate pattern used elsewhere here).
local Disp = {
  STEP_REF = 83,
  GROOVE_REF = 84,
  RHYTHM_REF = 85,
  RHYTHM_REF2 = 126,  -- Mini only: a second ARP RHYTHM DISPLAY on ARP 3
                       -- (the Gate page) - mk2 has no equivalent since it
                       -- keeps the Euclid/Accent knobs and the one display
                       -- together on a single page. No mk2 counterpart, so
                       -- this is an absolute reference, not offset by
                       -- resolveOffset() the way RHYTHM_REF is. Both
                       -- controls share the exact same paint callback and
                       -- read the exact same Disp fields, so they always
                       -- show identically - see Disp.repaintRhythm() below.

  STATUS_NONE = 0, STATUS_PLAYED = 1, STATUS_RESTED = 2, STATUS_ACCENTED = 3,

  stepBoxNotes = {},      -- array of MIDI note numbers, the current sequence
  stepBoxStatus = {},     -- parallel array, STATUS_*
  stepBoxCurrent = nil,   -- index into stepBoxNotes the arp just visited, or nil

  grooveVel = {},    -- [1..16], velocity multiplier at GROOVE AMT's live setting
  grooveGate = {},   -- [1..16], gate multiplier, likewise
  grooveOffset = {}, -- [1..16], timing offset as a fraction of a step (negative = early)

  gatePattern = {},    -- [1..gateLength], boolean hit/rest
  gateLength = 1,
  accentPattern = {},  -- [1..accentLength], boolean hit/rest
  accentLength = 1,
}

-- MIDI note number to name ("C4" for 60), matching the convention already
-- used for MIN NOTE/MAX NOTE's own labels (C-1..G9) and the comment above
-- KEYBOARD_DEFAULT_LOW/HIGH (middle C = C4 = 60).
local DISP_NOTE_NAMES = { [0] = "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" }

function Disp.noteName(note)
  local octave = (note // 12) - 1
  return DISP_NOTE_NAMES[note % 12] .. octave
end

-- Rebuilds stepBoxNotes/Status from a freshly computed orderedNotes() list,
-- wiping any remembered status - called whenever the sequence's own length
-- changes, so a stale status never lands on a box that now means something
-- else entirely.
function Disp.resetStep(notes)
  local n = {}
  for i, e in ipairs(notes) do n[i] = e.note end
  Disp.stepBoxNotes = n
  local s = {}
  for i = 1, #n do s[i] = Disp.STATUS_NONE end
  Disp.stepBoxStatus = s
  Disp.stepBoxCurrent = nil
end

-- Called every tick, unlike resetStep above: updates the note PITCHES to
-- whatever is actually playing right now, and only wipes the remembered
-- status history when something actually changed - a different chord of
-- the SAME size (LATCH MODE Chord replacing the held chord with a fresh
-- one, say) changes which notes are at each position without changing
-- how many there are, and the old length-only check never caught that -
-- found as note names that never updated while latched.
function Disp.syncStepNotes(notes)
  local changed = (#Disp.stepBoxNotes ~= #notes)
  local n = {}
  for i, e in ipairs(notes) do
    n[i] = e.note
    if not changed and Disp.stepBoxNotes[i] ~= e.note then changed = true end
  end
  Disp.stepBoxNotes = n
  if changed then
    local s = {}
    for i = 1, #n do s[i] = Disp.STATUS_NONE end
    Disp.stepBoxStatus = s
    Disp.stepBoxCurrent = nil
  end
end

-- A left-hand label strip, shared by all three displays, so a glance says
-- what each row is without needing the user guide open - DISP_LABEL_W is
-- small enough that it barely dents the box area (6 fewer px per box on
-- a 24-box STEP row) but is skipped outright were this ever squeezed onto
-- a narrower layout than the mk2's own 981px.
local DISP_LABEL_W = 64

local function paintDispLabel(h, text, color)
  graphics.setBackgroundColor(0x101010)
  graphics.setColor(color)
  graphics.print(2, (h // 2) - 6, text, DISP_LABEL_W - 4, LEFT, BOLD, SMALL)
end

function Disp.paintStep(control)
  local b = control:getBounds()
  local w, h = b[WIDTH], b[HEIGHT]

  graphics.setColor(0x101010)
  graphics.fillRect(0, 0, w, h)
  paintDispLabel(h, "STEPS", control:getColor())

  local areaX = DISP_LABEL_W
  local areaW = w - DISP_LABEL_W

  local n = #Disp.stepBoxNotes
  if n == 0 then
    graphics.setColor(0x505050)
    graphics.print(areaX, (h // 2) - 8, "ARP IDLE - NOTHING HELD", areaW, CENTER, REGULAR, SMALL)
    return
  end

  local boxW = areaW // n
  for i = 1, n do
    local bx = areaX + (i - 1) * boxW
    local status = Disp.stepBoxStatus[i] or Disp.STATUS_NONE
    local fillColor = 0x202020
    if status == Disp.STATUS_RESTED then
      fillColor = 0x303030
    elseif status == Disp.STATUS_ACCENTED then
      fillColor = ORANGE
    elseif status == Disp.STATUS_PLAYED then
      fillColor = control:getColor()
    end

    graphics.setColor(fillColor)
    graphics.fillRect(bx + 1, 2, boxW - 2, h - 4)

    if i == Disp.stepBoxCurrent then
      graphics.setColor(WHITE)
      graphics.drawRect(bx + 1, 2, boxW - 2, h - 4)
    end

    -- The note name, skipped on a box too narrow to hold one legibly -
    -- graphics.print does not clip (26.4), so a box narrower than its own
    -- text would spill into its neighbours rather than just looking tight.
    if boxW >= 32 then
      -- Anti-aliasing blends the text against graphics.setBackgroundColor,
      -- not whatever is actually underneath it (default black) - against a
      -- bright fill (the control's own teal, or accented orange) that
      -- mismatch is what read as fuzzy. Set it to this box's own fill so
      -- the blend is right for every status colour, not just the dark ones.
      graphics.setBackgroundColor(fillColor)
      graphics.setColor(WHITE)
      graphics.print(bx, (h // 2) - 6, Disp.noteName(Disp.stepBoxNotes[i]), boxW, CENTER, REGULAR, SMALL)
    end
  end
end

function Disp.paintGroove(control)
  local b = control:getBounds()
  local w, h = b[WIDTH], b[HEIGHT]

  graphics.setColor(0x101010)
  graphics.fillRect(0, 0, w, h)
  paintDispLabel(h, "GROOVE", control:getColor())

  local areaX = DISP_LABEL_W
  local areaW = w - DISP_LABEL_W

  local n = 16
  local boxW = areaW // n
  local current = (ArpState.grooveStep % n) + 1
  local tickH = 4   -- the timing-offset marker's own strip at the top, kept clear of the bars below it
  local barAreaH = h - tickH - 1
  local tickW = 3

  for i = 1, n do
    local bx = areaX + (i - 1) * boxW
    local vel = Disp.grooveVel[i] or 1.0
    local gate = Disp.grooveGate[i] or 1.0
    local offset = Disp.grooveOffset[i] or 0.0

    local heightFrac = helpers.clamp(vel, 0.1, 1.3) / 1.3
    local barH = math.floor(barAreaH * heightFrac)
    if barH < 2 then barH = 2 end

    local fillColor
    if i == current then
      fillColor = WHITE
    else
      fillColor = graphics.dim(control:getColor(), helpers.clamp(gate, 0.2, 1.0))
    end

    graphics.setColor(fillColor)
    graphics.fillRect(bx + 1, h - barH, boxW - 2, barH)

    -- Timing offset: a small tick along the top strip, shifted left (early)
    -- or right (late) of the box's own centre by how far this step's
    -- GROOVE/Swing-free offset pushes it - 0 sits dead centre. Clamped to
    -- +/-0.5 of a step, comfortably past what GROOVE AMT's own extremes
    -- (template offset up to ~0.33, Amount up to 120%) ever produce.
    local offsetFrac = helpers.clamp(offset, -0.5, 0.5)
    local centreX = bx + (boxW // 2)
    local tickX = centreX + math.floor(offsetFrac * boxW) - (tickW // 2)
    if tickX < bx then tickX = bx end
    if tickX > bx + boxW - tickW then tickX = bx + boxW - tickW end

    graphics.setColor((i == current) and WHITE or 0x00C8FF)
    graphics.fillRect(tickX, 0, tickW, tickH)
  end
end

function Disp.paintRhythm(control)
  local b = control:getBounds()
  local w, h = b[WIDTH], b[HEIGHT]

  graphics.setColor(0x101010)
  graphics.fillRect(0, 0, w, h)

  local halfH = h // 2
  local areaX = DISP_LABEL_W
  local areaW = w - DISP_LABEL_W

  -- Two sub-rows, two labels - each sits centred in its own half-height
  -- band rather than one label spanning the whole control.
  graphics.setBackgroundColor(0x101010)
  graphics.setColor(control:getColor())
  graphics.print(2, (halfH // 2) - 6, "GATE", DISP_LABEL_W - 4, LEFT, BOLD, SMALL)
  graphics.setColor(ORANGE)
  graphics.print(2, halfH + (halfH // 2) - 6, "ACC", DISP_LABEL_W - 4, LEFT, BOLD, SMALL)

  local gn = (Disp.gateLength > 0) and Disp.gateLength or 1
  local gateBoxW = areaW // gn
  local gateCurrent = (ArpState.euclidStep % gn) + 1
  for i = 1, gn do
    local bx = areaX + (i - 1) * gateBoxW
    local fillColor
    if i == gateCurrent then
      fillColor = WHITE
    elseif Disp.gatePattern[i] then
      fillColor = control:getColor()
    else
      fillColor = 0x303030
    end
    graphics.setColor(fillColor)
    graphics.fillRect(bx + 1, 2, gateBoxW - 2, halfH - 4)
  end

  local an = (Disp.accentLength > 0) and Disp.accentLength or 1
  local accentBoxW = areaW // an
  local accentCurrent = (ArpState.accentStep % an) + 1
  for i = 1, an do
    local bx = areaX + (i - 1) * accentBoxW
    local fillColor
    if i == accentCurrent then
      fillColor = WHITE
    elseif Disp.accentPattern[i] then
      fillColor = ORANGE
    else
      fillColor = 0x303030
    end
    graphics.setColor(fillColor)
    graphics.fillRect(bx + 1, halfH + 2, accentBoxW - 2, halfH - 4)
  end
end

-- Repaints every ARP RHYTHM DISPLAY there is - the original (RHYTHM_REF)
-- and, on the Mini, the duplicate on ARP 3 (RHYTHM_REF2) - rather than
-- just the one. Both read the same Disp.gatePattern/accentPattern/
-- ArpState.euclidStep/accentStep fields, so repainting both keeps them
-- showing identically with no separate state to go stale. Tolerant of
-- either not existing yet, the same way every other Disp repaint here is.
function Disp.repaintRhythm()
  local c1 = rcOrNil(Disp.RHYTHM_REF)
  if c1 then c1:repaint() end
  local ok2, c2 = pcall(controls.get, Disp.RHYTHM_REF2)
  if ok2 then c2:repaint() end
end

Strum.gateHandles = {}           -- note -> schedule.after handle, for a pending auto-gate

-- The gate-length multiplier at strum position i of n (1-based), 1.0 =
-- STRUM GATE's full length. Always 1.0 with nothing to taper across (a
-- single note) or TAPER at 0 - the first note is always unaffected, only
-- later notes shrink, same anchoring idiom as Strum.rampMultiplier() and
-- Strum.timingFraction() above.
function Strum.gateMultiplier(i, n)
  if n <= 1 then return 1.0 end
  local taper = cfgValue(Ref.STRUM_GATE_TAPER) / 100   -- 0..1
  if taper <= 0 then return 1.0 end
  local t = (i - 1) / (n - 1)                          -- 0 at the first note, 1 at the last
  return 1 - taper * t
end

-- The pitch order the strum fires its notes in. Up: low to high. Down:
-- high to low. Alternating: outside-in, low/high/low/high.
function Strum.orderNotes(notes)
  local sorted = {}
  for i, n in ipairs(notes) do sorted[i] = n end
  table.sort(sorted)

  local dir = cfgList(44)
  if dir == Strum.DOWN then
    local rev = {}
    for i = #sorted, 1, -1 do rev[#rev + 1] = sorted[i] end
    return rev
  elseif dir == Strum.ALT then
    local alt = {}
    local lo, hi = 1, #sorted
    local takeLow = true
    while lo <= hi do
      if takeLow then
        alt[#alt + 1] = sorted[lo]
        lo = lo + 1
      else
        alt[#alt + 1] = sorted[hi]
        hi = hi - 1
      end
      takeLow = not takeLow
    end
    return alt
  end
  return sorted   -- Strum.UP, the default
end

-- Sends `notes` spread across the current Strum Time, ordered by Strum
-- Direction - the first note at once, the last exactly Strum Time ms
-- later - using midi.at() the same way a swung step is delayed
-- (swingDelayMs() above). `velocityFor(note)` gets each note's velocity.
-- Note-off is not strummed: a release stops everything at once, since how a
-- chord already strumming should react to a mid-strum release is still an
-- open design question (see the note by Strum Time/Direction below).
-- The ramp's velocity multiplier at strum position i of n (1-based) - see
-- the comment above STRUM_RAMP_REF for the shape. Always 1.0 when there
-- is nothing to ramp across (a single note, or STRUM RAMP at 0).
function Strum.rampMultiplier(i, n)
  if n <= 1 then return 1.0 end
  local ramp = cfgValue(Ref.STRUM_RAMP) / 100   -- -1..1
  local t = (i - 1) / (n - 1)                   -- 0 at the first note, 1 at the last
  if ramp > 0 then
    return 1 - ramp * (1 - t)       -- crescendo: builds up to the struck velocity
  elseif ramp < 0 then
    return 1 + ramp * t             -- decrescendo: fades down from the struck velocity
  end
  return 1.0
end

-- STRUM ACCEL's timing fraction at strum position i of n (1-based).
-- Returns a fraction 0..1 of Strum Time; 0 at STRUM ACCEL's default
-- always gives the plain, evenly-spaced fraction (i-1)/(n-1) this always
-- used to send. A positive/negative Accel warps that even spacing into a
-- power curve - t^p or its mirror - which bunches the notes tight at
-- whichever end Accel's sign names and spreads them out at the other:
-- p = 1 at Accel 0 (no warp, linear) rising to ACCEL CURVE's own p_max
-- (ref 73, read live - see the comment above STRUM_ACCEL_CURVE_REF) at
-- |Accel| = 100%.
--
-- A power curve's compression grows much faster than linear as p rises
-- (its "flat" end collapses roughly like t^p), so notes bunched by a
-- steep curve shrink toward simultaneity far quicker than Strum Time can
-- be turned up to compensate - which is exactly why p_max is a knob
-- rather than a constant now: the right trade-off between "feels like
-- acceleration" and "notes stay separable" depends on Strum Time, the
-- chord size and taste, none of which this script can guess at once and
-- for all.
function Strum.timingFraction(i, n)
  if n <= 1 then return 0 end
  local t = (i - 1) / (n - 1)                     -- 0 at the first note, 1 at the last
  local accel = cfgValue(Ref.STRUM_ACCEL) / 100   -- -1..1
  if accel == 0 then return t end

  local pMax = cfgValue(Ref.STRUM_ACCEL_CURVE) / 10   -- 1.0..3.0
  local p = 1 + (pMax - 1) * math.abs(accel)
  if accel > 0 then
    return t ^ p             -- bunches near the end, spreads the start
  end
  return 1 - (1 - t) ^ p     -- bunches near the start, spreads the end
end

function Strum.sendNotes(notes, velocityFor, iface, port, chan, key)
  local strumMs = cfgValue(43)
  local ordered = Strum.orderNotes(notes)
  local n = #ordered
  local baseGateMs = cfgValue(Ref.STRUM_GATE)

  for i, note in ipairs(ordered) do
    -- Clamped to a minimum of 1, never 0 - a note-on with velocity 0 IS a
    -- note-off (recipe/reference 6.2), so a ramp steep enough to reach
    -- zero must not silently turn the first/last note of the strum into
    -- one.
    local velocity = math.floor(helpers.clamp(velocityFor(note) * Strum.rampMultiplier(i, n), 1, 127))
    local delay = (n > 1) and math.floor(strumMs * Strum.timingFraction(i, n)) or 0

    -- STRUM JITTER: a further +/- nudge on top of the curve above, an
    -- absolute number of milliseconds (not scaled by Strum Time - see the
    -- comment above STRUM_JITTER_REF for why). 0 (the default) adds
    -- nothing. Floored at 0 so a large negative jitter on an early note
    -- cannot push its delay negative.
    local jitterMs = cfgValue(Ref.STRUM_JITTER)
    if jitterMs > 0 then
      local offset = (math.random() * 2 - 1) * jitterMs
      delay = math.floor(math.max(0, delay + offset))
    end

    if delay > 0 then
      midi.at(schedule.now() + delay)
      midi.sendNoteOn(iface, port, chan, note, velocity)
      midi.at()
    else
      midi.sendNoteOn(iface, port, chan, note, velocity)
    end
    if debugSentNotesHook then debugSentNotesHook(note) end

    -- STRUM GATE / STRUM GATE TAPER: see the comment above STRUM_GATE_REF.
    -- 0 (the default) is off - nothing scheduled, the note rings exactly
    -- as it always did. `key` is the physical struck key this note was
    -- generated for, needed by expireStrumGateNote()'s bookkeeping.
    if baseGateMs > 0 and key ~= nil then
      Strum.cancelGate(note)   -- a stale timer on this same pitch must not fire late and cut the fresh note short
      local thisGateMs = math.floor(math.max(10, baseGateMs * Strum.gateMultiplier(i, n)))
      Strum.gateHandles[note] = schedule.after(delay + thisGateMs, function()
        Strum.expireGateNote(key, note, iface, port, chan)
      end)
    end
  end
end

-- Snaps `note` to the nearest note of the chosen scale, rooted on Key, and
-- says which of the scale's own degrees it landed on. If the note is
-- already in the scale, it is returned unchanged, at its own degree.
-- Otherwise the nearest scale degree is found by shortest distance around
-- the 12-note circle; a tie (exactly 6 semitones either way) rounds up.
-- For Chromatic, every semitone IS a degree (SCALE_OFFSETS[0] has all 12),
-- so this naturally snaps to nothing (shift 0) while still handing back a
-- degree index - notesForKey() below needs that index for every scale,
-- Chromatic included, to build a shape that stacks correctly from
-- wherever the struck key actually landed, not from Key's own position.
--
-- Returns: quantizedNote, degreeIndex0 (0-based, into `offsets`), offsets
-- (the rotated-offsets array itself, so a caller does not have to
-- recompute it).
local function nearestScaleMatch(note)
  local offsets = Scale.rotatedOffsets(cfgList(34), cfgList(27))
  if not offsets then return note, 0, { 0 } end  -- should not happen; every Scale Shape value has an entry

  local tonic = cfgList(33)
  local rel = (note - tonic) % 12        -- note's position relative to Tonic, 0..11

  local bestShift, bestAbs, bestIdx0 = 0, 12, 0
  for i, degree in ipairs(offsets) do
    local up = (degree - rel) % 12       -- 0..11: semitones up to reach this degree
    local shift = up
    if shift > 6 then shift = shift - 12 end   -- range (-6,6]
    local a = math.abs(shift)
    if a < bestAbs or (a == bestAbs and shift > bestShift) then
      bestAbs = a
      bestShift = shift
      bestIdx0 = i - 1
    end
  end

  return note + bestShift, bestIdx0, offsets
end

local function quantizeToScale(note)
  return (nearestScaleMatch(note))
end

local function latchMode()
  return cfgList(9)
end

-- HOLD (ref 53, Harmony Generator) - while on, a chord already sounding
-- directly (Shape/SATB with the arp off) keeps ringing
-- once the key that struck it is released, instead of stopping. It is
-- read live, like every other config value here. Hold and the arp cannot
-- run together - a struck key's release has nothing to do with the arp,
-- so the two compete for the same keystroke the same way Break Time and
-- the arp already do (see onBreakTimeChange/onArpToggle below).
local function holdActive()
  local c = rcOrNil(53)
  if not c then return false end
  return c:getValue():getValue() == 1
end

local function harmonyMode()
  return cfgList(37)
end

-- Shows only the parameter group the current Harmony Mode actually reads:
-- Off hides both the Shape params (Key/Mode/Scale/Shape/Inversion) and the
-- SATB params (Root Degree/Cantus Primus/Position); Shape shows its own
-- five and hides SATB's three; SATB shows its own three and hides Shape's
-- five. Called whenever Harmony Mode changes (onHarmonyModeChange) and once
-- from preset.onReady() to match whatever loaded.
local function updateChordParamVisibility()
  local mode = harmonyMode()
  local showShape = (mode == HARMONY_MODE_SHAPE)
  local showSatb = (mode == HARMONY_MODE_SATB)

  for _, ref in ipairs(ALWAYS_VISIBLE_REFS) do
    rc(ref):setVisible(true)
  end
  for _, ref in ipairs(SHAPE_PARAM_REFS) do
    rc(ref):setVisible(showShape)
  end
  for _, ref in ipairs(SATB_PARAM_REFS) do
    rc(ref):setVisible(showSatb)
  end
  for _, ref in ipairs(CHORD_PARAM_REFS) do
    rc(ref):setVisible(showShape or showSatb)
  end
end

-- What Harmony Mode was a moment ago, so onHarmonyModeChange() (whose own
-- control value has already changed by the time it runs, like every other
-- value function here) can tell whether the OLD mode left any notes
-- sounding directly that the new mode's cleanup needs to silence.
-- Synced from preset.onReady() and from the end of onHarmonyModeChange()
-- itself.
local lastHarmonyMode = HARMONY_MODE_OFF

-- What a struck key turns into, as an array of note numbers. Off: just the
-- key itself. Shape: the selected shape's full chord, rooted on that key,
-- using the degrees of the current Key/Scale/Mode (the same machinery
-- quantizeToScale's rotation uses).
-- Inversion (Shape mode only, ref 40): rotates the shape's own notes rather
-- than transposing the chord. Inversion N takes the LOWEST N notes of the
-- shape, in pitch order, and moves each of them up an octave - so for a
-- Triad (root, 3rd, 5th: e.g. C E G), inversion 1 moves the root above the
-- 5th (E G C), inversion 2 moves the root and 3rd above it (G C E), and so
-- on. It wraps on the shape's own note count: a shape with only 3 notes
-- sees inversion 3 as a full cycle back to the root position (all three
-- notes raised an octave together is the same shape again), not a 4th kind
-- of voicing a triad does not have.
function Chord.applyInversion(offsets, inversion)
  local sorted = {}
  for i, v in ipairs(offsets) do sorted[i] = v end
  table.sort(sorted)

  local n = #sorted
  if n == 0 then return sorted end

  local inv = inversion % n
  for i = 1, inv do
    local moved = sorted[i] + 12
    -- A shape that already doubles a tone an octave up (every "+8ve"
    -- shape) can have the note this loop is raising land EXACTLY on that
    -- existing duplicate - found on Triad + 8ve, Inversion 1: the root
    -- (60) raised to 72 lands on the shape's own "root + 8ve" note,
    -- already 72, and the two collapse into a single sounding pitch
    -- (debugNotesForKey gave 64,67,72,72, not four distinct notes) - a
    -- voice silently lost, not a deliberate unison. Keep raising by
    -- further octaves until clear of every other note's CURRENT value,
    -- so every inversion of a shape still sounds every one of its notes.
    while true do
      local collides = false
      for j = 1, n do
        if j ~= i and sorted[j] == moved then
          collides = true
          break
        end
      end
      if not collides then break end
      moved = moved + 12
    end
    sorted[i] = moved
  end
  table.sort(sorted)
  return sorted
end

-- VOICE SPLIT (ref 80, Harmony section): a two-handed split voicing - drops
-- whichever note of the generated chord currently sits lowest (after
-- Inversion has already decided that - a struck key's chord in 2nd
-- Inversion drops ITS bass note, the 5th, not the root) down one or two
-- octaves, the way a player's left hand takes the bass note down low while
-- the right hand plays the rest of the chord as voiced. Off (the default)
-- leaves every shape exactly as today. Applies to both Shape and SATB
-- chords (SATB's own Closed/Open/Tintinnabuli positions already spread the
-- four voices relative to each other - this still only moves the single
-- lowest one further down, on top of whichever Position is chosen).
-- Read live, like every other config value here.
--
-- "+ Open" (value 3) additionally raises the note that was second-lowest
-- BEFORE the bass dropped - the bottom of what is left for the right hand
-- - up an octave too, opening a wider gap between the dropped bass and the
-- rest of the chord instead of leaving it sitting right underneath.
--
-- Deliberately not special-cased against the Jazz Triad/Tetrad shapes
-- (16-19), which already drop their own root an octave as part of the
-- shape itself (see SHAPES above): stacking "-2 8ve" on one of those sends
-- the bass two further octaves down, which will rarely be useful, but
-- Voice Split works on whatever is CURRENTLY lowest regardless of how it
-- got there, on purpose - coupling it to specific Shape values would undo
-- the point of it applying to every shape and to SATB alike. The result is
-- still well-defined and floor-clamped either way, just not always a
-- combination worth reaching for.
Chord.SPLIT_OFF, Chord.SPLIT_1OVE, Chord.SPLIT_2OVE, Chord.SPLIT_1OVE_OPEN = 0, 1, 2, 3

-- Shifts notes[idx] by `step` semitones (a multiple of +/-12), and if that
-- lands it on a pitch another note in `notes` already holds, keeps
-- shifting by the same step until it is clear - the same collision
-- applyInversion() above has to guard against, generalised to either
-- direction and reused by both the bass drop and the "+ Open" lift below.
-- Capped at 10 steps (120 semitones): far more than the MIDI range needs,
-- just enough to guarantee this always terminates.
function Chord.shiftNoteClear(notes, idx, step)
  local moved = notes[idx] + step
  for _ = 1, 10 do
    local collides = false
    for i = 1, #notes do
      if i ~= idx and notes[i] == moved then
        collides = true
        break
      end
    end
    if not collides then break end
    moved = moved + step
  end
  return moved
end

function Chord.applyVoiceSplit(notes)
  local splitMode = cfgList(Ref.VOICE_SPLIT)
  if splitMode == Chord.SPLIT_OFF or #notes <= 1 then return notes end

  local drop = (splitMode == Chord.SPLIT_2OVE) and 24 or 12

  local lowestIdx = 1
  for i = 2, #notes do
    if notes[i] < notes[lowestIdx] then lowestIdx = i end
  end

  local result = {}
  for i, n in ipairs(notes) do result[i] = n end

  result[lowestIdx] = math.floor(helpers.clamp(Chord.shiftNoteClear(result, lowestIdx, -drop), 0, 127))

  if splitMode == Chord.SPLIT_1OVE_OPEN and #notes > 2 then
    local secondIdx = nil
    for i = 1, #notes do
      if i ~= lowestIdx and (secondIdx == nil or notes[i] < notes[secondIdx]) then
        secondIdx = i
      end
    end
    if secondIdx then
      result[secondIdx] = math.floor(helpers.clamp(Chord.shiftNoteClear(result, secondIdx, 12), 0, 127))
    end
  end

  return result
end

-- Snaps the struck key to the nearest scale tone FIRST, then builds the
-- shape by stacking scale degrees from there - not by adding flat semitone
-- intervals to the raw, possibly out-of-scale key. This is what keeps the
-- generated chord in key: striking C# with a Major-scale Triad plays the
-- same C-E-G (or D-F-A, if the tie rounds the other way) a diatonic player
-- would reach for, rather than a C#-F-G# shape carried over unchanged from
-- the key the Triad happens to look like in C major. See
-- scaleStepOffset()/nearestScaleMatch() above for the mechanics.
function Chord.notesForShape(note)
  local rootNote, startIndex0, offsets = nearestScaleMatch(note)
  local shapeId = cfgList(36)
  local shape
  if shapeId == Chord.ALT1 then
    shape = Chord.ALT1_BY_DEGREE[startIndex0 % 7] or Chord.ALT_TRIAD
  elseif shapeId == Chord.ALT2 then
    shape = Chord.ALT2_BY_DEGREE[startIndex0 % 7] or Chord.ALT_TRIAD
  else
    shape = Chord.SHAPES[shapeId] or Chord.SHAPES[0]
  end

  local semitoneOffsets = {}
  for _, spec in ipairs(shape) do
    semitoneOffsets[#semitoneOffsets + 1] = Chord.scaleStepOffset(offsets, startIndex0, spec[1] - 1) + 12 * spec[2]
  end
  semitoneOffsets = Chord.applyInversion(semitoneOffsets, cfgList(40))

  local notes = {}
  for _, offset in ipairs(semitoneOffsets) do
    notes[#notes + 1] = math.floor(helpers.clamp(rootNote + offset, 0, 127))
  end
  return notes
end

-- SATB (common-practice four-part harmony). All of it - the CANTUS_* and
-- POSITION_* constants and the functions that build the voicing - lives on
-- this one Satb table, rather than another dozen-odd top-level locals.
-- Same reasoning as the `Ref` table above.
--
-- Satb.SOPRANO etc are CANTUS PRIMUS's own raw values; Satb.POS_CLOSED/
-- POS_OPEN are POSITION's, and Satb.POS_T1_1..POS_T2_2 below (values 2..5)
-- are the Tintinnabuli ones.
local Satb = {}
Satb.SOPRANO, Satb.ALTO, Satb.TENOR, Satb.BASS = 0, 1, 2, 3
Satb.POS_CLOSED, Satb.POS_OPEN = 0, 1
-- Tintinnabuli-style positions (after the technique developed by Arvo
-- Part): "+1"/"+2" is how many triad tones above the alto the soprano
-- sits (first or second position superior); "-1"/"-2" is how many below
-- it the tenor sits (first or second position inferior) - see
-- Satb.notesForKey() below for how Soprano/Tenor are picked from these and
-- how the voices are permuted when Cantus Primus names a voice other
-- than Alto.
Satb.POS_T1_1, Satb.POS_T2_1, Satb.POS_T1_2, Satb.POS_T2_2 = 2, 3, 4, 5

-- The chord whose ROOT DEGREE role is satisfied by the struck note. ROOT
-- DEGREE (I..VII, stored 0..6 like every other list in this script) does
-- NOT name one fixed chord every note gets forced onto - it names the
-- ROLE the struck note itself plays in whatever chord it is harmonizing:
-- I means the note is the chord's own root; III means it is the chord's
-- third (so the actual root sits two scale-steps below it); and so on.
-- This is what makes walking a scale produce a different chord quality
-- for every note, the same way Shape's Triad already does when the note
-- IS the root - striking D with ROOT DEGREE "I" gives D-F-A (ii, minor,
-- because D is the 2nd degree of C major), striking F gives F-A-C (IV,
-- major), and so on, each diatonically correct. ROOT DEGREE "III" shifts
-- every one of those down a third: striking C now harmonizes it as the
-- third of A-C-E (vi).
--
-- The struck note is snapped to its own nearest scale degree first -
-- nearestScaleMatch(), same as Shape - and `rootDegree0 = noteDegree0 -
-- roleSteps` finds which degree the ROOT sits on; from there the root's
-- own absolute pitch and the third/fifth above it follow exactly the way
-- notesForKey() builds Shape's Triad (rootNote + scaleStepOffset()).
--
-- Returns the exact pitch the cantus firmus voice should sing (the
-- snapped note, unchanged) and the chord's three pitch classes (0..11):
-- root, third, fifth.
--
-- CAVEAT - scales shorter than 7 degrees (Pentatonic = 5; Blues, Major
-- Blues, Whole Tone, Augmented = 6): both "root/third/fifth" and ROOT
-- DEGREE's own numbering are built on 7-note-diatonic assumptions and
-- degrade in two separate ways once the scale is shorter.
--
-- 1. ROOT DEGREE starts repeating itself. `roleSteps` (ROOT DEGREE's raw
--    value, 0 for I up to 6 for VII) is wrapped with `% scaleLen` just
--    below, not `% 7` - so on a 5-note scale, roleSteps 5 and 6 (VI, VII)
--    land on the exact same rootDegree0 as 0 and 1 (I, II). VI/VII are
--    then dead controls: turning them does nothing a player can hear that
--    I/II did not already do. A 6-note scale loses one the same way
--    (VII == I); only a 7-note scale has all seven actually distinct.
--
-- 2. "Third" and "fifth" stop being a third and a fifth. They are always
--    "2 scale-steps up" and "4 scale-steps up" (the two scaleStepOffset()
--    calls below), which is a real third/fifth only because a 7-note
--    diatonic scale's own gaps happen to sum close to 4 and 7 semitones
--    by that point. A shorter scale's gaps are wider, so the same "+2
--    steps"/"+4 steps" lands further out - typically a fourth and a
--    minor seventh instead. Worked example, C Major Pentatonic (C D E G
--    A), struck note C: Root Degree I still gives a true third (E, +4
--    semitones) but "fifth" comes out as A, +9 semitones - a sixth, not a
--    fifth. Root Degree II-V all come out as two stacked perfect fourths
--    (e.g. II: A-D-G) rather than anything tertian. Not a bug to fix -
--    stacked fourths are an entirely idiomatic pentatonic/modal-jazz
--    sound - but a different harmonic language from what the same
--    control gives you on a 7-note scale, and it falls out of the
--    arithmetic by coincidence of each scale's gap pattern rather than by
--    design.
--
-- Shape mode's own Triad/Seventh/Ninth/etc (SHAPES, shapeNotesForKey())
-- use this identical degree math and inherit the identical caveat. Only
-- the two Diatonic Alt shapes (SHAPE_ALT1/2) are guarded against it -
-- rebuildShapeOverlay() hides them unless scaleLen == 7, because their
-- per-degree quality table is hand-written for seven degrees specifically
-- and has nothing to say about a fifth or sixth one.
function Satb.chordForNote(note)
  local offsets = Scale.rotatedOffsets(cfgList(34), cfgList(27)) or { 0 }
  local scaleLen = #offsets

  local snappedNote, noteDegree0 = nearestScaleMatch(note)

  local roleSteps = cfgList(50)                       -- 0 for I, 2 for III, 4 for V, ...
  local rootDegree0 = (noteDegree0 - roleSteps) % scaleLen
  local rootNote = snappedNote - Chord.scaleStepOffset(offsets, rootDegree0, roleSteps)

  local root  = rootNote % 12
  local third = (rootNote + Chord.scaleStepOffset(offsets, rootDegree0, 2)) % 12
  local fifth = (rootNote + Chord.scaleStepOffset(offsets, rootDegree0, 4)) % 12

  return snappedNote, { root, third, fifth }
end

-- The nearest note of pitch class `pc` strictly below/above `note` - never
-- `note` itself, even when `note` already has that pitch class.
function Satb.nearestToneBelow(note, pcs)
  local bestNote, bestDist = nil, 13
  for _, pc in ipairs(pcs) do
    local dist = (note - pc) % 12
    if dist == 0 then dist = 12 end
    if dist < bestDist then bestDist, bestNote = dist, note - dist end
  end
  return bestNote
end

function Satb.nearestToneAbove(note, pcs)
  local bestNote, bestDist = nil, 13
  for _, pc in ipairs(pcs) do
    local dist = (pc - note) % 12
    if dist == 0 then dist = 12 end
    if dist < bestDist then bestDist, bestNote = dist, note + dist end
  end
  return bestNote
end

-- The chord tone `n` steps above/below `note` (n = 0, 1, 2, 3 ...), applying
-- nearestChordToneAbove()/Below() repeatedly. Because `note` is always
-- itself a chord tone here (every call site starts from a pitch class in
-- `pcs`), and the "nearest chord tone" relation between the (at most
-- three) pitch classes of a triad is simply each one's immediate neighbour
-- in cyclic pitch-class order, going up n steps and back down n steps (or
-- the reverse) always returns to the note you started from - which is
-- exactly the property satbClosedOrOpen() and satbTintinnabuli() below
-- rely on to place the struck note correctly however many steps away from
-- the chord's reference voice it is built.
function Satb.nthToneAbove(note, pcs, n)
  local result = note
  for _ = 1, n do
    result = Satb.nearestToneAbove(result, pcs)
  end
  return result
end

function Satb.nthToneBelow(note, pcs, n)
  local result = note
  for _ = 1, n do
    result = Satb.nearestToneBelow(result, pcs)
  end
  return result
end

-- Close position: Soprano sits on top, and each lower voice is the nearest
-- chord tone below the one above it - Alto 1 step below Soprano, Tenor 2
-- steps below, Bass 3 steps below (confirmed against the worked example:
-- Soprano C4(60) gives Alto G3(55), Tenor E3(52), Bass C3(48)).
--
-- Open position widens that same stack - Alto 2 steps below Soprano
-- (skipping a chord tone, so a 5th-or-wider gap opens up where Close had
-- roughly a 3rd), Tenor 4 steps below, Bass 6 steps below - rather than
-- Close's 1/2/3. This is a found equivalence, not a rephrasing: the
-- textbook Open recipe ("Alto takes Close's Tenor pitch; Tenor takes
-- Close's Alto pitch, dropped an octave; Bass drops an octave too if that
-- would put it above the new Tenor") and "double every step" produce
-- exactly the same four pitches for a Soprano-anchored chord - confirmed
-- against the same worked example Close uses: Soprano C4(60) gives Alto
-- G3(52), Tenor F2(43), Bass C2(36) either way - but only the doubled-step
-- version has an answer for every OTHER Cantus Primus too.
--
-- Generalized to every Cantus Primus the same way satbTintinnabuli() is:
-- the struck note (already exactly a chord tone, by construction of
-- satbChordForNote()) is the voice CANTUS PRIMUS names, so Soprano is
-- worked out as however many steps ABOVE the struck note the named voice
-- sits below Soprano in the stack (0 for Soprano itself, 1 for Alto, 2 for
-- Tenor, 3 for Bass, each then doubled for Open) - then Alto/Tenor/Bass
-- are built down from that Soprano exactly as always. Soprano Cantus
-- Primus needs no detour: the struck note already IS Soprano.
--
-- The textbook Open recipe is phrased in terms of fixed ROLES ("the
-- alto", "the tenor") and so, taken literally, always transforms whichever
-- pitch happens to be sitting in the Alto/Tenor/Bass slot - which is only
-- harmless when Cantus Primus is Soprano (untouched by the recipe) or,
-- by luck, Tenor (the recipe's new Alto is the old Tenor's pitch,
-- unchanged). For Alto or Bass it silently relocates the very note Cantus
-- Primus was supposed to anchor - found by a test case built to catch
-- exactly this ("the struck note is one of the four voices"). The
-- doubled-step construction avoids that: it is built from the struck note
-- outward in every case, the same principle satbTintinnabuli() already
-- uses, so the voice CANTUS PRIMUS names is always exactly the pitch that
-- was struck, never an octave or a step away from it.
function Satb.closedOrOpen(note, position)
  local pivotNote, pcs = Satb.chordForNote(note)

  local cantus = cfgList(51)
  local voiceIndexFromTop -- 0 Soprano, 1 Alto, 2 Tenor, 3 Bass
  if cantus == Satb.ALTO then
    voiceIndexFromTop = 1
  elseif cantus == Satb.TENOR then
    voiceIndexFromTop = 2
  elseif cantus == Satb.BASS then
    voiceIndexFromTop = 3
  else -- Satb.SOPRANO
    voiceIndexFromTop = 0
  end

  local step = (position == Satb.POS_OPEN) and 2 or 1

  local soprano = Satb.nthToneAbove(pivotNote, pcs, step * voiceIndexFromTop)
  local alto = Satb.nthToneBelow(soprano, pcs, step * 1)
  local tenor = Satb.nthToneBelow(soprano, pcs, step * 2)
  local bass = Satb.nthToneBelow(soprano, pcs, step * 3)

  return {
    math.floor(helpers.clamp(soprano, 0, 127)),
    math.floor(helpers.clamp(alto, 0, 127)),
    math.floor(helpers.clamp(tenor, 0, 127)),
    math.floor(helpers.clamp(bass, 0, 127)),
  }
end

-- Tintinnabuli positions (after the technique developed by Arvo Part),
-- POSITION values T-vce +1/-1 .. +2/-2: soprano is the first or second
-- triad tone above alto ("+1"/"+2"), tenor the first or second below
-- ("-1"/"-2"), and bass is always exactly an octave below alto.
--
-- The struck note (snapped to a chord tone by satbChordForNote(), so it
-- IS one of the triad's three pitch classes) is the voice CANTUS PRIMUS
-- names - not relabelled after the fact, but placed there by first working
-- out what ALTO must be for that to hold, then building the other three
-- voices from that alto exactly as when Cantus Primus is Alto itself.
-- Alto is Soprano's known distance below it, or Tenor's distance above it,
-- or (Bass) built the other way since bass is always alto - 12. Moving UP
-- by a position's step count and back DOWN the same count (or the
-- reverse) returns to the same note - see nthChordToneAbove/Below above -
-- which is what makes the struck note land exactly on the named voice
-- rather than merely close to it. Cantus Primus Alto needs no detour: the
-- struck note already IS alto.
function Satb.tintinnabuli(note, position)
  local pivotNote, pcs = Satb.chordForNote(note)

  local sopranoSteps = (position == Satb.POS_T2_1 or position == Satb.POS_T2_2) and 2 or 1
  local tenorSteps   = (position == Satb.POS_T1_2 or position == Satb.POS_T2_2) and 2 or 1

  local cantus = cfgList(51)
  local altoNote
  if cantus == Satb.SOPRANO then
    altoNote = Satb.nthToneBelow(pivotNote, pcs, sopranoSteps)
  elseif cantus == Satb.TENOR then
    altoNote = Satb.nthToneAbove(pivotNote, pcs, tenorSteps)
  elseif cantus == Satb.BASS then
    altoNote = pivotNote + 12
  else -- Satb.ALTO
    altoNote = pivotNote
  end

  local bassNote = altoNote - 12
  local sopranoNote = Satb.nthToneAbove(altoNote, pcs, sopranoSteps)
  local tenorNote = Satb.nthToneBelow(altoNote, pcs, tenorSteps)

  return {
    math.floor(helpers.clamp(sopranoNote, 0, 127)),
    math.floor(helpers.clamp(altoNote, 0, 127)),
    math.floor(helpers.clamp(tenorNote, 0, 127)),
    math.floor(helpers.clamp(bassNote, 0, 127)),
  }
end

function Satb.notesForKey(note)
  local position = cfgList(52)
  if position == Satb.POS_CLOSED or position == Satb.POS_OPEN then
    return Satb.closedOrOpen(note, position)
  end
  -- Any other POSITION value is one of the four Tintinnabuli settings -
  -- POSITION's declared range stops at 5, so there is nothing else.
  return Satb.tintinnabuli(note, position)
end

-- Transpose (refs 18 Octave, 19 Semitone): up to 2 octaves and up to 12
-- semitones, both bipolar, applied together. Applied here, once, at the
-- point every struck key's actual notes are worked out - whether that is
-- a single passed-through note (Harmony Mode Off), a generated Shape/SATB
-- chord, or a note about to be handed to the arp's own pool - so it acts
-- the same way whether the arp is running or not. advanceStep() below
-- reads the already-transposed note back out of `held` and only quantizes
-- it to the scale; it does not add its own copy.
local function applyTranspose(note)
  return math.floor(helpers.clamp(note + (cfgList(18) * 12) + cfgValue(19), 0, 127))
end

-- Off mode's quantization: Shape and SATB already snap the struck note to
-- the scale as part of building their chord (nearestScaleMatch(), inside
-- shapeNotesForKey()/satbNotesForKey()); Off had nothing of the kind - it
-- passed the bare, transposed note through unchanged, and the ONLY place
-- that ever applied the scale was advanceStep(), which only ever runs
-- while the arp is stepping. With the arp off that left a live-struck
-- note going out unquantized (or, under the old modeSoundsDirectly(),
-- silently not going out at all) - a real gap, since choosing a Scale at
-- all implies wanting it to apply, arp or no arp. Quantizing here closes
-- it: every mode's stored note is now scale-correct the moment it is
-- worked out, and advanceStep()'s own quantizeToScale() on top of it,
-- when the arp IS running, is idempotent - an already-in-scale note
-- matches itself exactly, so nothing changes for the arp's existing
-- behaviour.
local function notesForKey(note)
  local mode = harmonyMode()
  local notes
  if mode == HARMONY_MODE_SATB then
    notes = Satb.notesForKey(note)
  elseif mode ~= HARMONY_MODE_SHAPE then
    notes = { note }
  else
    notes = Chord.notesForShape(note)
  end

  notes = Chord.applyVoiceSplit(notes)

  local transposed = {}
  for i, n in ipairs(notes) do
    local t = applyTranspose(n)
    if mode == HARMONY_MODE_OFF then
      t = math.floor(helpers.clamp(quantizeToScale(t), 0, 127))
    end
    transposed[i] = t
  end
  return transposed
end

-- SRC CHAN (ref 5) value 0 is OFF: blocks MIDI input entirely. No incoming
-- message's channel is ever 0, so this simply never matches while OFF is
-- selected - the same idiom an unmatched interface/port already relies on.
local function srcMatches(midiInput, channel)
  if cfgList(5) == 0 then return false end
  return midiInput.interface == cfgRoutedIface(3, 440) and midiInput.port == cfgRoutedPort(4, 440) and channel == cfgList(5)
end

-- Clock has no channel, so a clock message is matched on interface/port
-- only - its OWN route (CLOCK IFACE/PORT, refs 54/55), not the note
-- source's (3/4): a footswitch or a separate clock box is commonly on a
-- different port from the keyboard sending notes, and the two should be
-- free to differ.
function Clock.srcPortMatches(midiInput)
  return midiInput.interface == cfgRoutedIface(Ref.CLOCK_IFACE, 442) and midiInput.port == cfgRoutedPort(Ref.CLOCK_PORT, 442)
end

function Clock.isExternal()
  return cfgList(Ref.CLOCK_SRC) == Clock.EXTERNAL
end

function Clock.outRoute()
  return ioRoute(ComboRef.CLOCK_OUT, Ref.CLOCK_OUT_IFACE, Ref.CLOCK_OUT_PORT)
end

-- Points the generator at the current CLOCK OUT IFACE/PORT and TEMPO
-- without touching whether it is running - safe to call any time the route
-- or tempo might have changed. A no-op under External clock: the generator
-- is never the one sending in that case (see the comment above
-- CLOCK_OUT_IFACE_REF) - transport.setClockOutputs/setTempo would do
-- nothing harmful either way, but there is nothing for them to do.
-- CLOCK OUT IFACE's "Off" item (value 3, alongside MIDI IO/USB Dev/USB
-- Host): genuinely stops clock going out, rather than just leaving the
-- Internal generator or the External relay with nowhere useful to send it -
-- which is what the route defaulting to MIDI IO/Port 1 when the controls
-- are plain absent would otherwise mean. Read live, like every other
-- config value here.
-- CLOCK OUT ENABLE (ref 87, Config page): a dedicated master on/off for
-- sending any clock-related message (Start/Stop/Continue/Clock) to
-- downstream gear at all - separate from CLOCK OUT IFACE/PORT, which only
-- says WHERE it would go. Default off, so turning the arp on never nudges
-- a downstream device's transport unless this has been explicitly turned
-- on; CLOCK OUT IFACE/PORT can be configured ahead of time and simply sits
-- inert until this is switched on. Read live, like every other config
-- value here - tolerant of the control not existing yet on a device this
-- page has not reached (rcOrNil), in which case it is treated as off,
-- matching the feature's own default.
local function clockOutEnableSwitchOn()
  local c = rcOrNil(Ref.CLOCK_OUT_ENABLE)
  if not c then return false end
  return c:getValue():getValue() == 1
end

function Clock.outputEnabled()
  if not clockOutEnableSwitchOn() then return false end
  return cfgList(Ref.CLOCK_OUT_IFACE) ~= Clock.OFF
end

-- Nothing else needs to react live - Clock.outputEnabled() reads this
-- fresh everywhere it is checked. But switching it mid-stream should take
-- effect immediately rather than waiting for the next Arp On/Off or clock
-- source change: flipping it on while the arp is already running and
-- Internal starts the generator right now; flipping it off stops
-- whatever is currently going out (a harmless no-op under External, which
-- never owns the generator - see Clock.stopOutput()).
function onClockOutEnableChange(valueObject, value)
  if value == 1 then
    if isArpOn() then
      Clock.startOutput()
    end
  else
    Clock.stopOutput()
  end
end

function Clock.refreshOutput()
  if Clock.isExternal() then return end
  if not Clock.outputEnabled() then return end
  local iface, port = Clock.outRoute()
  transport.setClockOutputs{ { interface = iface, port = port } }
  transport.setTempo(cfgValue(1))
end

-- Claims the controller's one shared MIDI clock generator and starts it -
-- called when the arp turns on while CLOCK SRC is Internal. Harmless to
-- call under External too (it just no-ops via Clock.refreshOutput's own
-- guard) so callers do not have to check CLOCK SRC themselves.
function Clock.startOutput()
  if Clock.isExternal() then return end
  if not Clock.outputEnabled() then return end
  Clock.refreshOutput()
  transport.enableClock()
  transport.startClock()
end

-- Sends Stop and releases the generator - called when the arp turns off.
-- disableClock() does not claim and stopClock() does not either, so this
-- is safe to call even when this preset never claimed the clock (External
-- mode, or the clock was never started) - both are no-ops in that case.
function Clock.stopOutput()
  transport.stopClock()
  transport.disableClock()
end

-- How many MIDI clock pulses (24 per quarter note) make up one arp step at
-- the current SYNC rate. syncRates[n] is already in quarter notes (see the
-- table above, e.g. 6/24 for a 16th), so multiplying back by 24 recovers
-- the exact integer pulse count (6, 12, 24, ...) with no rounding drift.
function Clock.ticksPerStep()
  local beatsPerStep = syncRates[cfgList(13)] or 0.25
  local ticks = math.floor(beatsPerStep * 24 + 0.5)
  return (ticks > 0) and ticks or 1
end

-- CLOCK MONITOR (ref 86, Config page): a small read-only display for
-- incoming External clock - a live BPM estimate built from the actual
-- pulse spacing (not TEMPO, which External ignores outright) and a beat
-- flash, so a player can see at a glance whether anything is actually
-- arriving on CLOCK IFACE/PORT. Deliberately no "no clock for Ns" timeout
-- text in this first pass - the flash simply not moving already says
-- that, and a timeout check would need the timer running during External
-- too, which today it never is (stepping is pulse-driven then - see
-- midi.onClock below). Running/Stopped is driven straight off incoming
-- Start/Stop/Continue, same route-matching as the rest of this table.
Clock.monitorPulseCount = 0    -- pulses since the last flash, counts to 24 (one quarter note)
Clock.smoothedPulseMs = nil    -- exponential average of inter-pulse time, for the BPM estimate
Clock.bpmEstimate = 0
Clock.running = false          -- driven by incoming Start/Stop/Continue, External only
Clock.flashActive = false      -- lit briefly once per quarter note

-- Feeds one incoming External pulse into the BPM estimate and the
-- once-per-quarter-note flash. Called from midi.onClock below, after the
-- relay. Everything here is computed up front so Clock.paintMonitor stays
-- draw-only, reading plain fields the way every other paint callback in
-- this file does.
function Clock.registerPulse()
  local now = controller.uptime()
  if Clock.lastPulseAt then
    local interval = now - Clock.lastPulseAt
    if interval > 0 and interval < 2000 then   -- ignore a bogus/first-after-gap interval
      Clock.smoothedPulseMs = Clock.smoothedPulseMs and (Clock.smoothedPulseMs * 0.8 + interval * 0.2) or interval
      Clock.bpmEstimate = 60000 / (Clock.smoothedPulseMs * 24)
    end
  end
  Clock.lastPulseAt = now

  Clock.monitorPulseCount = Clock.monitorPulseCount + 1
  if Clock.monitorPulseCount >= 24 then
    Clock.monitorPulseCount = 0
    Clock.flashActive = true
    rc(Ref.CLOCK_MONITOR):repaint()
    schedule.after(80, function()
      Clock.flashActive = false
      rc(Ref.CLOCK_MONITOR):repaint()
    end)
  end
end

function Clock.paintMonitor(control)
  local b = control:getBounds()
  local w = b[WIDTH]

  -- Draw in the control's own coordinates - (0,0) is its own top left
  -- corner, not the screen's (preset-lua reference 26.3/26.7). Drawing at
  -- bounds[X]/bounds[Y] instead draws the control at twice its real
  -- offset, which is clipped away entirely once that offset exceeds the
  -- control's own height - exactly what happened here after this control
  -- was moved to a slot whose bounds[Y] (198) is past its own height
  -- (122): the whole picture fell outside its own clip region and nothing
  -- reached the screen, with no error anywhere, matching 26.7's own
  -- description of the symptom.
  --
  -- Only roughly the top half of the control's own declared height draws
  -- without clipping mid-glyph, so everything is still drawn inside a
  -- small, fixed slice from its own top rather than using the full
  -- height. SMALL is the largest text size that fits inside that slice.
  local h = 26

  graphics.setColor(0x101010)
  graphics.fillRect(0, 0, w, h)
  graphics.setBackgroundColor(0x101010)

  -- The width of a single slot too - no room for a sentence, so this is a
  -- short label/number plus the beat-flash dot, not a label line.
  local dotSize = 8
  local dotX = w - dotSize - 4
  local dotY = (h // 2) - (dotSize // 2)
  local textW = w - dotSize - 10

  if not Clock.isExternal() then
    graphics.setColor(0xB0B0B0)   -- was 0x505050 - too close to the dark fill to read
    graphics.print(3, (h // 2) - 6, "INT", textW, LEFT, REGULAR, SMALL)
    return
  end

  graphics.setColor(control:getColor())
  local text = Clock.running and (tostring(math.floor(Clock.bpmEstimate + 0.5)) .. " BPM") or "OFF"
  graphics.print(3, (h // 2) - 6, text, textW, LEFT, REGULAR, SMALL)

  graphics.setColor(Clock.flashActive and WHITE or 0x303030)
  graphics.fillRect(dotX, dotY, dotSize, dotSize)
end

-- MIN NOTE / MAX NOTE (refs 60/61, Config page): restrict which incoming
-- notes the arp ever sees, for a keyboard split. Read
-- live, like every other config value here. If the player sets Min above
-- Max the two are swapped rather than treating it as an always-false
-- range.
local function noteInRange(note)
  local minNote = cfgList(60)
  local maxNote = cfgList(61)
  if minNote > maxNote then
    minNote, maxNote = maxNote, minNote
  end
  return note >= minNote and note <= maxNote
end

local function destRoute()
  return cfgRoutedIface(6, 441), cfgRoutedPort(7, 441), cfgList(8)
end

-- DST CHAN (ref 8) value 0 is OFF: MIDI output is withheld entirely, not
-- just muted. The channel destRoute() hands back would be 0 in that case,
-- and every midi.send* call enforces channel 1..16 - passing 0 through
-- would RAISE, not just do nothing - so every send that follows destRoute()
-- must check this first.
local function destActive()
  return cfgList(8) ~= 0
end

-- HOLD RELEASE (ref 35, "RELEASE") and FADE CC (ref 38, "FADE CC"): when
-- HOLD is switched off, a directly-sounding Shape/SATB chord does not just
-- stop dead - it is held at full volume and only the
-- real note-off is sent once RELEASE's seconds (0..20, 0 is the old
-- instant-cutoff behaviour, and the default) have passed.
--
-- MIDI velocity is fixed at note-on and cannot be changed on a note already
-- sounding without sending another note-on - which is a retrigger, exactly
-- what this feature exists to avoid. So an actual fade, rather than a
-- plain delayed cutoff, can only be done with a continuous controller
-- ramped down ahead of the note-off, and which one varies by instrument:
-- FADE CC (0..127, default 7, Channel Volume - the one General MIDI
-- requires every instrument to support) names it, so it can be pointed at
-- whatever the receiving synth actually responds to - Expression (11) is
-- the usual alternative. An instrument that honours neither still gets the
-- delayed cutoff: the chord keeps ringing for RELEASE seconds and then
-- stops, which on its own is a useful "hang time" even with no audible
-- fade.
--
-- The fade is tracked so a note that starts sounding again before it
-- finishes - the same key struck again, Hold switched back on, the
-- destination changed, the preset reloaded - cancels it outright rather
-- than letting a stale scheduled CC or note-off land on the new sound.
-- Everything fade-related - the handles/notes/route state and the
-- scheduling functions - lives on this one HoldFade table, rather than
-- another half-dozen top-level locals. Same reasoning as the `Ref` table
-- above.
local HoldFade = {}
HoldFade.handles = {}   -- schedule.after handles, for cancelling mid-ramp
HoldFade.notes = {}     -- the notes this fade will eventually turn off
HoldFade.route = nil    -- { iface, port, chan } the fade is sending on

-- Cancels any fade in progress. `silence`: when true, also stops the fading
-- notes right now and resets Expression to full - the right thing whenever
-- something else is about to take over the same keystroke or route.
function HoldFade.cancel(silence)
  for _, h in ipairs(HoldFade.handles) do
    schedule.cancel(h)
  end
  HoldFade.handles = {}

  if silence and HoldFade.route and #HoldFade.notes > 0 then
    for _, n in ipairs(HoldFade.notes) do
      midi.sendNoteOff(HoldFade.route.iface, HoldFade.route.port, HoldFade.route.chan, n, 0)
    end
    midi.sendControlChange(HoldFade.route.iface, HoldFade.route.port, HoldFade.route.chan, cfgValue(38), 127)
  end

  HoldFade.notes = {}
  HoldFade.route = nil
end

-- The fade's curve, kept as its own function so it can be checked directly
-- (see the test file) without waiting out a real schedule. Squared, not
-- linear: hearing is roughly logarithmic, so a straight ramp in CC value
-- sounds like it hangs near full volume and then drops away quickly at the
-- end. Squaring (1 - i/steps) front-loads the drop and tapers the tail,
-- closer to how a real amp envelope's release actually decays and to how
-- the ear perceives it. `i` is 0..steps; 0 is full level, `steps` is zero.
function fadeCurveLevel(i, steps)
  local remaining = 1 - i / steps
  return math.floor(127 * remaining * remaining)
end

-- Schedules exactly ONE step ahead, not the whole ramp up front: `after`/
-- `every` share a pool of only 32 live entries per preset (see schedule()
-- in the reference), so a release above 1.6 s (32 steps of 50 ms) queued
-- past the 32nd entry, schedule.after() raised, and the final step - the
-- one that actually sends the note-off - never got scheduled at all. The
-- chord then rang forever. Scheduling one step, which re-schedules the
-- next when it runs, keeps the pool at exactly one entry per fade no
-- matter how long RELEASE is set to.
function HoldFade.scheduleStep(notes, iface, port, chan, i, steps)
  local level = fadeCurveLevel(i, steps)
  local isLast = (i == steps)
  local cc = cfgValue(38)   -- read live: FADE CC can be changed mid-ramp
  local handle = schedule.after(50, function()
    midi.sendControlChange(iface, port, chan, cc, level)
    if isLast then
      for _, n in ipairs(notes) do
        midi.sendNoteOff(iface, port, chan, n, 0)
      end
      midi.sendControlChange(iface, port, chan, cc, 127)
      HoldFade.handles = {}
      HoldFade.notes = {}
      HoldFade.route = nil
    else
      HoldFade.scheduleStep(notes, iface, port, chan, i + 1, steps)
    end
  end)
  HoldFade.handles = { handle }
end

-- Ramps Expression from full down to 0 over RELEASE's current value, then
-- sends the real note-off for every note in `notes` and resets Expression
-- to full again, ready for the next note-on. RELEASE 0 (the default) skips
-- the ramp entirely and stops `notes` at once, exactly as before this
-- feature existed.
function HoldFade.outAndRelease(notes, iface, port, chan)
  HoldFade.cancel(false)

  if #notes == 0 then return end

  local releaseMs = cfgValue(35) * 100   -- RELEASE is tenths of a second, 0..200 (0..20 s)
  if releaseMs <= 0 then
    for _, n in ipairs(notes) do
      midi.sendNoteOff(iface, port, chan, n, 0)
    end
    return
  end

  HoldFade.notes = notes
  HoldFade.route = { iface = iface, port = port, chan = chan }

  local stepMs = 50
  local steps = math.max(1, math.floor(releaseMs / stepMs))
  HoldFade.scheduleStep(notes, iface, port, chan, 1, steps)
end

local function stopCurrent()
  if ArpState.gateHandle then
    schedule.cancel(ArpState.gateHandle)
    ArpState.gateHandle = nil
  end
  if ArpState.currentNote ~= nil then
    if destActive() then
      local iface, port, chan = destRoute()
      midi.sendNoteOff(iface, port, chan, ArpState.currentNote, 0)
    end
    ArpState.currentNote = nil
  end
end

function Notes.sorted()
  local list = {}
  for note in pairs(Notes.held) do list[#list + 1] = note end
  table.sort(list)
  return list
end

function Notes.press(note, velocity)
  if Notes.held[note] == nil then Notes.pressOrder[#Notes.pressOrder + 1] = note end
  Notes.held[note] = velocity
  rc(Ref.HARMONY_KEYBOARD):repaint()
  if not isArpOn() then Disp.refreshStepPreview() end
end

function Notes.release(note)
  if Notes.held[note] == nil then return end
  Notes.held[note] = nil
  for i = #Notes.pressOrder, 1, -1 do
    if Notes.pressOrder[i] == note then table.remove(Notes.pressOrder, i) end
  end
  rc(Ref.HARMONY_KEYBOARD):repaint()
  if not isArpOn() then Disp.refreshStepPreview() end
  if next(Notes.held) == nil then            -- last key up: silence, reset
    stopCurrent()
    ArpState.stepIndex, ArpState.direction = 0, 1
    ArpState.euclidStep = 0
    ArpState.accentStep = 0
    ArpState.grooveStep = 0
  end
end

-- STRUM GATE / STRUM GATE TAPER's actual machinery - defined here, after
-- releaseNote() exists, so it can decrement noteRefCount/releaseNote the
-- same way removeGeneratedNotes() does when a gated note's time is up.
-- (Forward-declared above, where sendStrummedNotes() already needs them.)
Strum.cancelGate = function(note)
  local h = Strum.gateHandles[note]
  if h then
    schedule.cancel(h)
    Strum.gateHandles[note] = nil
  end
end

Strum.cancelAllGates = function()
  for _, h in pairs(Strum.gateHandles) do
    schedule.cancel(h)
  end
  Strum.gateHandles = {}
end

-- Drops `note` out of physical key `key`'s own remembered note list, so a
-- later real release of that key (removeGeneratedNotes) does not decrement
-- noteRefCount a second time for a note this gate timer has already retired.
function Strum.removeNoteFromKeyList(key, note)
  local list = Notes.keyGeneratedNotes[key]
  if not list then return end
  for i = #list, 1, -1 do
    if list[i] == note then table.remove(list, i) end
  end
end

Strum.expireGateNote = function(key, note, iface, port, chan)
  Strum.gateHandles[note] = nil
  local count = (Notes.noteRefCount[note] or 1) - 1
  if count <= 0 then
    Notes.noteRefCount[note] = nil
    Notes.release(note)
    midi.sendNoteOff(iface, port, chan, note, 0)
    if debugSentOffHook then debugSentOffHook(note) end
  else
    -- another contributing key still wants this exact pitch sounding;
    -- just retire THIS key's own share of it.
    Notes.noteRefCount[note] = count
  end
  Strum.removeNoteFromKeyList(key, note)
end

-- Expands `note` per notesForKey() and adds every result to `held`,
-- crediting them to this physical key so releaseGeneratedNotes() can later
-- take back exactly what this key added - no more, no less, even when two
-- struck keys' shapes share a pitch between them (noteRefCount is how a
-- shared pitch outlives the first key that is released).
-- Whether a Shape- or SATB-mode key should sound its generated notes
-- ITSELF, right now, rather than only joining the arp's held-notes pool:
-- true whenever Harmony Mode is Shape or SATB and the arp is not running
-- to arpeggiate the pool for us. With the arp running this stays false and
-- behaviour is exactly as before - the generated notes just join `held`
-- and the arp steps them.
-- Whether a struck key sounds straight to the destination right now, for a
-- given Harmony Mode: whenever the arp isn't running to step the pool
-- instead, the key's own notes are sent directly, for every mode -
-- Shape/SATB their generated chord (unchanged), and Off the struck note
-- itself, LIVE-QUANTIZED to the current Key/Scale/Mode (see the
-- quantization now baked into notesForKey() below). Previously Off's
-- direct path only fired under Chromatic, because the note it sent was
-- never quantized at all - any other scale selected meant the only way to
-- hear your playing follow the scale was to turn the arp on. That was a
-- real gap: a player who wants quantized passthrough with no arp running
-- had no way to get it. Now the quantization happens at key-press time
-- (and, as for every other mode, idempotently again in advanceStep() if
-- the arp later steps the same note), so direct sound is available, and
-- in tune, under every Harmony Mode and every Scale.
function Notes.soundsDirectly(mode)
  return not isArpOn()
end

-- DST CHAN OFF behaves like "nothing to sound to" for the direct path - the
-- arp/chord engine still tracks held notes and updates its displays exactly
-- as ever, it simply never reaches a midi.send* with an unsendable channel.
-- This one change covers every caller that gates its sends on this
-- function: addGenerated/removeGenerated/regenerateShape, onDestChange,
-- onSourceChange, preset.onExit, and the LATCH_CHORD cleanup in keyDown.
function Notes.shouldSoundDirectly()
  return Notes.soundsDirectly(harmonyMode()) and destActive()
end

function Notes.addGenerated(note, velocity)
  HoldFade.cancel(true)   -- a fresh key takes the keystroke back from any fade in progress
  local notes = notesForKey(note)
  local direct = Notes.shouldSoundDirectly()
  local iface, port, chan
  if direct then iface, port, chan = destRoute() end

  local newlySounding = {}
  for _, n in ipairs(notes) do
    local alreadySounding = Notes.noteRefCount[n] ~= nil
    Notes.noteRefCount[n] = (Notes.noteRefCount[n] or 0) + 1
    Notes.press(n, velocity)
    if direct and not alreadySounding then
      newlySounding[#newlySounding + 1] = n
    end
  end

  if direct and #newlySounding > 0 then
    if cfgValue(43) > 0 then
      Strum.sendNotes(newlySounding, function() return velocity end, iface, port, chan, note)
    else
      for _, n in ipairs(newlySounding) do
        midi.sendNoteOn(iface, port, chan, n, velocity)
        if debugSentNotesHook then debugSentNotesHook(n) end
      end
    end
  end

  Notes.keyGeneratedNotes[note] = notes
  Notes.keyVelocity[note] = velocity
end

function Notes.removeGenerated(note)
  local notes = Notes.keyGeneratedNotes[note]
  if not notes then return end
  Notes.keyGeneratedNotes[note] = nil
  Notes.keyVelocity[note] = nil

  local direct = Notes.shouldSoundDirectly()
  local iface, port, chan
  if direct then iface, port, chan = destRoute() end

  for _, n in ipairs(notes) do
    Strum.cancelGate(n)   -- a stale strum-gate timer must not fire after this real release
    local count = (Notes.noteRefCount[n] or 1) - 1
    if count <= 0 then
      Notes.noteRefCount[n] = nil
      Notes.release(n)
      if direct then
        midi.sendNoteOff(iface, port, chan, n, 0)
      end
    else
      Notes.noteRefCount[n] = count
    end
  end
end

-- Shape and Inversion are read once, at the moment a key goes down - unlike
-- Key/Scale/Mode, which quantizeToScale() reads fresh on every single step,
-- so a struck key's generated notes just sit in `held` as fixed pitches
-- until something re-reads them. Changing Shape or Inversion while notes
-- are already sounding calls this to catch every key currently contributing
-- generated notes (still physically down, or latched) up to the new
-- Shape/Inversion - recomputing each one's notes and diffing against what
-- it previously added, rather than silencing everything outright.
-- RETRIGGER (ref 62, "RETRIGGER" on the controller): decides what happens to
-- a note the OLD shape and the NEW shape both contain, when Shape/Inversion
-- (or SATB's Root Degree/Cantus Primus/Position) changes while a key is
-- still held. Legato (0, the default): a note present in both shapes is left
-- ringing untouched - only the notes that left get a note-off and only the
-- notes that arrived get a note-on, so a shared tone (e.g. root/3rd/5th
-- common to "7th" and "7th + 8ve") never clicks or retriggers. Retrigger
-- (1): every note of the OLD shape gets a note-off and every note of the
-- NEW shape gets a note-on, even one a moment's reflection says is "the
-- same" pitch - so switching shapes always re-strikes the whole new chord.
-- Read live, like every other config value here.
local RETRIGGER_LEGATO, RETRIGGER_ON = 0, 1

local function retriggerOnShapeChange()
  return cfgList(15) == RETRIGGER_ON
end

-- HOLD MODE (ref 79, Config page, "General Chord Settings"): governs the
-- sustain behaviour HOLD (ref 53) and its MIDI equivalent (the external
-- switch's CC 125, EXTERNAL_HOLD_CC below) provide - what happens when a
-- key whose generated chord is only still sounding because of that sustain
-- (the physical key is up, HOLD is on) is struck again.
--
--   Synth (0, the default) - a re-strike of a sustaining key is treated as
--     though the chord was already sounding: no new Note On, nothing
--     audibly changes. This is the behaviour the engine always had,
--     unchanged - a struck key whose generated notes are already in
--     noteRefCount never re-fires them (see addGeneratedNotes()).
--   Piano (1) - a re-strike of a sustaining key retriggers it, the way a
--     piano's damper pedal lets a re-struck string ring anew even while
--     the pedal stays down: the sustaining chord is released and struck
--     again fresh, with the new velocity.
--
-- Only the Shape/SATB chord generator sustains a key's notes past its own
-- release at all (plain Harmony Mode Off always releases on key-up - see
-- onKeyUp below) so this only has anything to decide for Shape/SATB; read
-- live, like every other config value here.
local HOLD_MODE_SYNTH, HOLD_MODE_PIANO = 0, 1

local function holdModeIsPiano()
  return cfgList(Ref.HOLD_MODE) == HOLD_MODE_PIANO
end

function Notes.regenerateShape()
  local mode = harmonyMode()
  if mode ~= HARMONY_MODE_SHAPE and mode ~= HARMONY_MODE_SATB then return end

  local direct = Notes.shouldSoundDirectly()
  local iface, port, chan
  if direct then iface, port, chan = destRoute() end

  local retrigger = retriggerOnShapeChange()

  for key, oldNotes in pairs(Notes.keyGeneratedNotes) do
    local newNotes = notesForKey(key)

    local oldSet, newSet = {}, {}
    for _, n in ipairs(oldNotes) do oldSet[n] = true end
    for _, n in ipairs(newNotes) do newSet[n] = true end

    -- Legato: skip a note the new shape still has - it just keeps ringing.
    -- Retrigger: never skip - a shared note is turned off here and turned
    -- back on below, same as any other note.
    for _, n in ipairs(oldNotes) do
      if retrigger or not newSet[n] then
        Strum.cancelGate(n)   -- a stale strum-gate timer must not fire after this real release
        local count = (Notes.noteRefCount[n] or 1) - 1
        if count <= 0 then
          Notes.noteRefCount[n] = nil
          Notes.release(n)
          if direct then
            midi.sendNoteOff(iface, port, chan, n, 0)
          end
        else
          Notes.noteRefCount[n] = count
        end
      end
    end

    local velocity = Notes.keyVelocity[key] or 100
    for _, n in ipairs(newNotes) do
      if retrigger or not oldSet[n] then
        local alreadySounding = Notes.noteRefCount[n] ~= nil
        Notes.noteRefCount[n] = (Notes.noteRefCount[n] or 0) + 1
        Notes.press(n, velocity)
        if direct and not alreadySounding then
          midi.sendNoteOn(iface, port, chan, n, velocity)
        end
      end
    end

    Notes.keyGeneratedNotes[key] = newNotes
  end
end

-- Shape and SATB share Note Priority (ref 49): at most ONE physically-held
-- key contributes its generated chord to the pool at a time - the "active"
-- key, chosen by Last/Highest/Lowest - rather than every held
-- key's chord stacking together. Holding a second key while the first is
-- still down retriggers on it when it wins priority (Last always does;
-- Highest/Lowest only when it actually outranks what is already held);
-- releasing the active key falls back to whichever held key wins next,
-- adding ITS notes fresh (they were never added while it was losing the
-- competition). Off-mode (Harmony Mode Off) is untouched by any of this -
-- every held key still feeds the arp's pool simultaneously, which is the
-- ordinary arpeggiator behaviour and has nothing to do with priority.
Notes.shapeHeld = {}                 -- note -> velocity, physically held keys while Harmony Mode is Shape or SATB
Notes.shapePressOrder = {}           -- press order stack (for Last priority), most recent last
Notes.shapeActiveKey = nil           -- the physical key currently contributing its generated notes, or nil

function Notes.activeShapeKey()
  local priority = cfgList(49)

  if priority == CHORD_PRIORITY_HIGHEST or priority == CHORD_PRIORITY_LOWEST then
    local best = nil
    for n in pairs(Notes.shapeHeld) do
      if best == nil then
        best = n
      elseif priority == CHORD_PRIORITY_HIGHEST and n > best then
        best = n
      elseif priority == CHORD_PRIORITY_LOWEST and n < best then
        best = n
      end
    end
    return best
  end

  for i = #Notes.shapePressOrder, 1, -1 do
    if Notes.shapeHeld[Notes.shapePressOrder[i]] ~= nil then
      return Notes.shapePressOrder[i]
    end
  end
  return nil
end

function Notes.shapeKeyDown(note, velocity, wasAlreadyDown)
  Notes.shapeHeld[note] = velocity
  Notes.shapePressOrder[#Notes.shapePressOrder + 1] = note

  -- HOLD MODE Piano: this exact key is already the active one and its
  -- chord is already sounding (keyGeneratedNotes[note] is set) purely
  -- because it is sustaining - the physical key had been released
  -- (wasAlreadyDown is false: this is a fresh key-down, not a duplicate
  -- Note On for a key that was never let go). Retrigger it: release and
  -- re-strike with the new velocity, rather than leaving it ringing
  -- untouched as Synth mode (and every other mode change here) does.
  if holdModeIsPiano() and note == Notes.shapeActiveKey and not wasAlreadyDown
    and Notes.keyGeneratedNotes[note] ~= nil then
    Notes.removeGenerated(note)
    Notes.addGenerated(note, velocity)
    Notes.shapeActiveKey = note
    return
  end

  local winner = Notes.activeShapeKey()
  if winner ~= nil and winner ~= Notes.shapeActiveKey then
    if Notes.shapeActiveKey ~= nil then
      Notes.removeGenerated(Notes.shapeActiveKey)   -- retract the key that just lost priority
    end
    Notes.addGenerated(winner, Notes.shapeHeld[winner])
    Notes.shapeActiveKey = winner
  end
end

function Notes.shapeKeyUp(note)
  Notes.shapeHeld[note] = nil
  for i = #Notes.shapePressOrder, 1, -1 do
    if Notes.shapePressOrder[i] == note then table.remove(Notes.shapePressOrder, i) end
  end

  if note ~= Notes.shapeActiveKey then return end   -- some other held key already has priority; nothing changes

  -- HOLD on: leave the chord sounding and shapeActiveKey as it stands,
  -- exactly as if the key were still down - a key that then wins priority
  -- still takes over normally on its OWN press (Notes.shapeKeyDown), and
  -- turning HOLD off with nothing held stops it (see onHoldChange).
  if holdActive() then return end

  -- Latch Off: a release really releases, same as ever.
  -- Latch Normal/Chord: its generated notes keep sounding, unchanged -
  -- only the "who is active" bookkeeping moves on, so a still-held key
  -- that was losing the competition can take over the slot and add ITS
  -- shape too (stacking with what is already latched).
  --
  -- That only makes sense while the arp is running: latching exists so
  -- the pool keeps feeding the arp after the key is let go. With the arp
  -- off, nothing ever re-articulates a latched chord again, so skipping
  -- the release here left a directly-sounding chord (Notes.shouldSoundDirectly()
  -- is true once the arp is off) with no path to a Note Off at all -
  -- found as a chord that rang forever until PANIC, and recurred on every
  -- chord played afterwards. So a release always really releases once the
  -- arp is off, latch setting or not.
  if latchMode() == LATCH_OFF or not isArpOn() then
    Notes.removeGenerated(note)
  end
  Notes.shapeActiveKey = nil

  local winner = Notes.activeShapeKey()
  if winner ~= nil then
    Notes.addGenerated(winner, Notes.shapeHeld[winner])
    Notes.shapeActiveKey = winner
  end
end

function Notes.keyDown(note, velocity)
  local mode = latchMode()
  local wasAnyKeyDown = next(Notes.keysDown) ~= nil
  local wasThisKeyDown = Notes.keysDown[note] == true
  Notes.keysDown[note] = true

  -- Chord: a fresh gesture (nothing was physically down a moment ago)
  -- replaces whatever was latched. Several keys pressed together still
  -- build one chord, since wasAnyKeyDown is true for the 2nd key onward.
  -- Normal: never clears here - a new note always adds to what is playing.
  if mode == LATCH_CHORD and not wasAnyKeyDown then
    -- Whatever the previous chord was sounding directly (Shape, arp off)
    -- must stop here too - this wipes noteRefCount without going through
    -- Notes.removeGenerated, which is the only other place that sends the
    -- matching note-off.
    if Notes.shouldSoundDirectly() then
      local iface, port, chan = destRoute()
      for n in pairs(Notes.noteRefCount) do
        midi.sendNoteOff(iface, port, chan, n, 0)
      end
    end
    Notes.held, Notes.pressOrder, Notes.noteRefCount, Notes.keyGeneratedNotes = {}, {}, {}, {}
    Notes.shapeHeld, Notes.shapePressOrder, Notes.shapeActiveKey = {}, {}, nil
    rc(Ref.HARMONY_KEYBOARD):repaint()
  end

  local mode = harmonyMode()
  if mode == HARMONY_MODE_SHAPE or mode == HARMONY_MODE_SATB then
    Notes.shapeKeyDown(note, velocity, wasThisKeyDown)
  else
    -- A re-press of a key HOLD is still sustaining (keyGeneratedNotes[note]
    -- was never cleared because Notes.keyUp below left it ringing) needs HOLD
    -- MODE's own answer, exactly as a Shape/SATB re-press already gets
    -- from Notes.shapeKeyDown: Piano retriggers it fresh with the new
    -- velocity; Synth leaves it ringing untouched - skipping the call to
    -- Notes.addGenerated outright, rather than relying on it to no-op,
    -- since calling it again on the SAME key without releasing it first
    -- would double-count noteRefCount (no new Note On is sent, the note is
    -- already sounding, but the eventual release would then only bring
    -- the count back to 1, not 0, and the note would never go off).
    if Notes.keyGeneratedNotes[note] ~= nil and not wasThisKeyDown then
      if holdModeIsPiano() then
        Notes.removeGenerated(note)
        Notes.addGenerated(note, velocity)
      end
      -- Synth: nothing changes, the sustaining note just keeps ringing.
    elseif Notes.keyGeneratedNotes[note] == nil then
      Notes.addGenerated(note, velocity)
    end
  end
end

function Notes.keyUp(note)
  Notes.keysDown[note] = nil
  local mode = harmonyMode()
  if mode == HARMONY_MODE_SHAPE or mode == HARMONY_MODE_SATB then
    Notes.shapeKeyUp(note)
    return
  end

  -- HOLD (Off mode): leave this note ringing on its own, independently of
  -- every other held note - the same way a sustain pedal keeps every note
  -- ringing after its own key comes up, regardless of how many others are
  -- still held or already released, until the pedal itself is released.
  -- onHoldChange() below releases it, faded over RELEASE TIME, once HOLD
  -- is switched off - the same path Notes.shapeKeyUp already uses for a
  -- sustaining chord.
  if holdActive() then return end

  if latchMode() == LATCH_OFF or not isArpOn() then
    -- Off: a release really releases. Normal and Chord both latch - the
    -- generated notes keep sounding until something explicitly clears them
    -- (a fresh Chord gesture, or Latch going back to Off) - but only while
    -- the arp is running to keep using them. With the arp off a latched
    -- note sounds directly and nothing else will ever release it, so a
    -- release always releases once the arp is off (see Notes.shapeKeyUp above
    -- for the matching Shape/SATB case).
    Notes.removeGenerated(note)
  end
end

-- Note Priority changing with keys currently down re-evaluates who should
-- be sounding right now - without this, picking Highest while a lower key
-- happens to be the one sounding would leave it sounding until the next
-- physical key event. Only meaningful under Shape/SATB; Chord Mode Off has
-- nothing that reads Note Priority.
function onChordPriorityChange(valueObject, value)
  if harmonyMode() == HARMONY_MODE_SHAPE or harmonyMode() == HARMONY_MODE_SATB then
    if next(Notes.shapeHeld) == nil then return end
    local winner = Notes.activeShapeKey()
    if winner ~= nil and winner ~= Notes.shapeActiveKey then
      if Notes.shapeActiveKey ~= nil then
        Notes.removeGenerated(Notes.shapeActiveKey)
      end
      Notes.addGenerated(winner, Notes.shapeHeld[winner])
      Notes.shapeActiveKey = winner
    end
  end
end

-- Whether a pattern is one of the "-8ve" variants, which skip the duplicate
-- note at an octave-repeat seam rather than playing it twice running - see
-- orderedNotes() below.
local function patternSkipsOctaveSeams(pattern)
  return pattern == Pattern.UP_8VE or pattern == Pattern.DOWN_8VE
    or pattern == Pattern.ALT_8VE or pattern == Pattern.ALT2_8VE
end

-- The octave offsets (whole octaves, 0 = the notes as held) to stack the
-- base notes across. RANGE (ref 10) packs direction into the one control
-- rather than a separate one, so the player asked for this directly
-- without reaching for Transpose: values 1..4 are the original "N
-- Octaves" - 0..range-1, stacking UP from the held notes, exactly as
-- before - and values 5..7 are "2/3/4 Octaves Down" - added for playing
-- with the Harmonizer (Chord/SATB), where dropping the arp's range DOWN
-- from a struck chord is the useful direction, not up. Still only ever
-- one direction at a time; a span that needs both ways is still built
-- with Transpose on top of this, same as before.
local RANGE_DOWN_BASE = 4   -- values 5,6,7 are "2,3,4 Octaves Down"

local function octaveOffsets(range)
  if range <= 1 then return { 0 } end

  if range > RANGE_DOWN_BASE then
    local count = range - RANGE_DOWN_BASE + 1   -- 5->2, 6->3, 7->4
    local offsets = {}
    for i = 1, count do offsets[i] = i - count end   -- -(count-1)..0, ascending pitch order
    return offsets
  end

  local offsets = {}
  for i = 1, range do offsets[i] = i - 1 end
  return offsets
end

-- The base note list, expanded across the chosen octave offsets (RANGE -
-- see octaveOffsets() above).
-- Each entry is { note = <midi note>, velocity = <original velocity> } so an
-- octave-shifted step still plays with the velocity of the key that was held.
--
-- When the held notes themselves already span a full octave (the top note
-- is exactly the bottom note plus 12), repeating the whole group a further
-- octave away lands that same pitch twice in a row, at the seam between one
-- repetition and the next. The plain patterns play that duplicate - it is
-- just another step. The "-8ve" patterns skip it, via `skipSeams`.
local function orderedNotes(skipSeams)
  local pattern = cfgList(2)
  local base
  if pattern == Pattern.ASPLAYED then
    base = Notes.pressOrder
  else
    base = Notes.sorted()
  end

  local offsets = octaveOffsets(cfgList(10))
  local list = {}

  for _, offset in ipairs(offsets) do
    for _, n in ipairs(base) do
      local note = n + offset * 12
      if skipSeams and #list > 0 and list[#list].note == note then
        -- the same pitch as the step just added: a seam duplicate, skipped
      else
        list[#list + 1] = { note = note, velocity = Notes.held[n] or 100 }
      end
    end
  end

  return list
end

function Disp.refreshStepPreview()
  Disp.resetStep(orderedNotes(patternSkipsOctaveSeams(cfgList(2))))
  local c = rcOrNil(Disp.STEP_REF)
  if c then c:repaint() end
end

-- An up/down path where the lowest and highest notes are each played twice
-- (once on the way past, once again before turning round), instead of the
-- plain Up/Down's single pass at each end.
local function buildUpDownRepeatSequence(notes)
  local n = #notes
  if n == 0 then return {} end
  if n == 1 then return { notes[1], notes[1] } end

  local seq = { notes[1], notes[1] }
  for i = 2, n - 1 do seq[#seq + 1] = notes[i] end
  seq[#seq + 1] = notes[n]
  seq[#seq + 1] = notes[n]
  for i = n - 1, 2, -1 do seq[#seq + 1] = notes[i] end
  return seq
end

-- The fixed step period (ms), from the current tempo and sync rate only.
-- Swing never touches this: the timer always ticks on an even grid, so
-- setPeriod() is called only when the tempo or sync rate actually change,
-- never once per step - its no-drift guarantee stays intact and a tick's own
-- run time is never added back into the schedule.
local function basePeriodMs()
  local bpm = cfgValue(1)
  local beatsPerStep = syncRates[cfgList(13)] or 0.25
  return (60000 / bpm) * beatsPerStep
end

-- Swing is bipolar, -80..+80%, centred on 0. It shifts the gap between an
-- even (off-beat) step and the odd (on-beat) step right before it:
--   negative -> that gap shortens (the even step effectively arrives sooner)
--   positive -> that gap lengthens (the even step arrives later)
--   zero     -> no effect
--
-- The timer's grid is never touched (see basePeriodMs() above). Instead,
-- exactly one of the two steps in a pair is delayed with midi.at(), and
-- which one depends on the sign:
--   positive swing delays the even step itself, pushing it later and so
--     widening the odd -> even gap, exactly as before;
--   negative swing delays the *preceding* odd step instead. Moving the odd
--     step later, towards the even step that follows it at its fixed time,
--     narrows the very same gap - without ever sending a message "in the
--     past", which a direct negative delay on the even step would require.
-- Both delays are measured from the step's own nominal tick, so neither
-- needs to look ahead to the next one.
local function swingDelayMs()
  local swing = math.abs(cfgValue(12)) / 100   -- 0..0.8
  return math.floor(basePeriodMs() * swing / 3)
end

local function stepIsDelayedBySwing(isOffBeat)
  local swing = cfgValue(12)
  if swing > 0 then return isOffBeat end
  if swing < 0 then return not isOffBeat end
  return false
end

-- Euclidean generator, shared by the Gate (refs 57/58) and the Accent (refs
-- 63/64/65) below - the two are entirely independent patterns, each with
-- its own Length/Pulses and its own cycle position (euclidStep/accentStep),
-- but both built by the same euclidPattern()/euclidGateHit() pair.
--
-- Distributes PULSES onsets as evenly as possible across a cycle of LENGTH
-- steps - the classic Euclidean-rhythm construction - via
-- `(i * pulses) % length < pulses`, the standard Bresenham-line form of it.
-- This always places an onset on step 0: E(1,4) reads X..., E(3,8) reads
-- X..X..X. - the conventional way a Euclidean rhythm is written, and what
-- makes "Length 4, Pulses 1" land the single hit on step 1 rather than
-- partway through the cycle. Rotating it this way changes nothing about
-- which steps are muted (for the Gate) or boosted (for Accent) as a
-- *proportion* - the pattern is exactly as even either way - only which
-- absolute step the cycle starts counting onsets from, and that start is
-- also where it always lands right after a reset (a struck key, a pattern
-- change, ...), so this is the phase a player actually hears as "the one".
--
-- Each cycle position (euclidStep for the Gate, accentStep for Accent) is
-- independent of stepIndex - which note plays and where in a rhythm cycle
-- we are are different counters - and advances once per actual arp step,
-- wrapping at its own LENGTH. Both are reset to 0 everywhere stepIndex
-- itself is reset, so all three always start back in phase together.
-- The Euclidean generator and the groove templates both live on this one
-- Groove table, rather than five further top-level locals. Same reasoning
-- as the `Ref` table above.
local Groove = {}

Groove.patternCache = {}   -- "length:pulses" -> boolean array, 0-based

function Groove.pattern(length, pulses)
  local key = length .. ":" .. pulses
  local cached = Groove.patternCache[key]
  if cached then return cached end

  local pattern = {}
  if pulses <= 0 then
    for i = 0, length - 1 do pattern[i] = false end
  else
    for i = 0, length - 1 do
      pattern[i] = ((i * pulses) % length) < pulses
    end
  end

  Groove.patternCache[key] = pattern
  return pattern
end

function Groove.gateHit(step, length, pulses)
  if length <= 0 then return true end
  if pulses >= length then return true end   -- the default: no gating/no accent
  local pattern = Groove.pattern(length, pulses)
  return pattern[step % length] == true
end

function Disp.refreshRhythmDisplay()
  Disp.gateLength = math.floor(cfgValue(57))
  if Disp.gateLength <= 0 then Disp.gateLength = 1 end
  local gatePulses = math.floor(cfgValue(58))
  local gp = Groove.pattern(Disp.gateLength, gatePulses)
  local gatePattern = {}
  for i = 0, Disp.gateLength - 1 do gatePattern[i + 1] = gp[i] end
  Disp.gatePattern = gatePattern

  Disp.accentLength = math.floor(cfgValue(63))
  if Disp.accentLength <= 0 then Disp.accentLength = 1 end
  local accentPulses = math.floor(cfgValue(64))
  local ap = Groove.pattern(Disp.accentLength, accentPulses)
  local accentPattern = {}
  for i = 0, Disp.accentLength - 1 do accentPattern[i + 1] = ap[i] end
  Disp.accentPattern = accentPattern

  Disp.repaintRhythm()
end

-- GROOVE (refs 66 Template, 67 Amount): a general-purpose 16-step feel
-- template, on top of Swing's own fixed every-second-step delay. Each
-- template gives every one of its 16 steps an offset (a fraction of a
-- step, written late-only in the table below), a velocity multiplier and
-- a gate-length multiplier; grooveStep (its own cycle, independent of
-- stepIndex/euclidStep/accentStep) walks through them once per actual arp
-- step, advanced in advanceStep() the same way euclidStep is - every
-- step, hit or rest, so its phase always matches real time.
--
-- Offsets are fractions of a step: 0.10 = 10% late. Every template's own
-- table is non-negative - late only - but AMOUNT (ref 67) is bipolar
-- (-120..120%) and grooveValuesAt() simply multiplies the table by it
-- (amount/100), so a negative Amount turns every template's own lateness
-- into earliness: offsetFrac comes out negative.
--
-- A step already due "now" cannot be sent earlier than now - nothing in
-- this script can send MIDI into the past (midi.at(), section 6.7 of the
-- Lua reference) - so a negative offsetFrac is never applied to the step
-- it belongs to. Instead it is applied to the step BEFORE it: delaying
-- the preceding note narrows the gap between the two exactly as a
-- negative Swing narrows the gap between an odd and an even step
-- (stepIsDelayedBySwing() above) - the destination step still lands on
-- its own fixed grid time, but the note before it arrives closer to it,
-- which is what "rushing" sounds like.
--
-- Doing that needs one step of look-ahead, because by the time a step
-- with a negative offset is actually due, the note before it has already
-- been sent. advanceStep() reads grooveStep's own offset for the step it
-- is about to send AND peeks grooveStep+1's offset in the same call,
-- before advancing the cycle - so if the UPCOMING step wants to rush, the
-- delay is added to THIS step's send instead, right here, with no state
-- carried between calls. grooveStep's cycle position advances every
-- actual arp step regardless of whether a note is gated out by the
-- Euclidean gate or Chance below, so the peek is always exactly one real
-- step ahead in the template - but if THIS step (the one being delayed
-- to make room for the rush) is itself gated out and sends nothing, the
-- rush has nothing to attach to and is simply lost rather than passed
-- further back; a deliberate simplification, not a bug, for the same
-- reason the Euclid/Accent/Chance generators are themselves allowed to
-- interact in surprising ways.
--
-- vel and gate are multipliers, 1.0 = unchanged. A note on precision: this
-- firmware's Lua numbers are single-precision floats, and 0.4 specifically
-- does not round-trip exactly through the crossfade formula below
-- (1 + (vel-1)*amount) - at Amount 100% it lands on floor(100*0.4) = 39,
-- not the mathematically clean 40, while every other fraction used across
-- these templates (0.3, 0.5, 0.55, 0.6, 0.65, ... 0.95) rounds as expected.
-- Confirmed directly on the instrument with run_lua. Harmless by ear (1
-- part in 127 of velocity), but worth knowing before assuming an exact
-- test expectation is a typo - see the Reggae Skank test case for the one
-- place this actually mattered.
Groove.templates = {
  [0] = { name = "Straight",
    offset = { 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0 },
    vel    = { 1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1 },
    gate   = { 1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1 } },

  -- Shuffle delays every second 16th by a third of a step, which gives a 
  -- triplet feel, and softens and shortens those notes. That's 100% swing, 
  -- with velocity and gate shaping added.
  [1] = { name = "Shuffle",
    offset = { 0,.33,0,.33, 0,.33,0,.33, 0,.33,0,.33, 0,.33,0,.33 },
    vel    = { 1,.7,.9,.7,  1,.7,.9,.7,  1,.7,.9,.7,  1,.7,.9,.7 },
    gate   = { 1,.6,1,.6,   1,.6,1,.6,   1,.6,1,.6,   1,.6,1,.6 } },

  -- Lazy has small, uneven offsets that never repeat exactly the same way 
  -- within a bar. This is a more "human" feel than a single swing value.
  [2] = { name = "Lazy",
    offset = { 0,.08,.03,.12, 0,.06,.04,.14, 0,.08,.03,.12, 0,.06,.04,.16 },
    vel    = { 1,.6,.8,.65,   .95,.6,.8,.7,  1,.6,.8,.65,   .95,.6,.8,.75 },
    gate   = { .9,.7,.9,.7,   .9,.7,.9,.7,   .9,.7,.9,.7,    .9,.7,.9,.8 } },

  -- Tight and aggressive: barely-there micro-delays (not mechanically
  -- zero, but close) plus hard beat accents and short, punchy gates
  -- everywhere else - driving rather than relaxed, the opposite character
  -- from Shuffle/Lazy's drag.
  [3] = { name = "Push",
    offset = { 0,.02,0,.04, 0,.02,0,.04, 0,.02,0,.04, 0,.02,0,.06 },
    vel    = { 1,.85,.95,.8, 1,.85,.95,.8, 1,.85,.95,.8, 1,.85,.95,.75 },
    gate   = { .6,.5,.6,.5,  .6,.5,.6,.5,  .6,.5,.6,.5,  .6,.5,.6,.45 } },

  -- A much deeper, more drunken drag than Lazy: the off-16ths lag hard
  -- behind the beat and dip far in velocity, while each group's downbeat
  -- stays loud and anchored - the exaggerated "MPC halftime" effect.
  [4] = { name = "Halftime",
    offset = { 0,.18,.08,.22, 0,.14,.10,.28, 0,.18,.08,.22, 0,.14,.10,.30 },
    vel    = { 1,.5,.75,.45,  1,.55,.7,.4,   1,.5,.75,.45,  1,.55,.7,.35 },
    gate   = { 1,.55,.85,.5,  1,.6,.8,.45,   1,.55,.85,.5,  1,.6,.8,.4 } },

  -- Not a drag at all: steps land on the grid (every offset is 0) and the
  -- feel comes entirely from a 3-2 son-clave-like accent placement -
  -- strong hits on steps 1, 5, 8, 11, 13 of 16 - with everything else
  -- pulled quiet and a touch short. A syncopated counterpart to the
  -- swing-based templates above.
  [5] = { name = "Clave",
    offset = { 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0 },
    vel    = { 1,.5,.5,.5, 1,.5,.5,1,  .5,.5,1,.5,  1,.5,.5,.5 },
    gate   = { .9,.6,.6,.6, .9,.6,.6,.9, .6,.6,.9,.6, .9,.6,.6,.6 } },

  -- Quantized - trance gating is always on the grid, no drag at all - but
  -- the gate pulses hard in a four-on-the-floor pumping pattern, like a
  -- sidechain-compressed pluck/gate effect, with matching velocity accents
  -- on the downbeat of each group of four.
  [6] = { name = "Trance Gate",
    offset = { 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0 },
    vel    = { 1,.7,.85,.7, 1,.7,.85,.7, 1,.7,.85,.7, 1,.7,.85,.7 },
    gate   = { 1,.2,.55,.2, 1,.2,.55,.2, 1,.2,.55,.2, 1,.2,.55,.2 } },

  -- Every other template groups in fours; this one groups in threes
  -- (strong-weak-weak, repeating every 3 steps across the 16-step cycle)
  -- with a gentle forward lean on the second of each triplet - a lilting,
  -- dance-like sway rather than a drag.
  [7] = { name = "Waltz Lilt",
    offset = { 0,.10,.05, 0,.10,.05, 0,.10,.05, 0,.10,.05, 0,.10,.05, 0 },
    vel    = { 1,.65,.7,  1,.65,.7,  1,.65,.7,  1,.65,.7,  1,.65,.7,  1 },
    gate   = { 1,.6,.65,  1,.6,.65,  1,.6,.65,  1,.6,.65,  1,.6,.65,  1 } },

  -- A loose, bell-pattern-derived syncopation: drags slightly throughout
  -- (looser than Push, lighter than Halftime) with an extra off-beat
  -- accent around step 11, closer to a talking-drum/bell-pattern feel
  -- than a straight swing.
  [8] = { name = "Afrobeat",
    offset = { 0,.06,.09,.04, 0,.07,.09,.05, 0,.06,.09,.04, 0,.07,.09,.05 },
    vel    = { 1,.55,.65,.6,  1,.55,.65,.6,  1,.55,.9,.6,   1,.55,.65,.6 },
    gate   = { .85,.55,.6,.55, .85,.55,.6,.55, .85,.55,.75,.55, .85,.55,.6,.55 } },

  -- No consistent drag or accent logic at all - abrupt velocity jumps and
  -- choppy, uneven gate lengths at fixed-but-irregular positions, for a
  -- broken/stuttering feel rather than anything groove-like in the
  -- traditional sense.
  [9] = { name = "Glitch Stutter",
    offset = { 0,0,0,.12, 0,0,.18,0, 0,.09,0,0, 0,0,.15,0 },
    vel    = { 1,.3,1,.9, .2,1,.3,1, .9,.2,1,.3, 1,.9,.2,1 },
    gate   = { .3,.9,.3,.2, .9,.3,.9,.2, .3,.9,.2,.9, .3,.2,.9,.3 } },

  -- A one-drop feel: the downbeats sit quiet and sustained in the
  -- background while the off-beats (the "ands" - steps 3, 7, 11, 15) get
  -- both the accent and a short, choppy gate, plus a touch of lazy drag -
  -- the classic upstroke-guitar skank rather than anything built around
  -- the downbeat.
  [10] = { name = "Reggae Skank",
    offset = { 0,0,.12,0, 0,0,.12,0, 0,0,.12,0, 0,0,.12,0 },
    vel    = { .4,.4,1,.4, .4,.4,1,.4, .4,.4,1,.4, .4,.4,1,.4 },
    gate   = { .9,.9,.35,.9, .9,.9,.35,.9, .9,.9,.35,.9, .9,.9,.35,.9 } },

  -- Unlike Glitch Stutter (deliberately erratic), this has a real pulse
  -- under it: main accents at steps 1, 7, 10, 13 - the classic
  -- funky-drummer/break snare placement - with quiet, short "ghost note"
  -- hits filling the gaps and a hint of forward drag on the ghosts only,
  -- so it rolls rather than scatters.
  [11] = { name = "Breakbeat Roll",
    offset = { 0,.05,.05,.05, .05,.05,0,.05, .05,0,.05,.05, 0,.05,.05,.05 },
    vel    = { 1,.3,.3,.35,   .3,.3,1,.3,    .3,1,.3,.3,    1,.3,.3,.35 },
    gate   = { .8,.3,.3,.3,   .3,.3,.8,.3,   .3,.8,.3,.3,   .8,.3,.3,.3 } },

  -- Named after J Dilla's signature MPC feel: a deep, irregular drag where
  -- no two groups of four offset the same way (unlike Lazy/Halftime's
  -- repeating pattern) - deliberately "drunk" rather than a clean swing -
  -- paired with uneven velocity dips on the off-16ths so the bounce reads
  -- as loose and human rather than mechanically delayed.
  [12] = { name = "Dilla Bounce",
    offset = { 0,.05,.15,.07, 0,.12,.18,.05, 0,.06,.16,.09, 0,.10,.20,.06 },
    vel    = { 1,.55,.75,.6,  .95,.5,.8,.55,  1,.6,.7,.5,    .9,.45,.75,.6 },
    gate   = { .8,.55,.7,.5,  .75,.5,.65,.5,  .8,.55,.7,.5,  .75,.45,.65,.55 } },

  -- A Brazilian samba feel: tight, barely-there forward-leaning offsets
  -- (never a full drag, closer to Push's urgency) under a surdo/tamborim-
  -- style accent pattern - strong hits on steps 1, 4, 7, 10 and 13, the
  -- characteristic syncopated samba pulse - with short, punchy gates
  -- throughout rather than Push's uniform shortness.
  [13] = { name = "Samba Push",
    offset = { 0,.02,0,.05, 0,.03,0,.06, 0,.02,0,.05, 0,.03,0,.07 },
    vel    = { 1,.6,.7,.95,  .6,.7,1,.6,   .7,.95,.6,.7,  1,.6,.7,.6 },
    gate   = { .6,.5,.55,.6, .5,.55,.6,.5, .55,.6,.5,.55, .6,.5,.55,.5 } },
}

-- The template's raw offset/vel/gate at `step` (0-based, wraps on 16),
-- crossfaded toward "straight" by GROOVE AMOUNT: 0 leaves every step exactly
-- as it would be with no groove at all, whatever the template; 100 is the
-- template's own numbers, unchanged; 120 exaggerates them by a further
-- fifth; negative values invert them (see the comment above) - vel/gate
-- genuinely invert (a quietened/shortened step gets louder/longer instead),
-- and offsetFrac comes out negative, which the CALLER (advanceStep) turns
-- into rushing the preceding step rather than applying here. Read live,
-- like every other config value here, so a template or amount change takes
-- effect on the very next step rather than waiting for a reset.
function Groove.valuesAt(step)
  local template = Groove.templates[cfgList(Ref.GROOVE_TEMPLATE)] or Groove.templates[0]
  local amount = cfgValue(Ref.GROOVE_AMOUNT) / 100
  local idx = (step % 16) + 1

  local offsetFrac = (template.offset[idx] or 0) * amount
  local velMult = 1 + ((template.vel[idx] or 1) - 1) * amount
  local gateMult = 1 + ((template.gate[idx] or 1) - 1) * amount

  return offsetFrac, velMult, gateMult
end

function Disp.refreshGrooveDisplay()
  for i = 0, 15 do
    local offset, vel, gate = Groove.valuesAt(i)
    Disp.grooveOffset[i + 1] = offset
    Disp.grooveVel[i + 1] = vel
    Disp.grooveGate[i + 1] = gate
  end
  local c = rcOrNil(Disp.GROOVE_REF)
  if c then c:repaint() end
end

-- A clock-grid control (SYNC, TEMPO) may have changed while the arp is
-- running. Applying timer.setPeriod()/transport.setTempo() the instant the
-- knob moves would retime whatever step is already in flight, landing the
-- next note at an unpredictable offset depending on exactly when, mid-step,
-- the value changed - so neither control's own value function touches the
-- timer at all (see onSyncChange/onTempoChange below): only the control's
-- own touch/end event arms Clock.pendingTimingApply, and this commits it,
-- but only once the CURRENT step has actually finished. Called from the
-- top of advanceStep() - the one function every stepping path (the timer,
-- an external clock pulse, or a fresh Start/Arp-On) funnels through - so
-- the commit always lands exactly on a step boundary, never mid-step.
function Clock.commitTimingIfPending()
  if not Clock.pendingTimingApply then return end
  Clock.pendingTimingApply = false
  Clock.currentTicksPerStep = Clock.ticksPerStep()
  if not Clock.isExternal() then
    -- The Internal timer's own period is now fixed (ARP_POLL_MS, see the
    -- comment above it) - a Tempo/Sync change no longer needs to retime
    -- the timer itself, only basePeriodMs(), which the poll loop reads
    -- fresh the moment it advances ArpState.nextDueAt for the step after
    -- this one - so the staging (committed only at a step boundary, never
    -- mid-step) is unchanged.
    transport.setTempo(cfgValue(1))
  end
end

local function advanceStep(isOffBeat, dueAt)
  Clock.commitTimingIfPending()
  stopCurrent()                        -- one note at a time, right now
  local pattern = cfgList(2)
  local notes = orderedNotes(patternSkipsOctaveSeams(pattern))
  local n = #notes
  if n == 0 then
    Disp.resetStep(notes)
    rc(Disp.STEP_REF):repaint()
    return
  end

  local entry

  if pattern == Pattern.UP or pattern == Pattern.UP_8VE or pattern == Pattern.ASPLAYED then
    ArpState.stepIndex = (ArpState.stepIndex % n) + 1
    entry = notes[ArpState.stepIndex]

  elseif pattern == Pattern.DOWN or pattern == Pattern.DOWN_8VE then
    ArpState.stepIndex = (ArpState.stepIndex % n) + 1
    entry = notes[n - ArpState.stepIndex + 1]

  elseif pattern == Pattern.ALT or pattern == Pattern.ALT_8VE then
    if n == 1 then
      ArpState.stepIndex = 1
    else
      ArpState.stepIndex = ArpState.stepIndex + ArpState.direction
      if ArpState.stepIndex >= n then
        ArpState.stepIndex = n
        ArpState.direction = -1
      elseif ArpState.stepIndex <= 1 then
        ArpState.stepIndex = 1
        ArpState.direction = 1
      end
    end
    entry = notes[ArpState.stepIndex]

  elseif pattern == Pattern.ALT2 or pattern == Pattern.ALT2_8VE then
    local seq = buildUpDownRepeatSequence(notes)
    local sn = #seq
    if sn == 0 then
      entry = nil
    else
      ArpState.stepIndex = (ArpState.stepIndex % sn) + 1
      entry = seq[ArpState.stepIndex]
    end

  elseif pattern == Pattern.STEP_UP then
    -- The lowest note alternates with the rest, rising: C E C G C ...
    if n == 1 then
      entry = notes[1]
    else
      local cycle = 2 * (n - 1)
      ArpState.stepIndex = (ArpState.stepIndex % cycle) + 1
      if ArpState.stepIndex % 2 == 1 then
        entry = notes[1]
      else
        entry = notes[1 + (ArpState.stepIndex // 2)]
      end
    end

  elseif pattern == Pattern.STEP_DOWN then
    -- The highest note alternates with the rest, falling: G E G C G ...
    if n == 1 then
      entry = notes[1]
    else
      local cycle = 2 * (n - 1)
      ArpState.stepIndex = (ArpState.stepIndex % cycle) + 1
      if ArpState.stepIndex % 2 == 1 then
        entry = notes[n]
      else
        entry = notes[n - (ArpState.stepIndex // 2)]
      end
    end

  elseif pattern == Pattern.RANDOM then
    ArpState.stepIndex = math.random(1, n)
    entry = notes[ArpState.stepIndex]

  elseif pattern == Pattern.RANDOM2 then
    -- Never the same note twice running - reroll on a repeat, unless there
    -- is only the one note and a repeat is all there is.
    if n == 1 then
      entry = notes[1]
    else
      local pick
      repeat
        pick = math.random(1, n)
      until pick ~= ArpState.stepIndex
      ArpState.stepIndex = pick
      entry = notes[ArpState.stepIndex]
    end

  elseif pattern == Pattern.RANDOM3 then
    -- A shuffled permutation of every note, then a fresh shuffle for the
    -- next pass - never two passes alike, but every note once per pass.
    if (not ArpState.shuffledOrder) or (#ArpState.shuffledOrder ~= n) or (ArpState.shuffledPos > #ArpState.shuffledOrder) then
      ArpState.shuffledOrder = {}
      for i = 1, n do ArpState.shuffledOrder[i] = i end
      for i = n, 2, -1 do
        local j = math.random(1, i)
        ArpState.shuffledOrder[i], ArpState.shuffledOrder[j] = ArpState.shuffledOrder[j], ArpState.shuffledOrder[i]
      end
      ArpState.shuffledPos = 1
    end
    entry = notes[ArpState.shuffledOrder[ArpState.shuffledPos]]
    ArpState.shuffledPos = ArpState.shuffledPos + 1

  else
    ArpState.stepIndex = (ArpState.stepIndex % n) + 1
    entry = notes[ArpState.stepIndex]
  end

  -- Keep the step display's own note list in sync with what is actually
  -- playing - only rebuilt (and its remembered status wiped) when the
  -- sequence's own length changes, so a stable chord/pattern keeps its
  -- status history across ticks instead of flickering blank every time.
  Disp.syncStepNotes(notes)

  -- Which box in the step display `entry` is - found by identity, since
  -- every pattern branch above sets `entry` to one of `notes`'s own
  -- elements (even ALT2's rearranged `seq` copies the same references),
  -- so this works the same way regardless of which pattern is selected.
  local displayIndex = nil
  if entry then
    for i, v in ipairs(notes) do
      if v == entry then
        displayIndex = i
        break
      end
    end
  end

  if entry then
    -- Euclidean gate (refs 57/58): checked first, deterministic. Both this
    -- and CHANCE below can be in play together - either one resting a step
    -- is enough to rest it.
    local euclidLength = math.floor(cfgValue(57))
    local euclidPulses = math.floor(cfgValue(58))
    local euclidHit = Groove.gateHit(ArpState.euclidStep, euclidLength, euclidPulses)
    ArpState.euclidStep = ArpState.euclidStep + 1

    -- Groove (refs 66/67): this step's timing/velocity/gate deviation, read
    -- and advanced here, in phase with euclidStep - every step, hit or
    -- rest, so the 16-step cycle always lands on real time regardless of
    -- what the Euclid gate, Chance or the Accent gate do to it below.
    -- `grooveNextOffsetFrac` peeks the UPCOMING step's offset, one ahead of
    -- `grooveStep` itself, before the cycle advances - see the comment
    -- above grooveValuesAt() for why: when the upcoming step wants to
    -- rush (a negative offset, only possible with a negative Amount), the
    -- delay it implies is added to THIS step's send below instead, since
    -- nothing can be sent earlier than the upcoming step's own fixed grid
    -- time.
    local grooveOffsetFrac, grooveVelMult, grooveGateMult = Groove.valuesAt(ArpState.grooveStep)
    local grooveNextOffsetFrac = Groove.valuesAt((ArpState.grooveStep + 1) % 16)
    ArpState.grooveStep = (ArpState.grooveStep + 1) % 16

    if not euclidHit then
      if displayIndex then
        Disp.stepBoxStatus[displayIndex] = Disp.STATUS_RESTED
        Disp.stepBoxCurrent = displayIndex
      end
      rc(Disp.STEP_REF):repaint()
      rc(Disp.GROOVE_REF):repaint()
      Disp.repaintRhythm()
      return
    end

    -- ArpChance: each step has this percent chance of actually sounding.
    -- The sequence still advances either way - a skipped step is a rest,
    -- not a repeat of the same step next time.
    local chancePercent = cfgValue(16)
    if chancePercent < 100 and math.random(1, 100) > chancePercent then
      if displayIndex then
        Disp.stepBoxStatus[displayIndex] = Disp.STATUS_RESTED
        Disp.stepBoxCurrent = displayIndex
      end
      rc(Disp.STEP_REF):repaint()
      rc(Disp.GROOVE_REF):repaint()
      Disp.repaintRhythm()
      return
    end

    -- Accent (refs 63 Length, 64 Pulses, 65 Amount%): a second, independent
    -- Euclidean pattern - the same generator as the Gate above, with its
    -- own Length/Pulses and its own cycle position (accentStep) - that
    -- boosts velocity on a hit instead of muting the step. A hit moves the
    -- velocity toward 127 by AMOUNT percent of the remaining headroom;
    -- Amount 0 (the default) leaves it untouched whatever Length/Pulses
    -- are set to, which is what keeps the arp unaffected until Amount is
    -- actually turned up.
    local accentLength = math.floor(cfgValue(63))
    local accentPulses = math.floor(cfgValue(64))
    local accentHit = Groove.gateHit(ArpState.accentStep, accentLength, accentPulses)
    ArpState.accentStep = ArpState.accentStep + 1
    local accentAmountPercent = 0   -- read below only on a hit; 0 means "no audible boost"

    -- ARP VEL (ref 59): 0 keeps the struck velocity; 1-127 overrides it to a
    -- fixed value before Accent/Groove run, so they vary around a constant
    -- baseline instead of around however hard the key was actually hit.
    local velocity = entry.velocity or 100
    local velocityOverride = math.floor(cfgValue(Ref.ARP_VELOCITY))
    if velocityOverride > 0 then
      velocity = velocityOverride
    end
    if accentHit then
      accentAmountPercent = cfgValue(65)
      velocity = math.floor(helpers.clamp(velocity + (127 - velocity) * (accentAmountPercent / 100), 0, 127))
    end
    -- Groove's own velocity multiplier, on top of Accent's.
    velocity = math.floor(helpers.clamp(velocity * grooveVelMult, 0, 127))

    -- Transpose was already applied once, when this note was worked out
    -- for the struck key (see notesForKey()/applyTranspose() above) - it
    -- is already baked into entry.note here, whether this came from a
    -- plain Off-mode key or a generated Shape/SATB chord. Key/Scale still
    -- snaps the result to the chosen scale fresh on every step, same as
    -- always, before it is clamped and sent.
    local note = math.floor(helpers.clamp(quantizeToScale(entry.note), 0, 127))
    local iface, port, chan = destRoute()

    -- Swing delays exactly one step per pair, chosen by the sign - see
    -- stepIsDelayedBySwing() above. Groove's own per-step offset is
    -- independent of, and additive with, swing's - both end up as one
    -- combined midi.at() delay. The timer's own period is never touched by
    -- either.
    --
    -- Groove's own offsetFrac only delays THIS step when it is positive
    -- (late); when it is negative (rush, only reachable with a negative
    -- Amount) it was never applicable to this step at all - it was
    -- already spent on the PRECEDING step, on that step's own turn through
    -- here, via grooveNextOffsetFrac. What groveNextOffsetFrac adds now is
    -- the mirror of that: if the UPCOMING step wants to rush, this step's
    -- send is delayed instead, narrowing the gap between the two exactly
    -- as negative Swing narrows the gap between an odd and even step.
    local grooveOwnDelayMs = (grooveOffsetFrac > 0) and math.floor(basePeriodMs() * grooveOffsetFrac) or 0
    local grooveRushDelayMs = (grooveNextOffsetFrac < 0) and math.floor(basePeriodMs() * -grooveNextOffsetFrac) or 0
    local grooveDelayMs = grooveOwnDelayMs + grooveRushDelayMs
    local delay = (stepIsDelayedBySwing(isOffBeat) and swingDelayMs() or 0) + grooveDelayMs

    -- The note-on is always scheduled through midi.at(), never sent bare -
    -- `dueAt` is this step's own precise, independently-advancing grid
    -- time under Internal lookahead polling (see ARP_POLL_MS above), or
    -- nil for an immediate start/External-pulse-driven step that has no
    -- grid of its own, in which case "now" is exactly right. Either way
    -- the real send is handed to the MIDI schedule thread at a known
    -- target instead of trusting whatever moment this application-thread
    -- callback happened to run at (reference 6.7, 22.3).
    local baseTime = dueAt or schedule.now()
    local sendAt = baseTime + delay

    -- DST CHAN OFF: the sequence keeps stepping and the displays keep
    -- tracking it, but nothing actually goes out - see destActive() above.
    if destActive() then
      midi.at(sendAt)
      midi.sendNoteOn(iface, port, chan, note, velocity)
      midi.at()                          -- back to sending at once
      ArpState.currentNote = note
      if debugSentNotesHook then debugSentNotesHook(note) end
    end

    if displayIndex then
      -- Orange only when the accent is actually audible: a step can match
      -- the Accent Euclidean pattern (accentHit) while ACC AMOUNT is 0, in
      -- which case the "boost" is literally zero and nothing sounds any
      -- different - marking it orange anyway was found to mislead (a step
      -- lit up with no ACC AMOUNT turned up at all).
      Disp.stepBoxStatus[displayIndex] =
        (accentHit and accentAmountPercent > 0) and Disp.STATUS_ACCENTED or Disp.STATUS_PLAYED
      Disp.stepBoxCurrent = displayIndex
    end
    rc(Disp.STEP_REF):repaint()
    rc(Disp.GROOVE_REF):repaint()
    Disp.repaintRhythm()

    -- Groove's gate multiplier shortens/lengthens the gate on top of
    -- GATE LENGTH itself, clamped back into a sendable 1..100%.
    local gatePercent = helpers.clamp(cfgValue(11) * grooveGateMult, 1, 100)
    if gatePercent < 100 then
      -- schedule.after()'s delay is measured from NOW, which under
      -- Internal lookahead polling can be a few ms before the note's own
      -- precise sendAt (that gap is exactly the point of ARP_LOOKAHEAD_MS)
      -- - so the gate-off has to count that gap too, or it would fire
      -- slightly early relative to the note it is meant to cut off.
      local untilSend = math.max(0, sendAt - schedule.now())
      local gateMs = untilSend + math.floor(basePeriodMs() * gatePercent / 100)
      local noteForGate = note
      ArpState.gateHandle = schedule.after(gateMs, function()
        if ArpState.currentNote == noteForGate then
          stopCurrent()
        end
      end)
    end
  end
end

-- The one function every stepping path funnels through: the timer
-- (Internal), an external clock pulse once enough have accumulated
-- (External), and a fresh Start/Arp-On's immediate first note (see bug 3 of
-- the clock review - starting used to leave the first step silent for a
-- whole period/pulse-count before sounding anything). Advances both LFOs,
-- refreshes the groove display cache, then calls advanceStep() itself and
-- toggles swing parity - exactly the block midi.onClock/timer.onTick used
-- to duplicate inline.
local function fireStep(isOffBeat, dueAt)
  Lfo.advanceStep()
  Lfo.apply()
  Disp.refreshGrooveDisplay()
  advanceStep(isOffBeat, dueAt)
  ArpState.swingParity = (ArpState.swingParity + 1) % 2
end

-- An external momentary/latching MIDI switch can drive Arp On/Off and HOLD
-- directly, on its own CC numbers and its own routing - refs 45/46/47
-- (Switch Interface/Port/Channel, Config page) - separate from the arp's
-- own source routing (3/4/5), since a footswitch is commonly on a
-- different port (USB Host, say) from the keyboard/synth sending notes,
-- and the two should be free to differ. CC 126 toggles Arp On/Off (ref 29);
-- CC 125 toggles HOLD (ref 53) - both standard on/off switch CCs, 0 = off,
-- 127 = on (>=64 counts as on, so a switch that is not perfectly 0/127
-- still works). setValue() (not updateValue()) is used deliberately: it
-- runs the control's own function (onArpToggle/onHoldChange) exactly as
-- pressing the pad by hand would, so every existing on/off side effect
-- (silencing notes, starting/stopping the timer) happens the same way
-- regardless of what triggered it.
local EXTERNAL_ARP_CC = 126
local EXTERNAL_HOLD_CC = 125

-- Mod wheel (CC 1): forwarded from the source route to the destination
-- route for the same reason pitch bend and aftertouch are (see
-- midi.onPitchBend etc. below) - it is channel-wide, like pitch bend and
-- channel aftertouch, so it forwards unchanged, just on the other channel.
local MOD_WHEEL_CC = 1

local function switchRoute()
  return cfgList(45), cfgList(46), cfgList(47)
end

-- Nothing needs to react live to the Switch Interface/Port/Channel
-- controls changing - switchRoute() above reads them fresh on every
-- incoming CC, the same way srcMatches()/destRoute() already do for the
-- arp's own routing. The function exists only because every control here
-- is declared with one (recipe 33.14).
function onSwitchRouteChange(valueObject, value)
end

-- MIN NOTE / MAX NOTE: nothing needs to react live either - noteInRange()
-- above reads both fresh on every incoming note. The functions exist only
-- because every control here is declared with one.
function onMinNoteChange(valueObject, value)
end

function onMaxNoteChange(valueObject, value)
end

-- SATB (refs 50/51/52) - ROOT DEGREE, CANTUS PRIMUS, POSITION. Each
-- changes what satbNotesForKey() builds, so - exactly like Shape and
-- Inversion above - a chord already sounding is brought up to date rather
-- than left stale until the key is re-struck.
function onRootDegreeChange(valueObject, value)
  if shapeUpdateIsImmediate() then
    Notes.regenerateShape()
  end
end

function onCantusPrimusChange(valueObject, value)
  if shapeUpdateIsImmediate() then
    Notes.regenerateShape()
  end
end

function onPositionChange(valueObject, value)
  if shapeUpdateIsImmediate() then
    Notes.regenerateShape()
  end
end

-- RETRIGGER: nothing needs to react live - retriggerOnShapeChange() above
-- reads it fresh every time regenerateShapeNotes() runs. The function
-- exists only because every control here is declared with one.
function onShapeRetriggerChange(valueObject, value)
end

-- HOLD MODE: nothing needs to react live - holdModeIsPiano() above reads it
-- fresh on every key press. The function exists only because every control
-- here is declared with one (recipe 33.14).
function onHoldModeChange(valueObject, value)
end

-- VOICE SPLIT: nothing needs to react live - applyVoiceSplit() above reads
-- it fresh every time a chord is generated. The function exists only
-- because every control here is declared with one (recipe 33.14).
function onVoicingSplitChange(valueObject, value)
end

-- SHAPE UPDATE also decides whether RETRIGGER's own choice currently means
-- anything: with On Next Chord, nothing is updated on an already-sounding
-- chord, so Legato/Retrigger has nothing to act on until the next struck
-- key. RETRIGGER is hidden in that case to avoid suggesting it does
-- something it cannot right now - shown again the moment SHAPE UPDATE goes
-- back to Immediate.
function onShapeUpdateModeChange(valueObject, value)
  local retriggerControl = rcOrNil(15)
  if retriggerControl then
    retriggerControl:setVisible(value == SHAPE_UPDATE_IMMEDIATE)
  end
end

function midi.onControlChange(midiInput, channel, controllerNumber, value)
  -- Mod wheel pass-through and the external switch share this one callback
  -- but watch two different, independent routes - a footswitch is commonly
  -- on a different port from the keyboard sending notes and CC1 (see the
  -- comment above EXTERNAL_ARP_CC) - so each is checked on its own route
  -- rather than one shared guard at the top.
  if controllerNumber == MOD_WHEEL_CC and srcMatches(midiInput, channel) and destActive() then
    local iface, port, chan = destRoute()
    midi.sendControlChange(iface, port, chan, MOD_WHEEL_CC, value)
  end

  local swIface, swPort, swChan = switchRoute()
  if midiInput.interface ~= swIface or midiInput.port ~= swPort or channel ~= swChan then return end

  if controllerNumber == EXTERNAL_ARP_CC then
    rc(29):getValue():setValue(value >= 64 and 1 or 0)
  elseif controllerNumber == EXTERNAL_HOLD_CC then
    rc(53):getValue():setValue(value >= 64 and 1 or 0)
  end
end

function midi.onNoteOn(midiInput, channel, noteNumber, velocity)
  if not srcMatches(midiInput, channel) then return end
  if not noteInRange(noteNumber) then return end

  if velocity == 0 then
    Notes.keyUp(noteNumber)
  else
    Notes.keyDown(noteNumber, velocity)
  end
end

function midi.onNoteOff(midiInput, channel, noteNumber, velocity)
  if not srcMatches(midiInput, channel) then return end
  if not noteInRange(noteNumber) then return end
  Notes.keyUp(noteNumber)
end

-- Pitch bend, channel aftertouch, poly aftertouch and mod wheel (CC 1, in
-- midi.onControlChange below) are not notes - the arp/Shape engines above
-- have nothing to say about them - but a keyboard playing
-- into this preset on its own source channel can still want them heard by
-- the synth on the destination channel. Without this they are simply never
-- forwarded: the preset only ever reads notes from the source and writes
-- notes (or generated chords) to the destination, so anything else the
-- keyboard sends just stops here.
--
-- Pitch bend and channel aftertouch are channel-wide, not per-note, so
-- they forward exactly as received - only the route (and so the channel)
-- changes, same as every note.
function midi.onPitchBend(midiInput, channel, value)
  if not srcMatches(midiInput, channel) then return end
  if not destActive() then return end
  local iface, port, chan = destRoute()
  midi.sendPitchBend(iface, port, chan, value)
end

function midi.onAfterTouchChannel(midiInput, channel, pressure)
  if not srcMatches(midiInput, channel) then return end
  if not destActive() then return end
  local iface, port, chan = destRoute()
  midi.sendAfterTouchChannel(iface, port, chan, pressure)
end

-- Poly (key) aftertouch names a note, and in Shape/SATB mode the note the
-- key actually sounds on the destination is not the struck note - it is
-- whatever notesForKey() generated for it (keyGeneratedNotes[noteNumber]).
-- So it is forwarded to every one of THOSE notes instead of the raw key
-- number, which would not correspond to anything sounding. In Harmony Mode
-- Off (plain arp or nothing at all) the struck note and the sounding note
-- are the same thing, so it forwards unchanged.
function midi.onAfterTouchPoly(midiInput, channel, noteNumber, pressure)
  if not srcMatches(midiInput, channel) then return end
  if not destActive() then return end
  local iface, port, chan = destRoute()

  local mode = harmonyMode()
  if mode == HARMONY_MODE_SHAPE or mode == HARMONY_MODE_SATB then
    local notes = Notes.keyGeneratedNotes[noteNumber]
    if notes then
      for _, n in ipairs(notes) do
        midi.sendAfterTouchPoly(iface, port, chan, n, pressure)
      end
    end
  else
    midi.sendAfterTouchPoly(iface, port, chan, noteNumber, pressure)
  end
end

-- External clock: steps are driven by incoming MIDI clock pulses (24 per
-- quarter note) rather than the timer. Only live while the arp is on and
-- CLOCK SRC is External; a clock from any other interface/port is ignored,
-- same as notes are gated by srcMatches(). SYNC still sets the beat value
-- per step (ticksPerStepFor()); TEMPO is not read at all here.
function midi.onClock(midiInput)
  if not Clock.isExternal() then return end
  if not Clock.srcPortMatches(midiInput) then return end

  -- Relay the incoming clock on to CLOCK OUT IFACE/PORT, regardless of
  -- whether the arp itself is running - a clock repeater, not just an arp
  -- feature. See the comment above CLOCK_OUT_IFACE_REF. Skipped entirely
  -- when CLOCK OUT IFACE is set to Off.
  if Clock.outputEnabled() then
    local outIface, outPort = Clock.outRoute()
    midi.sendClock(outIface, outPort)
  end

  Clock.registerPulse()

  if not isArpOn() then return end
  if not Clock.running then return end   -- a pulse arriving after Stop must not advance the sequence

  Clock.extCount = Clock.extCount + 1
  local ticksPerStep = Clock.currentTicksPerStep or Clock.ticksPerStep()
  if Clock.extCount >= ticksPerStep then
    Clock.extCount = Clock.extCount - ticksPerStep
    fireStep(ArpState.swingParity == 1)
  end
end

function midi.onStart(midiInput)
  if not Clock.isExternal() then return end
  if not Clock.srcPortMatches(midiInput) then return end
  if Clock.outputEnabled() then
    local outIface, outPort = Clock.outRoute()
    midi.sendStart(outIface, outPort)
  end
  Clock.extCount = 0
  Clock.pendingTimingApply = false
  Clock.currentTicksPerStep = Clock.ticksPerStep()
  ArpState.stepIndex, ArpState.direction = 0, 1
  ArpState.euclidStep = 0
  ArpState.accentStep = 0
  ArpState.grooveStep = 0
  ArpState.swingParity = 0
  stopCurrent()
  Clock.running = true
  Clock.monitorPulseCount = 0
  rc(Ref.CLOCK_MONITOR):repaint()

  -- The first step sounds the instant Start arrives, not after waiting a
  -- full step's worth of clock pulses - the same bug as an Arp-On start,
  -- fixed the same way (see fireStep() and onArpToggle()).
  if isArpOn() then
    fireStep(false)
  end
end

function midi.onContinue(midiInput)
  if not Clock.isExternal() then return end
  if not Clock.srcPortMatches(midiInput) then return end
  if Clock.outputEnabled() then
    local outIface, outPort = Clock.outRoute()
    midi.sendContinue(outIface, outPort)
  end
  Clock.extCount = 0
  Clock.running = true
  rc(Ref.CLOCK_MONITOR):repaint()
end

function midi.onStop(midiInput)
  if not Clock.isExternal() then return end
  if not Clock.srcPortMatches(midiInput) then return end
  if Clock.outputEnabled() then
    local outIface, outPort = Clock.outRoute()
    midi.sendStop(outIface, outPort)
  end
  stopCurrent()
  Clock.running = false
  Clock.flashActive = false
  rc(Ref.CLOCK_MONITOR):repaint()
end

function timer.onTick(ticks)
  -- Internal clock's lookahead poll - see the comment above ARP_POLL_MS.
  -- Runs far more often than a musical step, and does nothing at all
  -- unless a step has actually come due; External stepping is driven
  -- entirely by incoming clock pulses (midi.onClock) and never reaches
  -- here while CLOCK SRC is External.
  if Clock.isExternal() then return end
  if not ArpState.nextDueAt then return end   -- not running (arp off, or not yet started)

  local now = schedule.now()

  -- A genuine stall (heavy display work, a slow paint, ...) can leave the
  -- grid more than a full period behind real time. Catch it up silently -
  -- advance the grid and the swing parity (and, approximately, which note
  -- the pattern would be on, the same way this file always has) without
  -- sounding every skipped step, so a stall produces silence rather than
  -- a burst of notes landing on top of each other.
  while (now - ArpState.nextDueAt) > basePeriodMs() do
    local pattern = cfgList(2)
    local n = #orderedNotes(patternSkipsOctaveSeams(pattern))
    if n > 0 then ArpState.stepIndex = (ArpState.stepIndex % n) + 1 end
    ArpState.swingParity = (ArpState.swingParity + 1) % 2
    Lfo.advanceStep()
    ArpState.nextDueAt = math.floor(ArpState.nextDueAt + basePeriodMs())
  end

  -- Fire every step that has now come within ARP_LOOKAHEAD_MS of due,
  -- each scheduled through midi.at() at its own exact nominal time - see
  -- advanceStep()'s `dueAt` parameter. Kept an integer throughout -
  -- midi.at()/schedule.after() both want one, and basePeriodMs() (from
  -- BPM division) is a float.
  while ArpState.nextDueAt - now <= ARP_LOOKAHEAD_MS do
    local dueAt = ArpState.nextDueAt
    local isOffBeat = (ArpState.swingParity == 1)
    fireStep(isOffBeat, dueAt)
    ArpState.nextDueAt = math.floor(dueAt + basePeriodMs())
    now = schedule.now()
  end
end

-- Staged, not applied live - see the comment above Clock.commitTimingIfPending().
-- TEMPO is a long, continuous fader drag (20..300): applying
-- transport.setTempo()/timer.setPeriod() on every intermediate value the
-- knob passes through, while the application thread may also be taking a
-- live external clock, risks starving MIDI delivery on a long sweep - the
-- same class of bug DIVISION/SYNC had. The real effect is armed by
-- onTempoTouchEnd (the control's touch/end event, wired in the project)
-- and committed at the next natural step boundary.
function onTempoChange(valueObject, value)
end

function onTempoTouchEnd(control, source, event, potId, valueId, value)
  Clock.pendingTimingApply = true
end

-- Test backdoor: the test library drives a knob with test.turn(), which
-- calls the value's function exactly as a real turn would, but it has no
-- way to simulate the physical touch lifting - see onTempoTouchEnd above.
function debugTempoTouchEnd()
  onTempoTouchEnd(nil, nil, nil, nil, nil, nil)
end

-- CLOCK OUT IFACE/PORT: nothing needs to react live in External mode -
-- midi.onClock/onStart/onStop/onContinue above read the route fresh on
-- every relayed message. In Internal mode, re-point the generator at the
-- new route without disturbing whether it is running.
function onClockOutRouteChange(valueObject, value)
  Clock.refreshOutput()
end

function formatBpm(valueObject, value)
  return value .. " BPM"
end

function formatPercent(valueObject, value)
  return value .. " %"
end

function formatSwing(valueObject, value)
  if value > 0 then return "+" .. value .. " %" end
  return value .. " %"
end

-- GROOVE AMT (ref 67) is bipolar, like Swing - show the sign on a positive
-- value so "turned up" and "turned down" read unambiguously from the
-- number alone.
function formatGrooveAmount(valueObject, value)
  if value > 0 then return "+" .. value .. " %" end
  return value .. " %"
end

function formatStrumTime(valueObject, value)
  return value .. " ms"
end

-- Strum Time/Direction (refs 43/44) are for the "Strum chord" feature:
-- spreading a Shape-mode chord's notes out in time instead of sounding
-- them all at once, since it is generated instantly from a single
-- keystroke. See sendStrummedNotes()/orderForStrum() above for the engine:
-- when Strum Time is above 0, a chord's notes fire one by one, ordered by
-- Strum Direction (Up/Down/Alternating), spread evenly so the first sounds
-- at once and the last exactly Strum Time ms later. Note-off is NOT
-- strummed - a release (or a fresh trigger replacing the chord) stops
-- every sounding note at once, which is the simplest answer to "how does a
-- chord already strumming react to a mid-strum release" and the one open
-- question this round settles by not trying to be clever about it. Latch
-- interaction is otherwise unaffected: Strum plugs into
-- addGeneratedNotes() (Shape mode sounding directly) and changes nothing
-- about when it is called.
--
-- STRUM RAMP (ref 71) shapes velocity across the strummed notes, and
-- STRUM ACCEL (ref 72) shapes their timing - two independent controls,
-- each usable on its own or together, since a timing curve strong enough
-- to feel like real acceleration made a shared knob's velocity range
-- collapse (see the comment above STRUM_RAMP_REF for why they were split
-- apart). See STRUM_RAMP_REF/strumRampMultiplier() and
-- STRUM_ACCEL_REF/strumTimingFraction() above, both applied inside
-- sendStrummedNotes() itself.
--
-- Strum and the ARP still cannot run together, because they are two
-- different engines competing for the same single keystroke:
--
--   Strum Time raised above 0 while the arp is on turns the arp off.
--   The arp turned on while Strum Time is above 0 sets Strum Time to 0.
--
-- Each direction sets the OTHER control via setValue() (not updateValue()),
-- so it runs through that control's own function and every normal
-- on/off side effect (silencing notes, stopping the timer) exactly as if
-- the player had reached for that control directly - and each guards on
-- the condition that would otherwise fire it again, so the two functions
-- do not recurse into each other.
function onStrumTimeChange(valueObject, value)
  if value > 0 and isArpOn() then
    rc(29):getValue():setValue(0)   -- Arp: off, Strum Time has the keystroke now
  end
end

function onStrumDirectionChange(valueObject, value)
end

-- STRUM RAMP: nothing needs to react live - strumRampMultiplier() above
-- reads it fresh on every strummed note. The function exists only because
-- every control here is declared with one (recipe 33.14).
function onStrumRampChange(valueObject, value)
end

function formatStrumRamp(valueObject, value)
  if value > 0 then return "+" .. value .. " %" end
  return value .. " %"
end

-- STRUM ACCEL: nothing needs to react live - strumTimingFraction() above
-- reads it fresh on every strummed note. The function exists only because
-- every control here is declared with one (recipe 33.14).
function onStrumAccelChange(valueObject, value)
end

function formatStrumAccel(valueObject, value)
  if value > 0 then return "+" .. value .. " %" end
  return value .. " %"
end

-- ACCEL CURVE: nothing needs to react live - strumTimingFraction() above
-- reads it fresh on every strummed note. The function exists only because
-- every control here is declared with one (recipe 33.14).
function onStrumAccelCurveChange(valueObject, value)
end

-- STRUM JITTER: nothing needs to react live - sendStrummedNotes() above
-- reads it fresh on every strummed note. The function exists only because
-- every control here is declared with one (recipe 33.14).
function onStrumJitterChange(valueObject, value)
end

-- Stored as tenths (10..30); shown as the actual exponent, 1.0..3.0.
function formatStrumAccelCurve(valueObject, value)
  return string.format("%.1f", value / 10)
end

-- STRUM GATE: nothing needs to react live - sendStrummedNotes() above
-- reads it fresh on every strummed note. The function exists only because
-- every control here is declared with one (recipe 33.14).
function onStrumGateChange(valueObject, value)
end

function formatStrumGate(valueObject, value)
  if value <= 0 then return "Off" end
  return value .. " ms"
end

-- STRUM GATE TAPER: nothing needs to react live - strumGateMultiplier()
-- above reads it fresh on every strummed note. The function exists only
-- because every control here is declared with one (recipe 33.14).
function onStrumGateTaperChange(valueObject, value)
end

function formatStrumGateTaper(valueObject, value)
  return value .. " %"
end

function formatTransposeSemi(valueObject, value)
  if value > 0 then return "+" .. value .. " st" end
  if value < 0 then return value .. " st" end
  return "0 st"
end

function onPatternChange(valueObject, value)
  ArpState.stepIndex, ArpState.direction = 0, 1
  ArpState.euclidStep = 0
  ArpState.accentStep = 0
  ArpState.grooveStep = 0
  ArpState.shuffledOrder, ArpState.shuffledPos = nil, 1
  Disp.refreshStepPreview()
end

function onOctavesChange(valueObject, value)
  ArpState.stepIndex, ArpState.direction = 0, 1
  ArpState.euclidStep = 0
  ArpState.accentStep = 0
  ArpState.grooveStep = 0
  ArpState.shuffledOrder, ArpState.shuffledPos = nil, 1
  Disp.refreshStepPreview()
end

function onGateChange(valueObject, value)
  Lfo.captureBase(Lfo.REF_GATE, value)
end

function onChanceChange(valueObject, value)
  Lfo.captureBase(Lfo.REF_CHANCE, value)
end

-- ARP VEL: nothing needs to react live - the velocity override above reads
-- it fresh on every arp step. The function exists only because every
-- control here is declared with one (recipe 33.14).
function onArpVelocityChange(valueObject, value)
  Lfo.captureBase(Lfo.REF_ARPVEL, value)
end

function formatArpVelocity(valueObject, value)
  if value <= 0 then return "As Played" end
  return tostring(value)
end

-- GROOVE TEMPLATE / GROOVE AMOUNT: nothing needs to react live -
-- grooveValuesAt() above reads both fresh on every arp step. The functions
-- exist only because every control here is declared with one (recipe
-- 33.14).
function onGrooveTemplateChange(valueObject, value)
  Disp.refreshGrooveDisplay()
end

function onGrooveAmountChange(valueObject, value)
  Lfo.captureBase(Lfo.REF_GROOVEAMT, value)
  Disp.refreshGrooveDisplay()
end

-- EUC LENGTH / EUC PULSES: nothing needs to react live - euclidGateHit()
-- above reads both fresh on every arp step. The functions exist only
-- because every control here is declared with one (recipe 33.14).
function onEuclidLengthChange(valueObject, value)
  Disp.refreshRhythmDisplay()
end

function onEuclidPulsesChange(valueObject, value)
  Disp.refreshRhythmDisplay()
end

function formatEuclidLength(valueObject, value)
  return value .. " steps"
end

function formatEuclidPulses(valueObject, value)
  return value .. " hits"
end

-- ACCENT LENGTH / ACCENT PULSES / ACCENT AMOUNT: nothing needs to react
-- live - the Accent block in advanceStep() reads all three fresh on every
-- arp step. The functions exist only because every control here is
-- declared with one (recipe 33.14).
function onAccentLengthChange(valueObject, value)
  Disp.refreshRhythmDisplay()
end

function onAccentPulsesChange(valueObject, value)
  Disp.refreshRhythmDisplay()
end

function onAccentAmountChange(valueObject, value)
  Lfo.captureBase(Lfo.REF_ACCAMT, value)
end

function onTransposeOctaveChange(valueObject, value)
end

-- Scale decides both how many Mode choices make sense and what they are
-- called (modeChoiceCountForScale()/modeNamesForScale() above), so every
-- Scale change rebuilds Mode's overlay outright - see rebuildModeOverlay().
function onScaleChange(valueObject, value)
  Scale.rebuildModeOverlay()
  Chord.rebuildOverlay()
  Scale.updateInfoText()
end

-- The overlay already carries the right label for whatever Mode is turned
-- to - rebuildModeOverlay() is only needed when the choices THEMSELVES
-- change, i.e. on a Scale change - but the degrees shown in the info bar
-- DO depend on which mode (rotation) is current, so that still updates
-- here.
function onModeChange(valueObject, value)
  Scale.updateInfoText()
end

-- Shape changes the notes a struck key generates, so anything already
-- sounding from an earlier Shape is brought up to date rather than left
-- stale until the key is re-struck - see regenerateShapeNotes() above.
function onShapeChange(valueObject, value)
  if shapeUpdateIsImmediate() then
    Notes.regenerateShape()
  end
end

-- Inversion, the same way: it rearranges the shape's own notes, so a chord
-- already sounding is updated live too - unless SHAPE UPDATE says to wait
-- for the next struck key.
function onInversionChange(valueObject, value)
  if shapeUpdateIsImmediate() then
    Notes.regenerateShape()
  end
end

-- Everything a Harmony Mode change needs to settle: called from
-- onHarmonyModeChange() below, an ordinary switch.
local function settleModeChange()
  HoldFade.cancel(true)
  Strum.cancelAllGates()
  -- Anything the OLD mode was sounding directly (Shape, arp off) must be
  -- silenced before the tables that remember it are wiped below. harmonyMode()
  -- would read the NEW value already (this control's own value has already
  -- changed by the time its function runs, like every other value function
  -- here) so the OLD one is read from lastHarmonyMode instead.
  if Notes.soundsDirectly(lastHarmonyMode) and destActive() then
    local iface, port, chan = destRoute()
    for n in pairs(Notes.noteRefCount) do
      midi.sendNoteOff(iface, port, chan, n, 0)
    end
  end

  stopCurrent()
  Notes.held, Notes.pressOrder, Notes.noteRefCount, Notes.keyGeneratedNotes, Notes.keyVelocity = {}, {}, {}, {}, {}
  Notes.shapeHeld, Notes.shapePressOrder, Notes.shapeActiveKey = {}, {}, nil
  ArpState.stepIndex, ArpState.direction = 0, 1
  ArpState.euclidStep = 0
  ArpState.accentStep = 0
  ArpState.grooveStep = 0
  rc(Ref.HARMONY_KEYBOARD):repaint()
end

-- Harmony Mode decides what a struck key means, so switching it silences
-- everything outright rather than leaving the old meaning's notes stuck
-- sounding under the new one.
function onHarmonyModeChange(valueObject, value)
  settleModeChange()

  lastHarmonyMode = harmonyMode()
  updateChordParamVisibility()
end

function onTransposeSemitoneChange(valueObject, value)
end

function onSwingChange(valueObject, value)
  -- Swing never changes the timer's period; it only delays the off-beat
  -- note-on via midi.at() inside advanceStep.
  Lfo.captureBase(Lfo.REF_SWING, value)
end

-- Staged, not applied live - see the comment above Clock.commitTimingIfPending().
-- SYNC is a 19-item list dragged across several detents in one gesture;
-- retiming the timer/External pulse count on every intermediate value
-- would land the next note at an unpredictable offset depending on
-- exactly when, mid-step, the drag happened to be, and - with a live
-- external clock also competing for the application thread - risks
-- starving MIDI delivery on a long sweep (the DIVISION bug). The real
-- effect is armed by onSyncTouchEnd (the control's touch/end event, wired
-- in the project) and committed at the next natural step boundary.
function onSyncChange(valueObject, value)
end

function onSyncTouchEnd(control, source, event, potId, valueId, value)
  Clock.pendingTimingApply = true
end

-- Test backdoor - see the comment above debugTempoTouchEnd().
function debugSyncTouchEnd()
  onSyncTouchEnd(nil, nil, nil, nil, nil, nil)
end

-- CLOCK IFACE/PORT: nothing needs to react live - srcPortMatches() above
-- reads them fresh on every incoming clock message. The function exists
-- only because every control here is declared with one (recipe 33.14).
function onClockRouteChange(valueObject, value)
end

-- CLOCK SRC itself. Switching stops whatever is sounding and resets the
-- step position, then starts whichever engine now owns stepping: the timer
-- for Internal (if the arp is on), or nothing for External - stepping then
-- comes from midi.onClock as pulses arrive.
function onClockSourceChange(valueObject, value)
  HoldFade.cancel(true)
  stopCurrent()
  Clock.extCount = 0
  Clock.pendingTimingApply = false
  Clock.currentTicksPerStep = Clock.ticksPerStep()
  ArpState.swingParity = 0
  ArpState.stepIndex, ArpState.direction = 0, 1
  ArpState.euclidStep = 0
  ArpState.accentStep = 0
  ArpState.grooveStep = 0

  Clock.running = false
  Clock.lastPulseAt = nil
  Clock.bpmEstimate = 0
  Clock.smoothedPulseMs = nil
  Clock.monitorPulseCount = 0
  Clock.flashActive = false
  rc(Ref.CLOCK_MONITOR):repaint()

  if not isArpOn() then return end

  if value == Clock.EXTERNAL then
    timer.disable()
    ArpState.nextDueAt = nil
    Clock.stopOutput()   -- the generator stands down; relaying takes over
  else
    timer.setPeriod(ARP_POLL_MS)
    ArpState.nextDueAt = math.floor(schedule.now() + basePeriodMs())
    timer.enable()
    Clock.startOutput()
  end
end

function onLatchChange(valueObject, value)
  HoldFade.cancel(true)
  -- value is the list's labelled value (0 Off, 1 Normal, 2 Chord), not an
  -- index - textValues were declared 0/1/2 so the two agree here.
  if value == LATCH_OFF then
    -- switching to Off: drop every struck key's generated notes unless
    -- that key is still physically down. Go by keyGeneratedNotes, not
    -- `held` directly - in Shape mode a held note can be a long way from
    -- the physical key number that produced it.
    for note in pairs(Notes.keyGeneratedNotes) do
      if not Notes.keysDown[note] then
        Notes.removeGenerated(note)
      end
    end
    if next(Notes.held) == nil then
      stopCurrent()
      ArpState.stepIndex, ArpState.direction = 0, 1
      ArpState.euclidStep = 0
      ArpState.accentStep = 0
      ArpState.grooveStep = 0
    end

    -- A latched (but no longer held) Shape/SATB key dropped above may have
    -- been the "active" one - if so a still-held key that was losing the
    -- priority competition should take over the slot now.
    if harmonyMode() == HARMONY_MODE_SHAPE or harmonyMode() == HARMONY_MODE_SATB then
      if Notes.shapeActiveKey ~= nil and Notes.keyGeneratedNotes[Notes.shapeActiveKey] == nil then
        Notes.shapeActiveKey = nil
      end
      if Notes.shapeActiveKey == nil then
        local winner = Notes.activeShapeKey()
        if winner ~= nil then
          Notes.addGenerated(winner, Notes.shapeHeld[winner])
          Notes.shapeActiveKey = winner
        end
      end
    end
  end
end

-- Destination moved: silence the old route before anything plays on the new.
-- Includes whatever Shape was sounding directly with the arp off.
function onDestChange(valueObject, value)
  HoldFade.cancel(true)
  Strum.cancelAllGates()
  if Notes.shouldSoundDirectly() then
    local iface, port, chan = destRoute()
    for n in pairs(Notes.noteRefCount) do
      midi.sendNoteOff(iface, port, chan, n, 0)
    end
  end
  stopCurrent()
end

-- Source moved: the keys held on the old source will never send their
-- note-off.
function onSourceChange(valueObject, value)
  HoldFade.cancel(true)
  Strum.cancelAllGates()
  if Notes.shouldSoundDirectly() then
    local iface, port, chan = destRoute()
    for n in pairs(Notes.noteRefCount) do
      midi.sendNoteOff(iface, port, chan, n, 0)
    end
  end
  stopCurrent()
  Notes.held, Notes.pressOrder, Notes.noteRefCount, Notes.keyGeneratedNotes, Notes.keyVelocity = {}, {}, {}, {}, {}
  Notes.shapeHeld, Notes.shapePressOrder, Notes.shapeActiveKey = {}, {}, nil
  ArpState.stepIndex, ArpState.direction = 0, 1
  ArpState.euclidStep = 0
  ArpState.accentStep = 0
  ArpState.grooveStep = 0
  rc(Ref.HARMONY_KEYBOARD):repaint()
end

-- The arp's own on/off switch. Harmony Mode is unaffected either way - only
-- the timer that drives the pattern engine is gated here. Assigned (not
-- "local function") because this fills the forward declaration above.
isArpOn = function()
  local c = rcOrNil(29)
  if not c then return false end
  return c:getValue():getValue() == 1
end

-- Resets the pattern to its first step - the same starting point a pattern
-- or octave-range change already gives it - without changing anything else
-- (the held notes, the latch, the destination). Stops whatever is currently
-- sounding; the next tick plays step 1, fresh. Fires on press only.
function onArpReset(valueObject, value)
  if value == 0 then return end

  stopCurrent()
  ArpState.stepIndex, ArpState.direction = 0, 1
  ArpState.euclidStep = 0
  ArpState.accentStep = 0
  ArpState.grooveStep = 0
  ArpState.swingParity = 0
  ArpState.shuffledOrder, ArpState.shuffledPos = nil, 1
  Disp.repaintRhythm()   -- the position markers reset immediately, not on the next tick
end

-- PANIC (ref 56): a stuck note is the one failure mode none of the clean
-- state transitions above can promise to catch - a message dropped on a
-- flaky USB link, a destination changed by hand faster than
-- onDestChange's own cleanup could keep up with, or a synth that simply
-- missed one. Unlike every other reset in this script, PANIC does not
-- trust the script's own bookkeeping of what is sounding: it blasts
-- CC 123 (All Notes Off) and CC 120 (All Sound Off) on EVERY channel
-- 1..16 of the current destination route, not just the one channel the
-- script believes is in use, and only then clears every table that
-- tracks a sounding note - so nothing stale gets "released" again later
-- and nothing re-sounds on its own.
function onPanic(valueObject, value)
  if value == 0 then return end   -- fires on press only, like Arp Reset/Clear

  HoldFade.cancel(true)
  Strum.cancelAllGates()
  stopCurrent()

  local iface, port = cfgList(6), cfgList(7)
  for ch = 1, 16 do
    midi.sendControlChange(iface, port, ch, 123, 0)   -- All Notes Off
    midi.sendControlChange(iface, port, ch, 120, 0)   -- All Sound Off
  end

  Notes.held, Notes.pressOrder, Notes.keysDown = {}, {}, {}
  ArpState.currentNote = nil
  Notes.noteRefCount, Notes.keyGeneratedNotes, Notes.keyVelocity = {}, {}, {}
  Notes.shapeHeld, Notes.shapePressOrder, Notes.shapeActiveKey = {}, {}, nil
  ArpState.stepIndex, ArpState.direction = 0, 1
  ArpState.euclidStep = 0
  ArpState.accentStep = 0
  ArpState.grooveStep = 0
  ArpState.shuffledOrder, ArpState.shuffledPos = nil, 1
  ArpState.swingParity = 0
  Clock.extCount = 0
  rc(Ref.HARMONY_KEYBOARD):repaint()
end

-- HOLD (ref 53): keeps a directly-sounding Shape/SATB chord ringing after
-- the key that struck it is released, until HOLD itself is turned off. It
-- cannot run together with the arp - a struck
-- key's release has nothing to do with the arp - so the two compete for
-- the same keystroke exactly the way Strum Time and the arp already do
-- (onStrumTimeChange/onArpToggle): turning HOLD on hands the keystroke
-- back from the arp, turning the arp on takes it back from HOLD.
function onHoldChange(valueObject, value)
  if value == 1 then
    HoldFade.cancel(true)   -- Hold back on: cancel any fade and keep sounding at full volume
    if isArpOn() then
      rc(29):getValue():setValue(0)   -- Arp: off, HOLD has the keystroke now
    end
    return
  end

  -- HOLD turned off: every key still in keyGeneratedNotes whose physical
  -- key is no longer down is only still sounding because of HOLD - a
  -- single shapeActiveKey in Chord/SATB mode, or any number of
  -- independently-sustained Off-mode notes (onKeyUp above leaves each one
  -- exactly as it found it, the same way onShapeKeyUp already does for a
  -- chord). All of them fade out together over RELEASE (ref 35) instead of
  -- stopping dead - see fadeOutAndRelease() below. The bookkeeping
  -- (noteRefCount, keyGeneratedNotes, ...) is settled right now, exactly
  -- as the instant version did; only the actual MIDI note-off and the
  -- Expression ramp ahead of it are deferred.
  local iface, port, chan = destRoute()
  local toRelease = {}
  local active = destActive()

  for key, notes in pairs(Notes.keyGeneratedNotes) do
    if not Notes.keysDown[key] then
      Notes.keyGeneratedNotes[key] = nil
      Notes.keyVelocity[key] = nil
      if key == Notes.shapeActiveKey then Notes.shapeActiveKey = nil end

      for _, n in ipairs(notes) do
        local count = (Notes.noteRefCount[n] or 1) - 1
        if count <= 0 then
          Notes.noteRefCount[n] = nil
          Notes.release(n)
          toRelease[#toRelease + 1] = n
        else
          Notes.noteRefCount[n] = count
        end
      end
    end
  end

  -- DST CHAN OFF: there is no channel to ramp or release on.
  if active then
    HoldFade.outAndRelease(toRelease, iface, port, chan)
  end
end

function formatReleaseTime(valueObject, value)
  return string.format("%.1f s", value / 10)
end

-- Nothing needs to react live - fadeOutAndRelease() reads RELEASE fresh
-- every time HOLD is switched off. The function exists only because every
-- control here is declared with one (recipe 33.14).
function onReleaseTimeChange(valueObject, value)
end

function formatFadeCc(valueObject, value)
  return "CC " .. value
end

-- Nothing needs to react live - scheduleFadeStep() reads FADE CC fresh on
-- every 50ms step, so a change mid-ramp takes effect on the next step
-- rather than waiting for a fresh HOLD release. The function exists only
-- because every control here is declared with one (recipe 33.14).
function onFadeCcChange(valueObject, value)
end

function onArpToggle(valueObject, value)
  HoldFade.cancel(true)
  if value == 1 then
    -- The arp and Strum Time compete for the same keystroke (see
    -- onStrumTimeChange above) - turning the arp on hands the keystroke
    -- back to it, so Strum Time is reset to 0.
    if cfgValue(43) > 0 then
      rc(43):getValue():setValue(0)   -- Strum Time: off, the arp has the keystroke now
    end
    -- HOLD competes for the same keystroke too (see onHoldChange above).
    if holdActive() then
      rc(53):getValue():setValue(0)   -- HOLD: off, the arp has the keystroke now
    end
    -- Handing the held pool over to the arp: anything Shape/SATB was
    -- sounding directly (arp was off a moment ago) must stop now, since the
    -- arp is about to start stepping through the very same pool one note
    -- at a time - both at once would double notes up.
    if (harmonyMode() == HARMONY_MODE_SHAPE or harmonyMode() == HARMONY_MODE_SATB) and destActive() then
      local iface, port, chan = destRoute()
      for n in pairs(Notes.noteRefCount) do
        midi.sendNoteOff(iface, port, chan, n, 0)
      end
    end
    -- Starting resets the pattern to its first step and the pulse/phase
    -- counters, exactly as ARP RESET does - otherwise the first step after
    -- a restart lands wherever the pattern happened to be left when the
    -- arp was last turned off, not at step one.
    ArpState.stepIndex, ArpState.direction = 0, 1
    ArpState.euclidStep = 0
    ArpState.accentStep = 0
    ArpState.grooveStep = 0
    ArpState.swingParity = 0
    Clock.pendingTimingApply = false
    Clock.currentTicksPerStep = Clock.ticksPerStep()
    if Clock.isExternal() then
      Clock.extCount = 0
      timer.disable()
      ArpState.nextDueAt = nil
    else
      timer.setPeriod(ARP_POLL_MS)
      ArpState.nextDueAt = math.floor(schedule.now() + basePeriodMs())
      timer.enable()
      Clock.startOutput()   -- the arp is now the clock out's own start/stop
    end
    -- And the first note sounds the instant the arp starts, not after
    -- waiting a whole step period/pulse-count in silence - see fireStep().
    fireStep(false)
  else
    timer.disable()
    ArpState.nextDueAt = nil
    stopCurrent()
    Clock.stopOutput()   -- harmless no-op under External or if never started
    Disp.refreshStepPreview()   -- back to idle preview now the arp has stopped stepping
    -- Taking the pool back from the arp: previously this blasted every
    -- note in `held` as one chord, on the theory that "nothing else will
    -- play it now". In practice that is an unwanted extra attack whenever
    -- a key is still physically down at the moment the arp stops - the
    -- player hears the stepped notes, then a surprise chord on top. So the
    -- stepped note that was sounding has already been stopped above, and a
    -- key still physically down is left exactly as it is - its own release
    -- now always really releases once the arp is off (see onShapeKeyUp/
    -- onKeyUp above), so the sound picks back up normally with no
    -- retrigger in between.
    --
    -- A key that was latched - physically released while the arp was
    -- still running and Latch was Normal/Chord - is a different case: its
    -- notes never went out as a real Note On (the arp, not the pool, was
    -- doing the sounding), so leaving them in noteRefCount/
    -- keyGeneratedNotes once the arp stops is stale bookkeeping that
    -- nothing will ever clear - at best inert, at worst blocking a later
    -- chord that happens to share a pitch (addGeneratedNotes sees
    -- noteRefCount already set and skips sending its Note On). This is
    -- what let a chord sound and then stay stuck indefinitely after the
    -- arp was switched off: clear any such latched-but-unheld key here,
    -- the same cleanup onLatchChange already does for LATCH_OFF.
    if harmonyMode() == HARMONY_MODE_SHAPE or harmonyMode() == HARMONY_MODE_SATB then
      for note in pairs(Notes.keyGeneratedNotes) do
        if not Notes.keysDown[note] then
          Notes.removeGenerated(note)
        end
      end
      if Notes.shapeActiveKey ~= nil and Notes.keyGeneratedNotes[Notes.shapeActiveKey] == nil then
        Notes.shapeActiveKey = nil
      end
    end
  end
end

-- SNAPSHOT SAVE/RECALL (Config page): SNAPSHOT # (ref 97) picks a slot in a
-- single fixed bank (Snap.BANK); SAVE (ref 98) and LOAD (ref 99) are
-- momentary pads whose own NAME is rewritten to show what pressing them
-- would do right now - "SAVE n"/"OVR n" for an empty/occupied slot, and
-- "LOAD n"/"EMPTY" likewise - since a pad has no other on-screen text to
-- carry that. snapshots.save()/load() are both asynchronous (24.2): the
-- label is refreshed on a short delay after a save so it reliably reads the
-- state AFTER the write actually lands, rather than racing it.
local Snap = {}
Snap.BANK = 1
Snap.SLOT_REF, Snap.SAVE_REF, Snap.LOAD_REF = 97, 98, 99

function Snap.currentSlot()
  local c = rcOrNil(Snap.SLOT_REF)
  if not c then return 0 end
  return c:getValue():getValue()
end

-- Config page not built on every device yet - skip quietly where the
-- Snapshot controls do not exist there, same as RETRIGGER/the Arp displays.
function Snap.refreshLabels()
  local saveControl = rcOrNil(Snap.SAVE_REF)
  local loadControl = rcOrNil(Snap.LOAD_REF)
  if not saveControl or not loadControl then return end

  local slot = Snap.currentSlot()
  local used = snapshots.isUsed(Snap.BANK, slot)
  saveControl:setName(used and ("OVR " .. slot) or ("SAVE " .. slot))
  loadControl:setName(used and ("LOAD " .. slot) or "EMPTY")
end

function onSnapshotSlotChange(valueObject, value)
  Snap.refreshLabels()
end

function onSnapshotSave(valueObject, value)
  if value == 0 then return end   -- fires on press only
  snapshots.save(Snap.BANK, Snap.currentSlot())
  schedule.after(150, Snap.refreshLabels)
end

function onSnapshotLoad(valueObject, value)
  if value == 0 then return end   -- fires on press only
  local slot = Snap.currentSlot()
  if snapshots.isUsed(Snap.BANK, slot) then
    snapshots.load(Snap.BANK, slot)
  end
end

-- PAGE NAV (the freed 4th hardware button on several pages): a short press
-- goes to the next page, a long press (held past PageNav.LONG_PRESS_MS)
-- goes to the previous one - one function, reused by every page that
-- carries the button, the same way every other pad here shares its
-- handler. Fires on the pad's own press/release (value 1/0), exactly like
-- ARP RESET above; nothing is sent over MIDI - the message is virtual and
-- each instance uses its own parameter number, so one page's button
-- leaves no shared state for another page's copy to see.
local PageNav = {}
PageNav.pressedAt = nil
PageNav.LONG_PRESS_MS = 500

-- How many Mini pages actually carry content right now - cycling wraps
-- here rather than wandering into the still-empty placeholder pages
-- beyond it. Update this as more pages are built. Page 9 now carries the
-- MOD (LFO) controls ported from mk2's Page 4, with its own "< PAGE >"
-- button, so the cycle wraps at 9.
PageNav.PAGE_COUNT = 9

-- HARMONY 1 / ARP 1 (Config page, Mini only - mk2 has one CONFIG page with
-- no equivalent buttons, so these controls do not exist there): momentary
-- shortcuts back from Config to the section you most likely came from,
-- now that the knob-switch shortcut (onHarmonyKeyboardSwitch/
-- onArpStepDisplaySwitch above) only goes Config -> there and not back.
-- Reuse the exact same page targets the knob switches use, so both paths
-- agree on where "Harmony" and "Arp" land.
function onGoHarmony1(valueObject, value)
  if value == 0 then return end   -- fires on press only
  hopToHarmonyPage()
end

function onGoArp1(valueObject, value)
  if value == 0 then return end
  hopToArpPage()
end

function onPageNavButton(valueObject, value)
  if value == 1 then
    PageNav.pressedAt = controller.uptime()
    return
  end

  if not PageNav.pressedAt then return end
  local heldMs = controller.uptime() - PageNav.pressedAt
  PageNav.pressedAt = nil

  local current = pages.getActive():getId()
  local target
  if heldMs >= PageNav.LONG_PRESS_MS then
    target = current - 1
    if target < 1 then target = PageNav.PAGE_COUNT end
  else
    target = current + 1
    if target > PageNav.PAGE_COUNT then target = 1 end
  end
  pages.display(target)
end

-- Combined IFACE/PORT knob: a "custom" control with two values, "iface"
-- and "port" - turning the knob cycles the interface (MIDI IO/USB Dev/
-- USB Host), pressing it toggles the port (Port 1/Port 2), one knob doing
-- the work of two separate list controls. A custom control draws and
-- moves nothing by itself (10.3/9.8), so all three callbacks are attached
-- here, once per control, in preset.onReady() - and each value keeps the
-- same "function" its old standalone control had (onSourceChange,
-- onDestChange, ...), so turning OR pressing this knob still runs
-- whatever cleanup that route change always required (recipe 33.13),
-- exactly as if the two knobs it replaces had been turned by hand.
local IoKnob = {}

-- Every "I/O" custom control's reference, by its own numbering (these do
-- not exist on mk2, so they are looked up directly - not through rc()'s
-- +300 mirroring). Add a new one here when another IFACE/PORT pair is
-- combined onto a single knob.
IoKnob.REFS = { ComboRef.SRC, ComboRef.DST, ComboRef.CLOCK_IN, ComboRef.CLOCK_OUT }

function IoKnob.paint(control)
  local b = control:getBounds()
  local w, h = b[WIDTH], b[HEIGHT]

  graphics.setColor(0x101010)
  graphics.fillRect(0, 0, w, h)
  graphics.setBackgroundColor(0x101010)

  local ifaceValue = control:getValue("iface")
  local portValue = control:getValue("port")
  local ifaceLabel = ifaceValue:getOverlay():getLabel(ifaceValue:getValue()) or "?"

  graphics.setColor(control:getColor())
  graphics.print(0, (h // 2) - 14, control:getName(), w, CENTER, BOLD, SMALL)

  graphics.setColor(WHITE)
  graphics.print(0, (h // 2) + 2, ifaceLabel .. "  P" .. (portValue:getValue() + 1),
                 w, CENTER, REGULAR, SMALL)
end

-- The knob turning: steps the iface value one item per detent, wrapping,
-- regardless of how fast the turn was (event.delta's magnitude is not
-- used - a 3-item list has nothing useful to skip to).
function IoKnob.pot(control, event)
  if event.delta == 0 then return end   -- a touch, not a turn

  local ifaceValue = control:getValue("iface")
  local count = ifaceValue:getOverlay():getNumItems()
  local wanted = ifaceValue:getValue() + (event.delta > 0 and 1 or -1)
  if wanted < 0 then wanted = count - 1 end
  if wanted >= count then wanted = 0 end

  ifaceValue:setValue(wanted)
  control:repaint()
end

-- The knob's own push-switch: toggles the port. type 1 is pressed, 3 is
-- released - only the press toggles, same as every pad here firing once.
function IoKnob.switch(control, event)
  if event.type ~= 1 then return end

  local portValue = control:getValue("port")
  portValue:setValue(portValue:getValue() == 0 and 1 or 0)
  control:repaint()
end

function preset.onReady()
  HoldFade.cancel(true)
  Strum.cancelAllGates()
  -- All Notes Off: a reload forgets what it was sounding. Skipped outright
  -- when DST CHAN is OFF - there is no channel to send it on.
  if destActive() then
    local iface, port, chan = destRoute()
    midi.sendControlChange(iface, port, chan, 123, 0)
  end
  Notes.held, Notes.pressOrder, Notes.keysDown = {}, {}, {}
  ArpState.currentNote = nil
  Notes.noteRefCount, Notes.keyGeneratedNotes, Notes.keyVelocity = {}, {}, {}
  Notes.shapeHeld, Notes.shapePressOrder, Notes.shapeActiveKey = {}, {}, nil
  ArpState.stepIndex, ArpState.direction = 0, 1
  ArpState.euclidStep = 0
  ArpState.accentStep = 0
  ArpState.grooveStep = 0
  ArpState.shuffledOrder, ArpState.shuffledPos = nil, 1
  ArpState.swingParity = 0
  Clock.extCount = 0
  Clock.pendingTimingApply = false
  Clock.currentTicksPerStep = Clock.ticksPerStep()

  -- LFO engine (Page 4, MOD): fresh phase, and each destination's base
  -- pulled from whatever its control is actually showing right now -
  -- the project default or a loaded value, never a hard-coded number -
  -- so the LFO offsets from exactly what the player's knob says.
  Lfo.state = { { phase = 0, shValue = 0 }, { phase = 0, shValue = 0 } }
  for _, ref in pairs(Lfo.DEST_BY_VALUE) do
    Lfo.base[ref] = cfgValue(ref)
  end

  -- Respect the Arp On/Off control's own loaded value (its function has
  -- already run by this point, same as every other control's) rather than
  -- forcing the timer on regardless - see recipe 33.13's trap 3. Likewise
  -- CLOCK SRC's own loaded value decides whether the timer or incoming
  -- MIDI clock drives stepping.
  if isArpOn() and not Clock.isExternal() then
    timer.setPeriod(ARP_POLL_MS)
    ArpState.nextDueAt = math.floor(schedule.now() + basePeriodMs())
    timer.enable()
    Clock.startOutput()   -- match the loaded ARP ON value, same reasoning as the timer above
  else
    timer.disable()
    ArpState.nextDueAt = nil
  end

  -- Rebuild Mode's and Shape's overlays to whatever choice count the loaded
  -- Scale allows - needed explicitly on load too, same as every other
  -- derived display state here.
  Scale.rebuildModeOverlay()
  Chord.rebuildOverlay()

  -- Sync onHarmonyModeChange()'s memory of "the mode a moment ago" to what
  -- actually loaded, so the first change after a reload compares against
  -- the real starting mode rather than a stale default.
  lastHarmonyMode = harmonyMode()
  updateChordParamVisibility()

  -- RETRIGGER's visibility follows SHAPE UPDATE's loaded value too - see
  -- onShapeUpdateModeChange(). Config page not built on every device yet -
  -- skip quietly where RETRIGGER itself does not exist there.
  local retriggerControl = rcOrNil(15)
  if retriggerControl then
    retriggerControl:setVisible(shapeUpdateIsImmediate())
  end

  -- HARMONY KEYBOARD: its footprint comes from the project (span/vspan,
  -- anchored at the one slot that actually paints - see the comment above
  -- HARMONY_KEYBOARD_REF); only the paint callback is attached here. The
  -- callback is lost on every reload (10.3/9.8), and a callback set
  -- without a repaint stays blank until its first event, so the repaint
  -- is explicit rather than left to wait for one.
  local harmonyKeyboard = rc(Ref.HARMONY_KEYBOARD)
  harmonyKeyboard:setPaintCallback(paintHarmonyKeyboard)
  harmonyKeyboard:setSwitchCallback(onHarmonyKeyboardSwitch)
  harmonyKeyboard:repaint()

  -- ARP STEP DISPLAY / ARP GROOVE DISPLAY / ARP RHYTHM DISPLAY: see the
  -- comment above `Disp`. Callbacks are lost on every reload, same
  -- reasoning as the harmony keyboard above, so they are reattached here
  -- too, and their backing data refreshed explicitly rather than left to
  -- wait for the first tick or control change. The Arp page is not built
  -- on every device yet - skip quietly where a display does not exist
  -- there, same as RETRIGGER's visibility above.
  local stepDisplay = rcOrNil(Disp.STEP_REF)
  if stepDisplay then
    stepDisplay:setPaintCallback(Disp.paintStep)
    stepDisplay:setSwitchCallback(onArpStepDisplaySwitch)
    Disp.refreshStepPreview()
  end

  local grooveDisplay = rcOrNil(Disp.GROOVE_REF)
  if grooveDisplay then
    grooveDisplay:setPaintCallback(Disp.paintGroove)
    Disp.refreshGrooveDisplay()
  end

  local rhythmDisplay = rcOrNil(Disp.RHYTHM_REF)
  if rhythmDisplay then
    rhythmDisplay:setPaintCallback(Disp.paintRhythm)
  end
  local ok2, rhythmDisplay2 = pcall(controls.get, Disp.RHYTHM_REF2)
  if ok2 then
    rhythmDisplay2:setPaintCallback(Disp.paintRhythm)
  end
  if rhythmDisplay or ok2 then
    Disp.refreshRhythmDisplay()
  end

  Clock.running = false
  Clock.lastPulseAt = nil
  Clock.bpmEstimate = 0
  Clock.smoothedPulseMs = nil
  Clock.monitorPulseCount = 0
  Clock.flashActive = false
  local clockMonitor = rcOrNil(Ref.CLOCK_MONITOR)
  if clockMonitor then
    clockMonitor:setPaintCallback(Clock.paintMonitor)
    clockMonitor:repaint()
  end

  -- Combined IFACE/PORT knobs - see the comment above IoKnob. Skipped
  -- quietly for any reference not built on this device (none exist on
  -- mk2 at all, and more may be added here than are built yet on Mini).
  for _, ref in ipairs(IoKnob.REFS) do
    local ok, knob = pcall(controls.get, ref)
    if ok then
      knob:setPaintCallback(IoKnob.paint)
      knob:setPotCallback(IoKnob.pot)
      knob:setSwitchCallback(IoKnob.switch)
      knob:repaint()
    end
  end

  Snap.refreshLabels()

  Scale.updateInfoText()

  -- Combined SRC/DST/CLOCK IN knobs (Mini only - see the comment above
  -- paintRoutedKnob). Direct controls.get() by its own absolute reference,
  -- not rc(): these have no mk2 counterpart to offset from, so a bare
  -- pcall stands in for rcOrNil() here.
  for _, mergedRef in ipairs({ 440, 441, 442 }) do
    local ok, knob = pcall(controls.get, mergedRef)
    if ok then
      knob:setPaintCallback(paintRoutedKnob)
      knob:setPotCallback(onRoutedKnobTurn)
      knob:setSwitchCallback(onRoutedKnobSwitch)
      knob:repaint()
    end
  end
end

-- Switching back to a preset already in memory (pinned, or simply still
-- loaded) runs ONLY onEnter() - onReady() does not run again (lifecycle
-- section 3.3/3.6). The bottom-bar info text is reset to "" whenever
-- another preset writes its own info.setText(), so without this the scale
-- info would stay blank on a switch back even though nothing else changed.
function preset.onEnter()
  Scale.updateInfoText()
end

function preset.onExit()
  HoldFade.cancel(true)
  Strum.cancelAllGates()
  timer.disable()
  Clock.stopOutput()
  stopCurrent()
  if Notes.shouldSoundDirectly() then
    local iface, port, chan = destRoute()
    for n in pairs(Notes.noteRefCount) do
      midi.sendNoteOff(iface, port, chan, n, 0)
    end
  end
end

-- TEMP DEBUG
function debugScaleInfoText()
  return Scale.infoText()
end
function debugNotesForKey(n)
  return notesForKey(n)
end
function debugQuantize(n)
  return quantizeToScale(n)
end
debugSentNotesList = {}
function debugSentNotesHook(note)
  debugSentNotesList[#debugSentNotesList+1] = note
end
function debugGetSent()
  return debugSentNotesList
end
function debugClearSent()
  debugSentNotesList = {}
end
function debugKeyDown(n, v)
  Notes.keyDown(n, v or 100)
end
function debugKeyUp(n)
  Notes.keyUp(n)
end
-- Test/debug backdoor: forces exactly one real step per call, unconditionally,
-- bypassing the real-clock lookahead gate timer.onTick() now applies (see
-- the comment above ARP_POLL_MS) - the same "one call, one step" behaviour
-- this always had, for manual probing and for scripts that do not want to
-- wait out real wall-clock time between steps.
function debugTick(n)
  for i = 1, (n or 1) do
    local dueAt = ArpState.nextDueAt
    local isOffBeat = (ArpState.swingParity == 1)
    fireStep(isOffBeat, dueAt)
    if ArpState.nextDueAt then
      ArpState.nextDueAt = math.floor(dueAt + basePeriodMs())
    end
  end
end
function debugStrumGateHandleCount()
  local n = 0
  for _ in pairs(Strum.gateHandles) do n = n + 1 end
  return n
end
function debugStrumGateMultiplier(i, n)
  return Strum.gateMultiplier(i, n)
end
function debugKeyboardRangeFor(notesList)
  local set = {}
  for _, n in ipairs(notesList or {}) do set[n] = true end
  return keyboardRangeFor(set)
end
function debugHeldNotes()
  local list = {}
  for n in pairs(Notes.held) do list[#list + 1] = n end
  table.sort(list)
  return list
end
function debugLastHarmonyMode()
  return lastHarmonyMode
end
function debugShapeActiveKey()
  return Notes.shapeActiveKey
end
function debugStepBoxNotes()
  return Disp.stepBoxNotes
end
function debugStepBoxStatus()
  return Disp.stepBoxStatus
end
debugSentOffList = {}
function debugSentOffHook(note)
  debugSentOffList[#debugSentOffList+1] = note
end
function debugGetSentOff()
  return debugSentOffList
end
function debugClearSentOff()
  debugSentOffList = {}
end
function debugClockFlashActive()
  return Clock.flashActive
end
function debugClockRunning()
  return Clock.running
end
function debugClockBpmEstimate()
  return Clock.bpmEstimate
end
function debugGrooveVel(i)
  return Disp.grooveVel[i]
end


