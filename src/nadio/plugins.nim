when defined(posix) and not defined(nintendoswitch):
  import dynlib except loadLib
  from posix import dlopen, RTLD_LAZY
else:
  import dynlib
import os
import tables

import debug
import res

when defined(posix) and not defined(nintendoswitch):
  # use own loadLib implementation that uses RTLD_LAZY instead of RTLD_NOW to
  # prevent SIGSEGVing the app
  proc loadLib(path: string): LibHandle =
    result = dlopen(path, RTLD_LAZY)

type
  PluginMetadata* = proc (): string {.noconv.}
  PluginInit* = proc (res: var Resources) {.noconv.}
  Plugin* = ref object
    dll*: LibHandle
    name*, author*, version*: string
    init*: PluginInit
  PluginError* = object of LibraryError

proc loadPlugin*(path: string): Plugin =
  result = Plugin()
  result.dll = loadLib(path)

  result.name =
    $cast[PluginMetadata](result.dll.symAddr("nadioPluginGetName"))()
  result.author =
    $cast[PluginMetadata](result.dll.symAddr("nadioPluginGetAuthor"))()
  result.version =
    $cast[PluginMetadata](result.dll.symAddr("nadioPluginGetVersion"))()

  result.init = cast[PluginInit](result.dll.symAddr("nadioPluginInit"))

proc loadPlugins*(dest: var Table[string, Plugin], dir: string) =
  info "loading plugins from ", dir
  for kind, file in walkDir(dir):
    if kind in {pcFile, pcLinkToFile}:
      let plugin = loadPlugin(file)
      hint file, ": ", plugin.name, " ", plugin.version, ", by ", plugin.author
      if plugin.name in dest:
        raise newException(PluginError, "duplicate plugin " & plugin.name)
      dest[plugin.name] = plugin

proc callInit*(plugins: var Table[string, Plugin]) =
  info "initializing plugins"
  for name, plugin in plugins:
    info "· ", name
    # plugin.init(gRes)
