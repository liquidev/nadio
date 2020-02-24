import os
import tables

import rapid/gfx
import rdgui/windows

import gui
import i18n
import plugins
import res

proc main =
  initResources()
  app.loadStrings("en_US", BaseTranslations["en_US"])
  initGui()

  var plugins: Table[string, Plugin]
  plugins.loadPlugins(dataDir()/"plugins")

  surface.loop:
    draw ctx, step:
      ctx.clear theme.bg
      wm.draw(ctx, step)
    update:
      discard

when isMainModule: main()
