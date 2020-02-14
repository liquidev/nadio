import math
import options
import tables

import rapid/gfx
import rapid/gfx/text
import rdgui/button
import rdgui/control
import rdgui/event

import ../i18n
import ../res
import view

type
  ViewSwitcher* = ref object of Control
    fHeight: float
    views*: OrderedTable[string, View]
    font*: RFont
    fontSize*: int
    buttonWidth: float
    currentView: string

method width*(vs: ViewSwitcher): float = vs.views.len.float * vs.buttonWidth
method height*(vs: ViewSwitcher): float = vs.fHeight

proc `height=`*(vs: ViewSwitcher, newHeight: float) =
  vs.fHeight = newHeight

proc buttonWidth*(vs: ViewSwitcher): float = vs.buttonWidth
proc currentView*(vs: ViewSwitcher): string = vs.currentView

proc selectedButton*(vs: ViewSwitcher): Option[string] =
  var x = 0.0
  for name, _ in vs.views:
    if vs.mouseInRect(x, 0, vs.buttonWidth, vs.height):
      return some(name)
    x += vs.buttonWidth

proc switchToView*(vs: ViewSwitcher, name: string) =
  for _, vw in vs.views:
    vw.visible = false
  vs.views[name].visible = true
  vs.currentView = name

proc calculateSpacing(vs: ViewSwitcher) =
  let oldFontHeight = vs.font.height
  vs.font.height = vs.fontSize

  vs.buttonWidth = 0
  for name, _ in vs.views:
    vs.buttonWidth = max(vs.buttonWidth, vs.font.widthOf(name.i))
  vs.buttonWidth += 16
  vs.buttonWidth = round(vs.buttonWidth)

  vs.font.height = oldFontHeight

proc addView*(vs: ViewSwitcher, name: string, vw: View) =
  vs.views.add(name, vw)
  vs.calculateSpacing()
  if vs.views.len == 1:
    vs.switchToView(name)

proc resizeViews*(vs: ViewSwitcher, width, height: Natural) =
  for _, vw in vs.views:
    vw.fillViewport(width.float, height.float)

method onEvent*(vs: ViewSwitcher, ev: UiEvent) =
  if ev.kind == evMousePress and ev.mouseButton == mb1:
    let name = vs.selectedButton
    if name.isSome:
      vs.switchToView(name.get)

ViewSwitcher.renderer(Major, vs):
  let oldFontHeight = vs.font.height
  vs.font.height = vs.fontSize

  let hoverView = vs.selectedButton
  var x = 0.0
  for name, _ in vs.views:
    if vs.currentView == name:
      ctx.begin()
      ctx.color = theme.viewSwitcherCurrent
      ctx.rect(x, 0, vs.buttonWidth, vs.height)
      ctx.draw()
    ctx.color = gray(255)
    ctx.text(vs.font, x, y = -2, name.i, vs.buttonWidth, h = vs.height,
             hAlign = taCenter, vAlign = taMiddle)
    if hoverView.isSome and name == hoverView.get:
      ctx.begin()
      ctx.color =
        if vs.currentView == hoverView.get and
           win.mouseButton(mb1) == kaDown: theme.viewSwitcherPress
        else: theme.viewSwitcherHover
      ctx.rect(x, 0, vs.buttonWidth, vs.height)
      ctx.draw()
    x += vs.buttonWidth
  ctx.color = gray(255)

  vs.font.height = oldFontHeight

proc initViewSwitcher*(vs: ViewSwitcher, x, y, height: float,
                       font: RFont, fontSize = 14, rend = ViewSwitcherMajor) =
  vs.initControl(x, y, rend)
  vs.height = height
  vs.font = font
  vs.fontSize = fontSize

proc newViewSwitcher*(x, y, height: float, font: RFont, fontSize = 14,
                      rend = ViewSwitcherMajor): ViewSwitcher =
  new(result)
  result.initViewSwitcher(x, y, height, font, fontSize, rend)
