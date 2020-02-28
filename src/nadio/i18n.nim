import parsecfg
import streams
import tables

import debug

type
  LangTable* = TableRef[string, string]

const
  BaseTranslations* = {
    "en_US": slurp("data/lang/en_US.cfg"),
  }.toTable

proc init*(tab: var LangTable) =
  tab = newTable[string, string]()

proc loadStrings*(tab: LangTable, name, lang: string) =
  info "loading language ", name

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
        tab[section & '.' & ev.key] = ev.value
    of cfgOption:
      error("options are invalid")
    of cfgError:
      error(ev.msg)

  if errors.len > 0:
    raise newException(ValueError, errors)

proc getString*(tab: LangTable, key: string): string =
  echo "@ getString"
  echo key
  if key notin tab:
    result = key
  else:
    result = tab[key]
