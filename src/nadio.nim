import rapid/gfx
import rdgui/windows

import gui
import res

when isMainModule:
  initResources()
  initGui()

  echo cast[int](wm)

  surface.loop:
    draw ctx, step:
      ctx.clear theme.bg
      wm.draw(ctx, step)
    update:
      discard
