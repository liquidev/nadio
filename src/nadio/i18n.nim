import parsecfg
import streams
import tables

import debug
import res

const
  BaseTranslations* = {
    "en_US": slurp("data/lang/en_US.cfg"),
  }.toTable

proc loadStrings*(app: var State, name, lang: string) =
  log "loading language ", name

  # TODO: embed a compile-time table for this using macros to speed up loading
  log "parsing strings"
  var
    input = newStringStream(lang)
    parser: CfgParser
    section = ""
    errors = ""

  proc error(msg: string) =
    errors.add(parser.errorStr(msg) & '\n')

  parser.open(input, name)  
  while true:
    let ev = parser.next()
    case ev.kind
    of cfgEof: break
    of cfgSectionStart:
      section = ev.section
    of cfgKeyValuePair:
      if section.len == 0:
        error("string has no section")
      else:
        app.res.strings[section & '.' & ev.key] = ev.value
    of cfgOption:
      error("options are invalid")
    of cfgError:
      error(ev.msg)

  if errors.len > 0:
    raise newException(ValueError, errors)

proc getString*(app: State, key: string): string =
  if key notin app.res.strings:
    result = key
  else:
    result = app.res.strings[key]

proc i*(key: string): string =
  result = app.getString(key)
