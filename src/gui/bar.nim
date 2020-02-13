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
    left: seq[BarControl]
    right: seq[BarControl]

method width*(bar: Bar): float = bar.rwin.width.float
method height*(bar: Bar): float = procCall bar.Window.height

method onEvent*(bar: Bar, ev: UiEvent) =
  discard

proc add*(bar: Bar, align: BarAlignment, control: Control,
          background, outline: RColor) =
  let bc = BarControl (bg: background, outline: outline, control: control)
  case align
  of baLeft:
    var x = 0.0
    for bct in bar.left:
      x += bct.control.width + bar.height
    control.pos = vec2(x, 0.0)
    bar.left.add(bc)
  of baRight:
    var x = bar.width
    for bct in bar.right:
      x -= bct.control.width + bar.height
    control.pos = vec2(x, 0.0)
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
  ctx.draw(prLineShape)

Bar.renderer(Plain, bar):
  bar.drawBackground(ctx)
  for bc in bar.left:
    bc.control.draw(ctx, step)
  for bc in bar.right:
    bc.control.draw(ctx, step)

Bar.renderer(Powerline, bar):
  bar.drawBackground(ctx)

proc initBar*(bar: Bar, wm: WindowManager, position: BarPosition, height: float,
              rend = BarPlain) =
  var y: float
  case position
  of bpTop:
    y = viewport.top
    viewport.top += height
  of bpBottom:
    y = viewport.bottom - height
    viewport.bottom -= height
  bar.initWindow(wm, x = 0, y, width = 0, height, rend)

proc newBar*(wm: WindowManager, position: BarPosition, height: float,
             rend = BarPlain): Bar =
  new(result)
  result.initBar(wm, position, height, rend)
