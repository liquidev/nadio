## This module implements a node editor.
## Nadio doesn't use nodes for producing audio directly, they're only an
## intermediate representation used in the GUI.

import tables

import rapid/gfx
import rapid/gfx/text
import rdgui/control
import rdgui/event

import ../i18n
import ../res
import nodeeditor_defs # IoKind, IoSignal
import view

export nodeeditor_defs

type
  Io* = ref object of Control
    editor: NodeEditor
    name*: string
    kind*: IoKind
    signal*: IoSignal
  Node* = ref object of Control
    editor: NodeEditor
    fWidth, fHeight: float
    name*: string
    inputs*, outputs*: OrderedTable[string, Io]
    dragging: bool
  NodeEditor* = ref object of Box
    scroll: Vec2[float]
    zoom: float
    scrolling: bool

#--
# I/O implementation
#--

method width*(io: Io): float = 12 + sans.widthOf(io.name.i)
method height*(io: Io): float = 20

Io.renderer(Standard, io):
  ctx.begin()
  ctx.color = theme.ioSignals[io.signal]
  ctx.circle(x = (if io.kind == ioIn: 0.0 else: io.width),
             io.height / 2,
             r = 4)
  ctx.color = theme.nodeIoText
  ctx.draw()
  if io.kind == ioIn:
    ctx.text(sans, 12, -2, io.name.i, h = io.height, vAlign = taMiddle)
  elif io.kind == ioOut:
    ctx.text(sans, io.width - 12, -2, io.name.i,
             h = io.height, hAlign = taRight, vAlign = taMiddle)

proc initIo*(io: Io, editor: NodeEditor, x, y: float, name: string,
             kind: IoKind, signal: IoSignal) =
  io.initControl(x, y, IoStandard)
  io.editor = editor
  io.name = name
  io.kind = kind
  io.signal = signal

proc newIo*(editor: NodeEditor, x, y: float, name: string,
            kind: IoKind, signal: IoSignal): Io =
  new(result)
  result.initIo(editor, x, y, name, kind, signal)

#--
# Node implementation
#--

method width*(node: Node): float =
  let nameWidth = sans.widthOf(node.name.i)
  var inputsWidth, outputsWidth = 0.0
  for _, inp in node.inputs:
    inputsWidth = max(inputsWidth, inp.width)
  for _, outp in node.outputs:
    outputsWidth = max(outputsWidth, outp.width)
  let ioWidth = inputsWidth + outputsWidth
  result = max(nameWidth, ioWidth) + 32
method height*(node: Node): float =
  40 + 20 * max(node.inputs.len, node.outputs.len).float

method onEvent*(node: Node, ev: UiEvent) =
  if ev.kind in {evMousePress, evMouseRelease} and ev.mouseButton == mb1:
    node.dragging =
      ev.kind == evMousePress and
      node.pointInRect(ev.mousePos, 0, 0, node.width, node.height)
    if node.dragging:
      node.editor.bringToTop(node)
  if node.dragging and ev.kind == evMouseMove:
    let delta = ev.mousePos - node.lastMousePos
    node.pos += delta

proc layOut(node: Node) =
  block:
    var y = 32.0
    for _, inp in node.inputs:
      inp.pos = vec2(0.0, y)
      y += inp.height
  block:
    var y = 32.0
    for _, outp in node.outputs:
      outp.pos = vec2(node.width - outp.width, y)
      y += outp.height

proc addInput*(node: Node, name: string, signal: IoSignal) =
  let io = node.editor.newIo(0, 0, name, ioIn, signal)
  node.inputs.add(name, io)
  node.layOut()

proc addOutput*(node: Node, name: string, signal: IoSignal) =
  let io = node.editor.newIo(0, 0, name, ioOut, signal)
  node.outputs.add(name, io)
  node.layOut()

Node.renderer(Standard, node):
  ctx.clearStencil(0)
  ctx.stencil(saReplace, 255):
    ctx.begin()
    ctx.rrect(0, 0, node.width, node.height, 4)
    ctx.draw()
  ctx.stencilTest = (scEq, 255)

  ctx.begin()
  ctx.color = theme.nodeHeader
  ctx.rect(0, 0, node.width, 24)
  ctx.color = theme.nodeBackground
  ctx.rect(0, 24, node.width, node.height - 24)
  ctx.draw()
  ctx.color = theme.nodeHeaderText
  ctx.text(sans, 0, -2, node.name.i,
           node.width, 24, hAlign = taCenter, vAlign = taMiddle)

  ctx.color = gray(255)
  ctx.noStencilTest()

  for _, inp in node.inputs:
    inp.draw(ctx, step)
  for _, outp in node.outputs:
    outp.draw(ctx, step)

proc initNode*(node: Node, editor: NodeEditor,  x, y: float, name: string) =
  node.initControl(x, y, NodeStandard)
  node.editor = editor
  node.name = name

proc newNode*(editor: NodeEditor, x, y: float, name: string): Node =
  new(result)
  result.initNode(editor, x, y, name)

#--
# Node editor implementation
#--

proc transform*(editor: NodeEditor, point: Vec2[float]): Vec2[float] =
  result = point - editor.scroll

method onEvent*(editor: NodeEditor, ev: UiEvent) =
  block:
    var ev =
      case ev.kind
      of evMousePress:
        mousePressEvent(ev.mouseButton, editor.transform(ev.mousePos),
                        ev.modKeys)
      of evMouseRelease:
        mouseReleaseEvent(ev.mouseButton, editor.transform(ev.mousePos),
                          ev.modKeys)
      of evMouseMove:
        mouseMoveEvent(editor.transform(ev.mousePos))
      else: ev
    for i in countdown(editor.children.len - 1, 0):
      editor.children[i].event(ev)
      if ev.consumed: return
  if ev.kind in {evMousePress, evMouseRelease} and ev.mouseButton == mb3:
    editor.scrolling = ev.kind == evMousePress
    ev.consume()
  if editor.scrolling and ev.kind == evMouseMove:
    let delta = ev.mousePos - editor.lastMousePos
    editor.scroll += delta

NodeEditor.renderer(Transform, editor):
  ctx.transform:
    ctx.translate(editor.scroll.x, editor.scroll.y)
    ctx.scale(editor.zoom, editor.zoom)
    ctx.begin()
    ctx.draw(prPoints)
    for node in editor.children:
      node.draw(ctx, step)

proc initNodeEditor*(editor: NodeEditor, vw: View) =
  editor.initBox(0, 0, NodeEditorTransform)
  editor.scroll = vec2(vw.width / 2, vw.height / 2)
  editor.zoom = 1

proc newNodeEditor*(vw: View): NodeEditor =
  new(result)
  result.initNodeEditor(vw)
