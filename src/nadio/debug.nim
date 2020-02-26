import strutils
import terminal

proc log*(text: varargs[string, `$`]) {.deprecated.} =
  discard

proc hint*(text: varargs[string, `$`]) =
  stderr.styledWriteLine(styleBright, fgGreen, "h  ",
                         resetStyle, text.join)

proc info*(text: varargs[string, `$`]) =
  stderr.styledWriteLine(styleBright, fgCyan, "i  ",
                         resetStyle, text.join)

proc warning*(text: varargs[string, `$`]) =
  stderr.styledWriteLine(styleBright, fgYellow, "!  ",
                         resetStyle, text.join)

proc error*(text: varargs[string, `$`]) =
  stderr.styledWriteLine(styleBright, fgRed, "!! ",
                         resetStyle, text.join)
