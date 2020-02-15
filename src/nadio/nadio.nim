import rapid/gfx
import rdgui/windows

import gui
import i18n
import res

when isMainModule:
  initResources()
  loadStrings("en_US")
  initGui()

  surface.loop:
    draw ctx, step:
      ctx.clear theme.bg
      wm.draw(ctx, step)
    update:
      discard
