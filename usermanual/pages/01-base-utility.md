# Page 1: Utility, Patch Sync & Microtonal Tuning (`Utility`)

The **Utility** page is your command center for connecting to the Korg Z1, synchronizing patches, protecting your edits from accidental loss, naming programs, and designing custom microtonal scales on a 5-octave interactive keyboard.

---

## Screen Layout Overview

```
+---------------------------------------------------------------------------------------------------+
|  ROW 1: CONNECTION, PATCH SYNC, BACKUP & UNDO / REDO                                              |
|  [ Handshake ID ] [ Patch Req ]   [Recover Backup] [ Backup Now ]  [    Undo    ] [    Redo    ]  |
+---------------------------------------------------------------------------------------------------+
|  ROW 2: PROGRAM NAME EDITOR & AUTO PROGRAM-CHANGE SYNC                                            |
|  [   Name Pos   ] [  Name Char  ] [         Program Name         ] [PC Patch Req]                 |
+---------------------------------------------------------------------------------------------------+
|  ROW 3: 5-OCTAVE INTERACTIVE MICROTONAL KEYBOARD (C2 .. C7)                                       |
|  [ ||| | ||| ||| | ||| | ||| ||| | ||| | ||| ||| | ||| | ||| ||| | ||| | ||| ||| ]                |
+---------------------------------------------------------------------------------------------------+
|  ROW 4: SCALE & KEY TUNING CONTROLS                                                               |
|  [ Scale Target ] [Scale Octave*] [  Key Select  ] [   Key Tune   ]                               |
+---------------------------------------------------------------------------------------------------+
|  ROW 5: TUNING TRANSMISSION & PRESET DRAWER TOGGLE                                                |
|  [  Req Tuning  ] [ Send Tuning ] [ Reset Scale  ]                 [ Tune Preset ]                |
+---------------------------------------------------------------------------------------------------+
|  ROW 6: TUNING PRESET LIBRARY (Visible when "Tune Preset" is ON)                                  |
|  [ Preset List (16 Slots) ] [Name Pos / Char] [ Save / Rename ] [ Load / Delete ]                 |
+---------------------------------------------------------------------------------------------------+
```
*(\*`Scale Octave` appears automatically when `User Scale 2 (128 Keys)` is selected.)*

---

## 1. Connection & Patch Synchronization

### Automatic Handshake on Startup
When you load the preset, the Electra One automatically queries the Korg Z1 and discovers its active MIDI channel. If your Z1 is powered off when you first turn on the Electra One, the controller automatically retries every **5 seconds** until the Z1 comes online.

### Manual Connection & Patch Controls
- **Handshake ID**: Manually verifies the connection with the Korg Z1 and updates the MIDI channel if you changed it on the synth.
- **Patch Req**: Requests the currently active program from the Z1 and updates all 12 pages on the Electra One.
- **PC Patch Req** *(Toggle Button, Row 2 Right)*: When turned **ON**, changing presets on the Korg Z1 front panel automatically triggers a patch request so the Electra One screen always stays in sync with the synth. Turn this **OFF** if you want to browse programs on the Z1 without overwriting the controls currently shown on the Electra One.

---

## 2. Patch Protection Backup & One-Touch Recovery

On the Korg Z1 hardware, switching to another program immediately discards any unsaved edits in the edit buffer. The Electra One protects your work with an automatic **30-second safety window** plus manual snapshot backups:

- **Automatic 30-Second Protection**: Every time you edit a knob or slider, the Electra One keeps a backup of your work in memory. If you accidentally switch programs on the Z1 (or tap **Patch Req**), your previous edits remain protected for **30 seconds** without being overwritten by the newly loaded patch.
- **Backup Now**: Manually freezes your current patch into the backup slot at any time—ideal right before experimenting with major sound changes.
- **Recover Backup**: Restores your backed-up patch to all controls on the Electra One **and transmits the complete patch back to the Korg Z1 edit buffer** so the synth immediately plays your recovered sound again.

---

## 3. 16-Step Undo & Redo

- **Undo**: Steps backward through your last **16 parameter edits** and immediately updates the Korg Z1.
- **Redo**: Steps forward through any changes you just undid.
- **Smart Knob Grouping**: Smoothly sweeping a knob or fader is grouped into a **single Undo step**, so pressing **Undo** returns the parameter to where it started before the sweep rather than stepping through every single intermediate value.
- **Clean History**: Moving the patch-name cursor or typing letters into the patch name does not clutter your sound-design undo history.

---

## 4. Program Name Editor (Row 2)

You can rename the active 16-character Z1 program directly from the Utility page:

