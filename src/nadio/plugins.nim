import dynlib
import os
import tables

import debug
import res

type
  PluginMetadata* = proc (): cstring {.cdecl.}
  PluginInit* = proc (app: var State) {.cdecl.}
  Plugin* = ref object
    dll*: LibHandle
    name*, author*, version*: string
    init*: PluginInit
  PluginError* = object of LibraryError

proc dlerror(): cstring {.importc.}

proc loadPlugin*(path: string): Plugin =
  result = Plugin()
  result.dll = loadLib(path)

  echo cast[int](result.dll.symAddr("nadPluginGetName"))
  echo dlerror()

  result.name =
    $cast[PluginMetadata](result.dll.symAddr("nadPluginGetName"))()
  result.author =
    $cast[PluginMetadata](result.dll.symAddr("nadPluginGetAuthor"))()
  result.version =
    $cast[PluginMetadata](result.dll.symAddr("nadPluginGetVersion"))()

  result.init = cast[PluginInit](result.dll.symAddr("nadPluginInit"))

proc loadPlugins*(dest: var Table[string, Plugin], dir: string) =
  log "loading plugins from ", dir
  for kind, file in walkDir(dir):
    if kind in {pcFile, pcLinkToFile}:
      stderr.write("plugin " & file)
      let plugin = loadPlugin(file)
      log ": ", plugin.name, " ", plugin.version, ", by ", plugin.author
      if plugin.name in dest:
        raise newException(PluginError, "duplicate plugin " & plugin.name)
      dest[plugin.name] = plugin

proc callInit*(plugins: var Table[string, Plugin]) =
  log "initializing plugins"
  for name, plugin in plugins:
    log "· ", name
    plugin.init(app)
