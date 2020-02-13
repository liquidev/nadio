import sequtils
import tables

import rapid/gfx except viewport
import rapid/gfx/text
import rdgui/control
import rdgui/textbox
import rdgui/windows

import commands
import debug
import gui/bar
import gui/commandbox
import gui/renderers
import gui/view
import gui/viewswitcher
import keybinds
import res

var
  viewBar*, commandBar*, statusBar*: Bar
  songView*, patternView*, instrumentView*: View

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

  log "adding windows"
  log "· views"
  wm.add(songView)
  wm.add(patternView)
  wm.add(instrumentView)
  log "· bars"
  wm.add(viewBar)
  wm.add(commandBar)
  wm.add(statusBar)

  log "· view bar"
  block:
    var switcher = newViewSwitcher(0, 0, 24, font = nunito, fontSize = 14)
    switcher.addView("View.song", songView)
    switcher.addView("View.pattern", patternView)
    switcher.addView("View.instrument", instrumentView)
    viewBar.add(baLeft, switcher, gray(0, 0), gray(0, 0), padding = 0)

  log "· command bar"
  var commandTextBox: TextBox
  block:
    commandTextBox = newCommandBox(0, 4, surface.width, 16,
                                       font = robotoMono, fontSize = 14)
    commandTextBox.visible = false
    commandTextBox.onAccept = proc () =
      echo runCommand(commandTextBox.text)
      commandTextBox.text = ""
      commandTextBox.focused = false
      commandTextBox.visible = false
    commandBar.add(baLeft, commandTextBox, gray(0, 0), gray(0, 0),
                   padding = 8)

  log "adding keybinds"

  proc globalKeybinds(): Table[Keybind, KeybindAction] =
    result = {
      Keybind":": proc (chord: seq[Keybind]): bool {.closure.} =
        commandTextBox.visible = true
        commandTextBox.focused = true
        true,
    }.toTable

  songView.keybinds = globalKeybinds()
  patternView.keybinds = globalKeybinds()
  instrumentView.keybinds = globalKeybinds()
