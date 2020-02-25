import gui/bar
import gui/view

type
  App* = object
    viewBar*, cmdBar*, statusBar*: Bar
    songView*, pattView*, instrView*: View

var gApp*: App
