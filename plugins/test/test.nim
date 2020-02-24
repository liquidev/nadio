import nadio/i18n
import nadio/res

proc nadioPluginGetName*: string {.noconv, exportc, dynlib.} = "test plugin"
proc nadioPluginGetAuthor*: string {.noconv, exportc, dynlib.} = "iLiquid"
proc nadioPluginGetVersion*: string {.noconv, exportc, dynlib.} = "0.1.0"

proc nadioPluginInit*(app: var State) {.noconv, exportc, dynlib.} =
  echo "hello from plugin"
  echo "current language: ", app.getString("Language.name")
