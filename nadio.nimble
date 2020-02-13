# Package

version       = "0.1.0"
author        = "liquid600pgm"
description   = "Nadio is an experimental digital audio workstation with a keyboard focused terminal user interface."
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["nadio/nadio"]

# Dependencies

requires "nim >= 1.0.4"
requires "rapid"           # windowing, graphics, and audio
requires "rdgui"           # user interface
requires "npeg >= 0.22.2"  # command parsing
