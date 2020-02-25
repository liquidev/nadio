import rapid/gfx
import rapid/gfx/text
import rdgui/windows

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
