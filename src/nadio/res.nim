import rapid/gfx
import rapid/gfx/text
import rdgui/windows

import debug
import themes

var
  win*: RWindow
  surface*: RGfx
  wm*: WindowManager

  sans*, sansBold*, mono*: RFont

  theme*: Theme

proc initResources*() =
  log "initializing the window"
  win = initRWindow()
    .size(1280, 720) # TODO: save size somewhere in a data folder
    .title("Nadio")
    .antialiasLevel(8)
    .open()
  surface = win.openGfx()

  log "loading fonts"
  const
    sansTtf = slurp("data/fonts/Nunito-Regular.ttf")
    sansBoldTtf = slurp("data/fonts/Nunito-Bold.ttf")
    monoTtf = slurp("data/fonts/RobotoMono-Regular.ttf")
  sans = newRFont(sansTtf, 14)
  sansBold = newRFont(sansBoldTtf, 14)
  mono = newRFont(monoTtf, 12)

  log "setting theme"
  theme = ThemeDefault

  log "init resources done"
