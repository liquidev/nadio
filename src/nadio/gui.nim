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
  info "initializing the user interface"
  wm = newWindowManager(win)

  info "creating bars"
  # order matters
  gApp.viewBar = wm.newBar(bpTop, 24, BarPlain)
  gApp.cmdBar = wm.newBar(bpBottom, 24, BarPlain)
  gApp.statusBar = wm.newBar(bpBottom, 24, BarPowerline)

  info "creating views"
  gApp.songView = wm.newView()
  gApp.pattView = wm.newView()
  gApp.instrView = wm.newView()

  info "adding windows"
  info "· views"
  wm.add(gApp.songView)
  wm.add(gApp.pattView)
  wm.add(gApp.instrView)
  info "· bars"
  wm.add(gApp.viewBar)
  wm.add(gApp.cmdBar)
  wm.add(gApp.statusBar)

  info "· view bar"
  var switcher: ViewSwitcher
  block:
    switcher = newViewSwitcher(0, 0, 24, font = sans, fontSize = 14)
    switcher.addView("View.song", gApp.songView)
    switcher.addView("View.pattern", gApp.pattView)
    switcher.addView("View.instrument", gApp.instrView)
    gApp.viewBar.add(baLeft, switcher, gray(0, 0), gray(0, 0), padding = 0)

  info "· command bar"
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

  info "· resize hook"

  proc layOutWindows(width, height: Natural) =
    resetViewport()
    repositionBars(width, height)
    switcher.resizeViews(width, height)

  win.onResize(layOutWindows)
  layOutWindows(win.width, win.height)

  info "adding keybinds"

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
    var editor = newNodeEditor(gApp.instrView, gApp.nodeLibrary)
    gApp.instrView.add(editor)
    var aout = editor.newNode(0, 0, "Node/AudioOut.name")
    editor.add(aout)
    aout.addInput("Node/AudioOut.inLeft", ioFloat)
    aout.addInput("Node/AudioOut.inRight", ioFloat)
    switcher.switchToView("View.instrument")
