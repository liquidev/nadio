# Package

version       = "0.1.0"
author        = "liquid600pgm"
description   = "Nadio is an experimental digital audio workstation with a keyboard focused terminal user interface."
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["nadio/nadio"]
installExt    = @["nim"]

# Dependencies

requires "nim >= 1.0.4"
requires "rapid"           # windowing, graphics, and audio
requires "rdgui"           # user interface
requires "npeg >= 0.22.2"  # command parsing

# Tasks

from os import `/`, getHomeDir

const
  PluginOptions = "--app:lib --opt:speed --debugger:gdb"
  Plugins = [
    "test",
  ]

proc compilePlugin(name: string) =
  mkdir "plugins/_out"
  selfExec "c " & PluginOptions &
           " -o:plugins/_out/" & name.toDll &
           " plugins/" & name & "/" & name

task buildPlugins, "Builds all plugins to `plugins/_out`":
  for name in Plugins:
    echo ":: building plugin '" & name & "'"
    compilePlugin name

proc dataDir(): string =
  when defined(windows):
    result = getHomeDir()/"AppData"/"Roaming"/"Nadio"
  elif defined(linux):
    result =
      if existsEnv("XDG_DATA_DIR"): getEnv("XDG_DATA_DIR")/"Nadio"
      else: getHomeDir()/".local"/"share"/"Nadio"
  else:
    result = getHomeDir()/"Nadio"

task installPlugins, "Installs all plugins to platform-specific data directory":
  buildPluginsTask()
  mkdir dataDir()/"plugins"
  echo ":: plugin directory: " & dataDir()/"plugins"
  for name in Plugins:
    echo ":: installing plugin '" & name & "'"
    cpFile "plugins/_out/" & name.toDll, dataDir()/"plugins"/name.toDll
