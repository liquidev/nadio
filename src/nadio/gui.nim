import sequtils
import tables

import rapid/gfx except viewport
import rapid/gfx/text
import rdgui/control
import rdgui/label
import rdgui/textbox
import rdgui/windows

import app
import commands
import debug
import gui/bar
import gui/command_box
import gui/node_editor
import gui/renderers
import gui/view
import gui/view_switcher
import keybinds
import res

proc initGui*() =
  log "initializing the user interface"
  wm = newWindowManager(win)

  log "creating bars"
  # order matters
  gApp.viewBar = wm.newBar(bpTop, 24, BarPlain)
  gApp.cmdBar = wm.newBar(bpBottom, 24, BarPlain)
  gApp.statusBar = wm.newBar(bpBottom, 24, BarPowerline)

  log "creating views"
  gApp.songView = wm.newView()
  gApp.pattView = wm.newView()
  gApp.instrView = wm.newView()

  log "adding windows"
  log "· views"
  wm.add(gApp.songView)
  wm.add(gApp.pattView)
  wm.add(gApp.instrView)
  log "· bars"
  wm.add(gApp.viewBar)
  wm.add(gApp.cmdBar)
  wm.add(gApp.statusBar)

  log "· view bar"
  var switcher: ViewSwitcher
  block:
    switcher = newViewSwitcher(0, 0, 24, font = sans, fontSize = 14)
    switcher.addView("View.song", gApp.songView)
    switcher.addView("View.pattern", gApp.pattView)
    switcher.addView("View.instrument", gApp.instrView)
    gApp.viewBar.add(baLeft, switcher, gray(0, 0), gray(0, 0), padding = 0)

  log "· command bar"
  var
    cmdTextBox: TextBox
    msgLabel: Label
  block:
    var wrapper = newBox(0, 0)
    gApp.cmdBar.add(baLeft, wrapper, gray(0, 0), gray(0, 0), padding = 0)
    msgLabel = newLabel(4, 4, "", font = mono, fontSize = 12)
    cmdTextBox = newCommandBox(8, 4, surface.width, 16,
                               font = mono, fontSize = 12)
    cmdTextBox.visible = false
    cmdTextBox.onAccept = proc () =
      if cmdTextBox.text.len > 0:
        let error = runCommand(cmdTextBox.text)
        if error.len > 0:
          msgLabel.text = "E: " & error
      cmdTextBox.text = ""
      cmdTextBox.focused = false
      cmdTextBox.visible = false
    wrapper.add(cmdTextBox)
    wrapper.add(msgLabel)

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
        cmdTextBox.visible = true
        cmdTextBox.focused = true
        msgLabel.text = ""
        true,
    }.toTable

  gApp.songView.keybinds = globalKeybinds()
  gApp.pattView.keybinds = globalKeybinds()
  gApp.instrView.keybinds = globalKeybinds()

  # debugging stuff, TODO: remove later
  block:
    var editor = newNodeEditor(gApp.instrView)
    gApp.instrView.add(editor)
    var
      node1 = editor.newNode(-256, -128, "Node/SinOsc.name")
      node2 = editor.newNode(0.002, 0, "Node/AudioOut.name")
    editor.add(node1)
    editor.add(node2)
    node1.addInput("Node/SinOsc.inFrequency", ioFloat)
    node1.addOutput("Node/SinOsc.outWave", ioFloat)
    node2.addInput("Node/AudioOut.inLeft", ioFloat)
    node2.addInput("Node/AudioOut.inRight", ioFloat)
    # node1.outputs["Node/SinOsc.outWave"]
    #   .connect(node2.inputs["Node/AudioOut.inAudio"])
    switcher.switchToView("View.instrument")
