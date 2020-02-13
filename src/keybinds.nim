import hashes
import unicode

import rapid/gfx

type
  Keybind* = distinct string
  KeybindAction* = proc (chord: seq[Keybind]): bool ## \
    ## should return false if more keys are needed, true if the chord is
    ## complete

proc toKeybind*(rune: Rune, mods: RModKeys): Keybind =
  var k = $rune
  if mkCtrl in mods: k = "^" & k
  result = k.Keybind

proc `==`*(a, b: Keybind): bool {.borrow.}
proc `==`*(a: Keybind, b: string): bool {.borrow.}
proc hash*(kb: Keybind): Hash {.borrow.}
proc `$`*(kb: Keybind): string {.borrow.}