1. **Name Pos (`1` – `16`)**: Selects which character position in the 16-character patch name you want to edit.
2. **Name Char**: Scrolls through the available characters (`A–Z`, `a–z`, `0–9`, spaces, and symbols). While you turn **Name Char**, the character is highlighted on the display and sent directly to the Z1.
3. **Program Name Display**: Shows the full 16-character program name across two large lines (`chars 1–8` on top, `chars 9–16` below) with a bright cursor underline beneath the currently selected character position.

*(A read-only **Program Name** banner is also visible on the [Common & Arp](file:///home/timbos/src/Z1/usermanual/pages/11-common-arp.md) page so you can always see the active patch name when configuring performance settings.)*

---

## 5. Interactive 5-Octave Microtonal Scale Editor (Rows 3–5)

The Korg Z1 supports two global user-programmable microtonal scales stored inside the synthesizer:
- **User Scale 1 (Octave)**: A 12-note scale (`C` through `B`) whose cent offsets repeat identically across every octave on the keyboard.
- **User Scale 2 (128 Keys)**: A full-keyboard scale where every single MIDI note (`C-1` to `G9`, 128 notes total) can be tuned independently from `-99` to `+99` cents.

*(Note: To hear a user scale in your patch, set **Scale Type** on the [Common & Arp](file:///home/timbos/src/Z1/usermanual/pages/11-common-arp.md) page to `UserOctave` or `UserAllNote`.)*

### Using the 5-Octave Interactive Keyboard (`C2..C7`)
- **Touch Any Key to Select It**: Tap directly on any white or black key across the 5-octave piano display in Row 3 to select that note for tuning. The selected key is highlighted in white.
- **Visual Cent-Offset Bars**: Every key on the 5-octave keyboard draws a live vertical tuning gauge:
  - **Sharp (`+1` to `+99` cents)**: Drawn upward from the center line in **teal**.
  - **Flat (`-1` to `-99` cents)**: Drawn downward from the center line in **amber/orange**.
  - **Standard Equal Temperament (`0` cents)**: Clean center tick mark.

### Tuning Controls (Row 4)
- **Scale Target**: Switches between editing **User Scale 1 (Octave)** and **User Scale 2 (128 Keys)**.
- **Scale Octave** *(Appears automatically in `User Scale 2` mode)*: Shifts the 5-octave view window across the full 128-note MIDI range so you can view and edit the lowest sub-bass octaves or highest treble octaves.
- **Key Select**: Selects the active note by knob (synchronized with touching keys on the 5-octave piano graphic).
- **Key Tune (`-99` to `+99` cents)**: Adjusts the fine pitch offset of the selected note in cents (`100 cents = 1 semitone`) and updates the Z1 in real time.

### Scale Transmission Buttons (Row 5)
- **Req Tuning**: Pulls the current User Scale 1 and User Scale 2 tuning tables from the Korg Z1 into the Electra One.
- **Send Tuning**: Transmits the active scale from the Electra One to the Korg Z1.
- **Reset Scale**: Resets all notes in the currently selected scale back to `0` cents (standard Equal Temperament) and updates the Z1.

---

## 6. Tuning Preset Library (`Tune Preset`, Rows 5–6)

Tap the **Tune Preset** button on the right side of Row 5 to open or close the on-board **Tuning Preset Library** in Row 6. This library stores up to **16 custom named microtonal scales** inside the Electra One's persistent memory.

- **Preset List (Left Display)**: Scroll through the 16 tuning slots (`01`–`16`). The currently selected slot is highlighted with a teal bar and dark text for easy reading, along with a badge indicating whether the stored preset is a 12-note octave scale (`OCT`) or a 128-key full scale (`128`).
- **Name Pos & Name Char**: Position the cursor and dial in a custom name for your scale (for example, `Just Inton C`, `Arabic Rast`, or `Stretch Piano`).
- **Save**: Stores the current microtonal scale and your custom name into the selected slot.
- **Rename**: Updates the name of an existing saved tuning preset without altering its stored cent values.
- **Load**: Loads the selected tuning preset into the editor and transmits the scale directly to the Korg Z1.
- **Delete**: Clears the selected tuning preset slot back to `(Empty)`.

---

## Next Pages
- Continue to [Page 2: Common & Arp](file:///home/timbos/src/Z1/usermanual/pages/11-common-arp.md) to select your patch's **Scale Type** (`UserOctave` or `UserAllNote`), Unison, and Voice Assign mode.
- Jump to [Page 3: OSC Common](file:///home/timbos/src/Z1/usermanual/pages/03b-osc-common.md) to set oscillator tuning and manage oscillator presets.
