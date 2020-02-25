import os
import tables

import rapid/gfx
import rapid/gfx/text
import rdgui/windows

import debug
import i18n
import themes

type
  Resources* = object
    win*: RWindow
    surface*: RGfx
    wm*: WindowManager
    sans*, sansBold*, mono*: RFont
    theme*: Theme
    strings*: LangTable

proc loadStrings*(res: var Resources, name, lang: string) =
  res.strings.loadStrings(name, lang)

proc getString*(res: Resources, key: string): string =
  result = res.strings.getString(key)

var gRes*: Resources

template win*: RWindow = gRes.win
template surface*: RGfx = gRes.surface
template wm*: WindowManager = gRes.wm

template sans*: RFont = gRes.sans
template sansBold*: RFont = gRes.sansBold
template mono*: RFont = gRes.mono
template theme*: Theme = gRes.theme

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
  gRes.win = initRWindow()
    .size(1280, 720) # TODO: save size somewhere in a data folder
    .title("Nadio")
    .antialiasLevel(8)
    .open()
  gRes.surface = win.openGfx()

  log "loading fonts"
  const
    sansTtf = slurp("data/fonts/Nunito-Regular.ttf")
    sansBoldTtf = slurp("data/fonts/Nunito-Bold.ttf")
    monoTtf = slurp("data/fonts/RobotoMono-Regular.ttf")
  gRes.sans = newRFont(sansTtf, 14)
  gRes.sansBold = newRFont(sansBoldTtf, 14)
  gRes.mono = newRFont(monoTtf, 12)

  log "loading strings"
  gRes.loadStrings("en_US", BaseTranslations["en_US"])

  log "setting theme"
  gRes.theme = ThemeDefault

  log "data directory: ", dataDir()
  createDir(dataDir())
  createDir(dataDir()/"plugins")

  log "init resources done"
