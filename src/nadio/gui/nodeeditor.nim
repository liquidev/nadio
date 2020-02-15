## This module implements a node editor.
## Nadio doesn't use nodes for producing audio directly, they're only an
## intermediate representation used in the GUI.

import math
import options
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
  IoObj* = object of Control
    editor: NodeEditor
    node: Node
    name*: string
    case kind*: IoKind
    of ioIn:
      inConnection*: Io
    of ioOut:
      outConnections*: seq[Io]
    signal*: IoSignal
    connecting: bool
  Io* = ref IoObj
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
# Prototypes
#--

proc transform*(editor: NodeEditor, point: Vec2[float]): Vec2[float]

#--
# I/O implementation
#--

method width*(io: Io): float = 12 + sans.widthOf(io.name.i)
method height*(io: Io): float = 20

proc connectedTo*(io, other: Io): bool =
  case io.kind
  of ioOut:
    result = other in io.outConnections
  of ioIn:
    result = io.inConnection == other

proc connect*(io, other: Io) =
  case io.kind
  of ioOut:
    assert other.kind == ioIn
    io.outConnections.add(other)
    other.connect(io)
  of ioIn:
    assert other.kind == ioOut
    io.inConnection = other

proc terminal(io: Io): Vec2[float] =
  ## Returns the position of the Io's terminal.
  result =
    case io.kind
    of ioIn: vec2(0.0, io.height / 2)
    of ioOut: vec2(io.width, io.height / 2)

proc selectedIo(io: Io): Option[Io] =
  for ctrl in io.editor.children:
    if ctrl of Node and ctrl != io.node:
      let
        node = ctrl.Node
        compat =
          if io.kind == ioIn: node.outputs
          else: node.inputs
      for name, other in compat:
        if io.connectedTo(other): continue
        let
          terminal = other.terminal
          mouse = io.editor.transform(other.mousePos)
          delta = mouse - terminal
        if dot(delta, delta) <= 12.0 ^ 2:
          return some(other)

proc snappedMousePos(io: Io): Vec2[float] =
  let selected = io.selectedIo
  if selected.isSome:
    result = selected.get.screenPos - io.screenPos + selected.get.terminal
  else:
    result = io.editor.transform(io.mousePos)

proc wireCurve(ctx: RGfxContext, a, b: Vec2[float]) =
  func curve(x: float): float = (-cos(PI * x) + 1) / 2
  let
    d = b - a
    count = int(dot(d, d).sqrt / 8)
  for i in 0..<count:
    let
      t0 = i / count
      t1 = (i + 1) / count
      u = vec2(mix(a.x, b.x, t0), mix(a.y, b.y, curve(t0)))
      v = vec2(mix(a.x, b.x, t1), mix(a.y, b.y, curve(t1)))
    ctx.line((u.x, u.y), (v.x, v.y))

method onEvent*(io: Io, ev: UiEvent) =
  if ev.kind in {evMousePress, evMouseRelease} and ev.mouseButton == mb1:
    if io.connecting and ev.kind == evMouseRelease:
      let sel = io.selectedIo
      if sel.isSome:
        io.connect(sel.get)
      io.connecting = false
    else:
      let terminal = io.terminal
      io.connecting =
        ev.kind == evMousePress and
        io.pointInCircle(ev.mousePos, terminal.x, terminal.y, 6)
      if io.connecting:
        ev.consume()

Io.renderer(Standard, io):
  let
    oldLineWidth = ctx.lineWidth
    terminal = io.terminal

  ctx.color = theme.nodeIoText
  if io.kind == ioIn:
    ctx.text(sans, 12, -2, io.name.i, h = io.height, vAlign = taMiddle)
  elif io.kind == ioOut:
    ctx.text(sans, io.width - 12, -2, io.name.i,
             h = io.height, hAlign = taRight, vAlign = taMiddle)

  if io.kind == ioOut:
    ctx.begin()
    ctx.color = theme.ioSignals[io.signal]
    for _, inp in io.outConnections:
      let b = inp.screenPos - io.screenPos + inp.terminal
      ctx.wireCurve(terminal, b)
    ctx.lineWidth = 2
    ctx.draw(prLineShape)
  if io.connecting:
    ctx.begin()
    ctx.lineWidth = 1
    let b = io.snappedMousePos
    ctx.color = theme.nodeIoGhost
    ctx.wireCurve(terminal, b)
    ctx.draw(prLineShape)

  ctx.begin()
  ctx.color = theme.ioSignals[io.signal]
  ctx.circle(terminal.x, terminal.y, 4)
  ctx.draw()

  ctx.color = gray(255)
  ctx.lineWidth = oldLineWidth

proc initIo*(io: Io, node: Node, x, y: float, name: string,
             kind: IoKind, signal: IoSignal) =
  io[] = IoObj(kind: kind)
  io.initControl(x, y, IoStandard)
  io.editor = node.editor
  io.node = node
  io.name = name
  io.signal = signal

proc newIo*(node: Node, x, y: float, name: string,
            kind: IoKind, signal: IoSignal): Io =
  new(result)
  result.initIo(node, x, y, name, kind, signal)

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
  for _, inp in node.inputs:
    inp.event(ev)
    if ev.consumed: return
  for _, outp in node.outputs:
    outp.event(ev)
    if ev.consumed: return
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
  let io = node.newIo(0, 0, name, ioIn, signal)
  node.inputs.add(name, io)
  node.contain(io)
  node.layOut()

proc addOutput*(node: Node, name: string, signal: IoSignal) =
  let io = node.newIo(0, 0, name, ioOut, signal)
  node.outputs.add(name, io)
  node.contain(io)
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
