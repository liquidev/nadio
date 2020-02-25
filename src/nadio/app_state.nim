import rapid/gfx
import rapid/gfx/text
import rdgui/windows

import i18n
import plugins/node_library
import themes

type
  State* = object
    win*: RWindow
    surface*: RGfx
    wm*: WindowManager
    res*: Resources
    library*: NodeLibrary
  Resources = object
    sans*, sansBold*, mono*: RFont
    theme*: Theme
    strings*: LangTable

proc loadStrings*(app: var State, name, lang: string) =
  app.res.strings.loadStrings(name, lang)

proc getString*(app: State, key: string): string =
  result = app.res.strings.getString(key)
