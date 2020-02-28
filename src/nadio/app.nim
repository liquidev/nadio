import debug
import gui/bar
import gui/node_editor
import gui/view

type
  App* = ref object
    viewBar*, cmdBar*, statusBar*: Bar
    songView*, pattView*, instrView*: View
    nodeLibrary*: NodeLibrary

var gApp*: App

proc initApp*() =
  new(gApp)

  info "creating node library"
  gApp.nodeLibrary = newNodeLibrary()

proc addNode*(app: App, spec: NodeSpec) =
  app.nodeLibrary.add(spec)
