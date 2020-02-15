import sequtils
import tables

import rapid/gfx except viewport
import rapid/gfx/text
import rdgui/control
import rdgui/label
import rdgui/textbox
import rdgui/windows

import commands
import debug
import gui/bar
import gui/commandbox
import gui/nodeeditor
import gui/renderers
import gui/view
import gui/viewswitcher
import keybinds
import res

var
  viewBar*, commandBar*, statusBar*: Bar
  songView*, patternView*, instrumentView*: View

proc initGui*() =
  log "initializing the user interface"
  wm = newWindowManager(win)

  log "creating bars"
  # order matters
  viewBar = wm.newBar(bpTop, 24, BarPlain)
  commandBar = wm.newBar(bpBottom, 24, BarPlain)
  statusBar = wm.newBar(bpBottom, 24, BarPowerline)

  log "creating views"
  songView = wm.newView()
  patternView = wm.newView()
  instrumentView = wm.newView()

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
  var switcher: ViewSwitcher
  block:
    switcher = newViewSwitcher(0, 0, 24, font = sans, fontSize = 14)
    switcher.addView("View.song", songView)
    switcher.addView("View.pattern", patternView)
    switcher.addView("View.instrument", instrumentView)
    viewBar.add(baLeft, switcher, gray(0, 0), gray(0, 0), padding = 0)

  log "· command bar"
  var
    commandTextBox: TextBox
    messageLabel: Label
  block:
    var wrapper = newBox(0, 0)
    commandBar.add(baLeft, wrapper, gray(0, 0), gray(0, 0), padding = 0)
    messageLabel = newLabel(4, 4, "", font = mono, fontSize = 12)
    commandTextBox = newCommandBox(8, 4, surface.width, 16,
                                   font = mono, fontSize = 12)
    commandTextBox.visible = false
    commandTextBox.onAccept = proc () =
      if commandTextBox.text.len > 0:
        let error = runCommand(commandTextBox.text)
        if error.len > 0:
          messageLabel.text = "E: " & error
      commandTextBox.text = ""
      commandTextBox.focused = false
      commandTextBox.visible = false
    wrapper.add(commandTextBox)
    wrapper.add(messageLabel)

  log "· resize hook"

  proc layOutWindows(width, height: Natural) =
    resetViewport()
    repositionBars(width, height)
    switcher.resizeViews(width, height)

  win.onResize(layOutWindows)
  layOutWindows(win.width, win.height)

  log "adding keybinds"

  proc globalKeybinds(): Table[Keybind, KeybindAction] =
    result = {
      Keybind":": proc (chord: seq[Keybind]): bool {.closure.} =
        commandTextBox.visible = true
        commandTextBox.focused = true
        messageLabel.text = ""
        true,
    }.toTable

  songView.keybinds = globalKeybinds()
  patternView.keybinds = globalKeybinds()
  instrumentView.keybinds = globalKeybinds()

  # debugging stuff, TODO: remove later
  block:
    var editor = newNodeEditor(instrumentView)
    instrumentView.add(editor)
    var
      node1 = editor.newNode(-256, -128, "Node/SinOsc.name")
      node2 = editor.newNode(0, 0, "Node/AudioOut.name")
    editor.add(node1)
    editor.add(node2)
    node1.addInput("Node/SinOsc.inFrequency", ioFloat)
    node1.addOutput("Node/SinOsc.outWave", ioFloat)
    node2.addInput("Node/AudioOut.inAudio", ioFloat)
    # node1.outputs["Node/SinOsc.outWave"]
    #   .connect(node2.inputs["Node/AudioOut.inAudio"])
    switcher.switchToView("View.instrument")
