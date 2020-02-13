import rapid/gfx
import rdgui/windows

import gui
import res

when isMainModule:
  initResources()
  initGui()

  surface.loop:
    draw ctx, step:
      ctx.clear theme.bg
      wm.draw(ctx, step)
    update:
      discard
