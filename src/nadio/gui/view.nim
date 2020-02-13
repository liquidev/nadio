import tables
import unicode

import rapid/gfx
import rdgui/control
import rdgui/event
import rdgui/windows

import ../keybinds
import ../modes

type
  View* = ref object of Window
    mode*: Mode
    keybindBuffer*: seq[Keybind]
    keybinds*: Table[Keybind, KeybindAction]

method onEvent*(vw: View, ev: UiEvent) =
  # block mouse events if the mouse is outside the view's bounding box
  if ev.kind in {evMousePress..evMouseScroll}:
    if vw.mouseInRect(0, 0, vw.width, vw.height):
      procCall vw.Window.onEvent(ev)
  else:
    procCall vw.Box.onEvent(ev)
  if not ev.consumed:
    if ev.kind == evKeyPress:
      if ev.key == keyEscape:
        if vw.keybindBuffer.len != 0:
          vw.keybindBuffer.setLen(0)
        else:
          vw.mode = modeNormal
        ev.consume()
    elif ev.kind == evKeyChar:
      vw.keybindBuffer.add(toKeybind(ev.rune, ev.modKeys))
      if vw.keybindBuffer[0] in vw.keybinds:
        if vw.keybinds[vw.keybindBuffer[0]](vw.keybindBuffer):
          vw.keybindBuffer.setLen(0)
      ev.consume()

View.renderer(Default, vw):
  let pos = vw.screenPos
  ctx.scissor(pos.x, pos.y, vw.width, vw.height):
    BoxChildren(ctx, step, vw)

proc initView*(vw: View, wm: WindowManager, x, y, width, height: float,
               rend = ViewDefault) =
  vw.initWindow(wm, x, y, width, height, rend)
  vw.width = width
  vw.height = height

proc newView*(wm: WindowManager, x, y, width, height: float,
              rend = ViewDefault): View =
  new(result)
  result.initView(wm, x, y, width, height, rend)

var viewport* = (top: 0.0, bottom: 0.0, left: 0.0, right: 0.0)
  # initialized in /gui

proc newView*(wm: WindowManager, rend = ViewDefault): View =
  ## Creates a new view filling the viewport.
  ## This is used for the major views (Song, Pattern, Instrument).
  let
    x = viewport.left
    y = viewport.top
    width = viewport.right - viewport.left
    height = viewport.bottom - viewport.top
  result = wm.newView(x, y, width, height, rend)
