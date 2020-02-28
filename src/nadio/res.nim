import os
import tables

import rapid/gfx
import rapid/gfx/text
import rdgui/windows

import debug
import i18n
import themes

type
  Resources* = ref object
    win*: RWindow
    surface*: RGfx
    wm*: WindowManager
    sans*, sansBold*, mono*: RFont
    theme*: Theme
    strings*: LangTable

proc loadStrings*(res: Resources, name, lang: string) =
  res.strings.loadStrings(name, lang)

proc getString*(res: Resources, key: string): string =
  echo res == nil
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
  if existsEnv("NADIO_DATA_DIR"): return getEnv("NADIO_DATA_DIR")
  when defined(windows):
    result = getHomeDir()/"AppData"/"Roaming"/"Nadio"
  elif defined(linux):
    result =
      if existsEnv("XDG_DATA_DIR"): getEnv("XDG_DATA_DIR")/"Nadio"
      else: getHomeDir()/".local"/"share"/"Nadio"
  else:
    result = getHomeDir()/"Nadio"
    once:
      warning "unsupported platform, data directory defaults to ~/Nadio"

proc initResources*() =
  new(gRes)

  info "initializing the window"
  gRes.win = initRWindow()
    .size(1280, 720) # TODO: save size somewhere in a data folder
    .title("Nadio")
    .antialiasLevel(8)
    .open()
  gRes.surface = win.openGfx()

  info "loading fonts"
  const
    sansTtf = slurp("data/fonts/Nunito-Regular.ttf")
    sansBoldTtf = slurp("data/fonts/Nunito-Bold.ttf")
    monoTtf = slurp("data/fonts/RobotoMono-Regular.ttf")
  gRes.sans = newRFont(sansTtf, 14)
  gRes.sansBold = newRFont(sansBoldTtf, 14)
  gRes.mono = newRFont(monoTtf, 12)

  info "loading strings"
  gRes.strings.init()
  gRes.loadStrings("en_US", BaseTranslations["en_US"])

  info "setting theme"
  gRes.theme = ThemeDefault

  hint "data directory: ", dataDir()
  createDir(dataDir())
  createDir(dataDir()/"plugins")

  info "init resources done"
