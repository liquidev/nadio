import terminal

proc log*(text: varargs[string, `$`]) =
  stderr.writeLine text
