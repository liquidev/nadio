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
    init ctx:
      ctx.lineSmooth = true
    draw ctx, step:
      ctx.clear theme.bg
      wm.draw(ctx, step)
    update:
      discard
