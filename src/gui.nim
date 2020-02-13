import sequtils
import tables

import rapid/gfx except viewport
import rdgui/control
import rdgui/textbox
import rdgui/windows

import debug
import gui/bar
import gui/view
import keybinds
import res

var
  viewBar*, commandBar*, statusBar*: Bar
  commandTextBox*: TextBox

  songView*, patternView*, instrumentView*: View

proc globalKeybinds(): Table[Keybind, KeybindAction] =
  result = {
    Keybind":": proc (chord: seq[Keybind]): bool {.closure.} =
      echo "!! opening command bar"
      commandTextBox.visible = true
      commandTextBox.focused = true
      echo commandTextBox.screenPos
      true,
  }.toTable

proc `$`(c: Control): string = $cast[int](c)
proc initGui*() =
  log "initializing gui"
  wm = newWindowManager(win)
  viewport = (top: 0.0, bottom: surface.height,
              left: 0.0, right: surface.width)

  log "creating bars"
  # order matters
  viewBar = wm.newBar(bpTop, 24, BarPlain)
  commandBar = wm.newBar(bpBottom, 24, BarPlain)
  statusBar = wm.newBar(bpBottom, 24, BarPowerline)

  log "creating views"
  songView = wm.newView()
  patternView = wm.newView()
  instrumentView = wm.newView()
  patternView.visible = false
  instrumentView.visible = false

  echo [viewBar, commandBar, statusBar, songView, patternView, instrumentView]

  log "adding windows"
  log "· views"
  wm.add(songView)
  wm.add(patternView)
  wm.add(instrumentView)
  log "· bars"
  wm.add(viewBar)
  wm.add(commandBar)
  wm.add(statusBar)

  log "· command bar"
  block:
    commandTextBox = newTextBox(0, 0, surface.width,
                                font = robotoMono, fontSize = 14)
    commandTextBox.visible = false
    commandBar.add(baLeft, commandTextBox, gray(0, 0), gray(0, 0))

  log "adding keybinds"
  songView.keybinds = globalKeybinds()
  patternView.keybinds = globalKeybinds()
  instrumentView.keybinds = globalKeybinds()

  echo wm.windows
