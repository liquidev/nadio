import parsecfg
import streams
import tables

import debug

const
  Translations = {
    "en_US": slurp("data/lang/en_US.cfg"),
  }.toTable

var strings: Table[string, string]

proc loadStrings*(lang: string) =
  log "loading language ", lang
  if lang notin Translations:
    raise newException(KeyError, "translation not found: " & lang)

  # TODO: embed a compile-time table for this using macros to speed up loading
  log "parsing strings"
  var
    input = newStringStream(Translations[lang])
    parser: CfgParser
    section = ""
    errors = ""

  proc error(msg: string) =
    errors.add(parser.errorStr(msg) & '\n')

  parser.open(input, "Translations[" & lang & "]")  
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
        strings[section & '.' & ev.key] = ev.value
    of cfgOption:
      error("options are invalid")
    of cfgError:
      error(ev.msg)

  if errors.len > 0:
    raise newException(ValueError, errors)

proc i*(key: string): string =
  if key notin strings:
    result = key
  else:
    result = strings[key]
