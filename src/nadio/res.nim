import rapid/gfx
import rapid/gfx/text
import rdgui/windows

import debug
import themes

var
  win*: RWindow
  surface*: RGfx
  wm*: WindowManager

  nunito*, nunitoBold*, robotoMono*: RFont

  theme*: Theme

proc initResources*() =
  log "initializing the window"
  win = initRWindow()
    .size(1280, 720) # TODO: save size somewhere in a data folder
    .title("Nadio")
    .open()
  surface = win.openGfx()

  log "loading fonts"
  const
    nunitoTtf = slurp("data/fonts/Nunito-Regular.ttf")
    nunitoBoldTtf = slurp("data/fonts/Nunito-Bold.ttf")
    robotoMonoTtf = slurp("data/fonts/RobotoMono-Regular.ttf")
  nunito = newRFont(nunitoTtf, 14)
  nunitoBold = newRFont(nunitoBoldTtf, 14)
  robotoMono = newRFont(robotoMonoTtf, 14)

  log "setting theme"
  theme = ThemeDefault

  log "init resources done"
