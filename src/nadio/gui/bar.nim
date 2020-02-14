import rapid/gfx except viewport
import rdgui/control
import rdgui/event
import rdgui/windows

import ../res
import view

type
  BarControl* = tuple
    bg, outline: RColor
    control: Control
  BarPosition* = enum
    bpTop
    bpBottom
  BarAlignment* = enum
    baLeft
    baRight
  Bar* = ref object of View
    position: BarPosition
    left: seq[BarControl]
    right: seq[BarControl]

method width*(bar: Bar): float = bar.rwin.width.float
method height*(bar: Bar): float = procCall bar.Window.height

method onEvent*(bar: Bar, ev: UiEvent) =
  for bct in bar.left:
    bct.control.event(ev)
    if ev.consumed:
      break
  if not ev.consumed:
    for bct in bar.right:
      bct.control.event(ev)
      if ev.consumed:
        break

proc add*(bar: Bar, align: BarAlignment, control: Control,
          background, outline: RColor, padding = 0.0) =
  bar.contain(control)
  let bc = BarControl (bg: background, outline: outline, control: control)
  case align
  of baLeft:
    var x = padding
    for bct in bar.left:
      x += bct.control.width + bar.height
    control.pos.x = x
    bar.left.add(bc)
  of baRight:
    var x = bar.width - padding
    for bct in bar.right:
      x -= bct.control.width + bar.height
    control.pos.x = x
    bar.right.add(bc)

proc drawBackground(bar: Bar, ctx: RGfxContext) =
  ctx.begin()
  ctx.color = theme.barFill
  ctx.rect(0, 0, bar.width, bar.height)
  ctx.draw()
  ctx.begin()
  ctx.color = theme.barLine
  ctx.line((0.0, 0.0), (bar.width, 0.0))
  ctx.line((0.0, bar.height), (bar.width, bar.height))
  ctx.color = gray(255)
  ctx.draw(prLineShape)

Bar.renderer(Plain, bar):
  bar.drawBackground(ctx)
  for bc in bar.left:
    bc.control.draw(ctx, step)
  for bc in bar.right:
    bc.control.draw(ctx, step)

Bar.renderer(Powerline, bar):
  bar.drawBackground(ctx)

var bars: seq[Bar]

proc initBar*(bar: Bar, wm: WindowManager, position: BarPosition, height: float,
              rend = BarPlain) =
  bar.initWindow(wm, x = 0, y = 0, width = 0, height, rend)
  bar.position = position
  bars.add(bar)

proc newBar*(wm: WindowManager, position: BarPosition, height: float,
             rend = BarPlain): Bar =
  new(result)
  result.initBar(wm, position, height, rend)

proc repositionBars*(width, height: Natural) =
  for bar in bars:
    case bar.position
    of bpTop:
      bar.pos.y = viewport.top
      viewport.top += bar.height
    of bpBottom:
      bar.pos.y = height.float - viewport.bottom - bar.height
      viewport.bottom += bar.height
