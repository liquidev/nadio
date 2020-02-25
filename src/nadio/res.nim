import os
import tables

import rapid/gfx
import rapid/gfx/text
import rdgui/windows

import app_state
import debug
import themes

var app*: State

template win*: RWindow = app.win
template surface*: RGfx = app.surface
template wm*: WindowManager = app.wm

template sans*: RFont = app.res.sans
template sansBold*: RFont = app.res.sansBold
template mono*: RFont = app.res.mono
template theme*: Theme = app.res.theme

proc dataDir*(): string =
  when defined(windows):
    result = getHomeDir()/"AppData"/"Roaming"/"Nadio"
  elif defined(linux):
    result =
      if existsEnv("XDG_DATA_DIR"): getEnv("XDG_DATA_DIR")
      else: getHomeDir()/".local"/"share"/"Nadio"
  else:
    result = getHomeDir()/"Nadio"

proc initResources*() =
  log "initializing the window"
  app.win = initRWindow()
    .size(1280, 720) # TODO: save size somewhere in a data folder
    .title("Nadio")
    .antialiasLevel(8)
    .open()
  app.surface = win.openGfx()

  log "loading fonts"
  const
    sansTtf = slurp("data/fonts/Nunito-Regular.ttf")
    sansBoldTtf = slurp("data/fonts/Nunito-Bold.ttf")
    monoTtf = slurp("data/fonts/RobotoMono-Regular.ttf")
  app.res.sans = newRFont(sansTtf, 14)
  app.res.sansBold = newRFont(sansBoldTtf, 14)
  app.res.mono = newRFont(monoTtf, 12)

  log "setting theme"
  app.res.theme = ThemeDefault

  log "data directory: ", dataDir()
  createDir(dataDir())
  createDir(dataDir()/"plugins")

  log "init resources done"
