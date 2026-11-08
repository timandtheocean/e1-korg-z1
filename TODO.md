# update
- update INSTRUCTION.md keep a TODO there to so merge this:

# rate throthle ?

# built
- complete patch parsing
- a build script that makes one preset will all pages in /home/timbos/src/Z1/e1
- import into webedit and improve the layout. 

# sub presets
- remove all fx preset functionality.
- [sub} Presets for: envelops, lfos, osc, filter, fx, arp, scales
- on the related pages a button to jump to the presets page. 

# morph
- Morph feature [SCENE Morph] : you press a [SCENE] button. 
Once its engaged ( turned on) every parameter you change will be the [morphed to state].
there will be a dial where you can morph between the newly created state and back to the state before we engaged ( turned on ) 
if [SCENE Morph] is enabled you should be able to navigate any presetpage and make changes. 
Be carefull not to use the undo/redo buffer as the state we [morph from]

# keyboard widget 
- for filter tracking
- preset and user scales

# widgets, EQ, envelope, arp, sequencer etc
https://roomi-fields.github.io/electraone-widgets/

# library 
- use the "Filter selector" 
see z1-filterwidget for json and lua
-Mixer. Customize the mixer for the 2x5 channels of the Z1
see z1-mixerwidget for json and lua
 -- 1. Define the custom names array before or inside the paint function
local channelNames = {"OSC1", "OSC2", "SUBOSC", "NOISE", "FeedBack"}
 
- Need to find out how we can create our own custom widgets. 

# base page 
- improve UI, 
- add controls to save, name and load sub presets


