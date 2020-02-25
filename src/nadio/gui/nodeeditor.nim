## This module implements a node editor.
## Nadio doesn't use nodes for producing audio directly, they're only an
## intermediate representation used in the GUI.

import math
import options
import strutils
import tables

import rapid/gfx
import rapid/gfx/text
import rapid/world/aabb
import rdgui/control
import rdgui/event

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
    polyphonic*: bool
    index*: int
    connecting: bool
  Io* = ref IoObj
  Node* = ref object of Control
    editor: NodeEditor
    fWidth, fHeight: float
    name*: string
    inputs*, outputs*: OrderedTable[string, Io]
  NodeEditor* = ref object of Box
    scroll: Vec2[float]
    zoom: float
    selected: seq[Node]
    selectionBox: RAABounds
    scrolling, selecting, dragging: bool

#--
# Prototypes
#--

proc mousePos(node: Node): Vec2[float]
proc transform*(editor: NodeEditor, point: Vec2[float]): Vec2[float]

#--
# I/O implementation
#--

proc `$`(io: Io, root = true): string =
  result = $io.kind & "[" & $io.signal & "]"
  case io.kind
  of ioIn:
    if io.inConnection != nil:
      result.add(": (" & `$`(io.inConnection, root = false) & ")")
  of ioOut:
    result.add(": [")
    var i = 0
    for _, other in io.outConnections:
      if not root:
        result.add(cast[BiggestInt](other).toHex(sizeof(pointer)))
      else:
        result.add(`$`(other, root = false))
      if i != io.outConnections.len - 1:
        result.add(", ")
      inc(i)
    result.add("]")

method width*(io: Io): float = 12 + sans.widthOf(io.name.i)
method height*(io: Io): float = 20

proc connectedTo*(io, other: Io): bool =
  case io.kind
  of ioOut:
    result = other in io.outConnections
  of ioIn:
    result = io.inConnection == other

proc hasConnection*(io: Io): bool =
  case io.kind
  of ioOut:
    result = io.outConnections.len > 0
  of ioIn:
    result = io.inConnection != nil

proc connect*(io, other: Io) =
  case io.kind
  of ioOut:
    assert other.kind == ioIn
    io.outConnections.add(other)
    other.inConnection = io
  of ioIn:
    assert other.kind == ioOut
    io.inConnection = other
    other.outConnections.add(io)

proc disconnect*(io, other: Io) =
  case io.kind
  of ioOut:
    assert other.kind == ioIn
    let index = io.outConnections.find(other)
    assert index != -1, "`other` must be connected to `io`"
    io.outConnections.del(index)
  of ioIn:
    assert other.kind == ioOut
    io.inConnection = nil
    other.disconnect(io)

proc terminal(io: Io): Vec2[float] =
  ## Returns the position of the Io's terminal.
  result =
    case io.kind
    of ioIn: vec2(0.0, io.height / 2)
    of ioOut: vec2(io.width, io.height / 2)

proc hasMouse(io: Io, threshold = 6.0): bool =
  let delta = io.node.mousePos - io.pos - io.terminal
  result = dot(delta, delta) <= threshold * threshold

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
        if other.hasMouse(threshold = 12):
          return some(other)

proc snappedMousePos(io: Io): Vec2[float] =
  let selected = io.selectedIo
  if selected.isSome:
    result = selected.get.screenPos - io.screenPos + selected.get.terminal
  else:
    result = io.node.mousePos - io.pos

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
    elif ev.kind == evMousePress:
      if io.hasMouse:
        if io.kind == ioIn and io.hasConnection:
          let other = io.inConnection
          io.disconnect(other)
          other.connecting = true
          ev.consume()
        else:
          io.connecting = ev.kind == evMousePress
          if io.connecting:
            ev.consume()
  elif io.connecting and ev.kind == evMouseMove:
    ev.consume()

Io.renderer(Standard, io):
  let
    oldLineWidth = ctx.lineWidth
    terminal = io.terminal

  ctx.color = theme.nodeIoText
  if io.kind == ioIn:
    ctx.text(sans, 12, -2, app.getString(io.name),
             h = io.height, vAlign = taMiddle,
             textureScaling = io.editor.zoom)
  elif io.kind == ioOut:
    ctx.text(sans, io.width - 12, -2, app.getString(io.name),
             h = io.height, hAlign = taRight, vAlign = taMiddle,
             textureScaling = io.editor.zoom)

  if io.kind == ioOut:
    ctx.begin()
    ctx.color = theme.ioSignals[io.signal]
    for _, inp in io.outConnections:
      let b = inp.screenPos - io.screenPos + inp.terminal
      ctx.wireCurve(terminal, b)
    ctx.lineWidth =
      if io.polyphonic: 4
      else: 2
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
  io.index =
    case io.kind
    of ioIn: node.inputs.len
    of ioOut: node.outputs.len

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

proc mousePos(node: Node): Vec2[float] =
  node.editor.transform(node.editor.mousePos) - node.pos

proc hasMouse*(node: Node): bool =
  let mouse = node.mousePos
  mouse.x in 0.0..node.width and mouse.y in 0.0..node.height

method onEvent*(node: Node, ev: UiEvent) =
  for _, inp in node.inputs:
    inp.event(ev)
    if ev.consumed: return
  for _, outp in node.outputs:
    outp.event(ev)
    if ev.consumed: return

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
           node.width, 24, hAlign = taCenter, vAlign = taMiddle,
           textureScaling = node.editor.zoom)

  ctx.color = gray(255)
  ctx.noStencilTest()

  if node in node.editor.selected:
    ctx.begin()
    ctx.color = theme.nodeSelected
    ctx.lrrect(0, 0, node.width, node.height, 4)
    ctx.draw(prLineShape)

  for _, inp in node.inputs:
    inp.draw(ctx, step)
  for _, outp in node.outputs:
    outp.draw(ctx, step)

proc initNode*(node: Node, editor: NodeEditor, x, y: float, name: string) =
  node.initControl(x, y, NodeStandard)
  node.editor = editor
  node.name = name

proc newNode*(editor: NodeEditor, x, y: float, name: string): Node =
  new(result)
  result.initNode(editor, x, y, name)

#--
# Node editor implementation
#--

method width*(editor: NodeEditor): float = editor.parent.width
method height*(editor: NodeEditor): float = editor.parent.height

proc transform*(editor: NodeEditor, point: Vec2[float]): Vec2[float] =
  (point - vec2(editor.width / 2, editor.height / 2)) / editor.zoom -
  editor.scroll

proc nodeDrag(editor: NodeEditor, node: Node, ev: UiEvent) =
  if ev.kind == evMousePress and ev.mouseButton == mb1:
    if node.hasMouse:
      if mkCtrl in ev.modKeys:
        let index = editor.selected.find(node)
        if index != -1:
          editor.selected.del(index)
        else:
          editor.selected.add(node)
      elif node notin editor.selected:
        editor.selected = @[node]
      ev.consume()
      editor.dragging = true

proc updateSelection(editor: NodeEditor) =
  let
    top = min(editor.selectionBox.top, editor.selectionBox.bottom)
    bottom = max(editor.selectionBox.top, editor.selectionBox.bottom)
    left = min(editor.selectionBox.left, editor.selectionBox.right)
    right = max(editor.selectionBox.left, editor.selectionBox.right)
    selBox = newRAABB(left, top, right - left, bottom - top)
  editor.selected.setLen(0)
  for node in editor.children:
    let aabb = newRAABB(node.pos.x, node.pos.y, node.width, node.height)
    if aabb.intersects(selBox):
      editor.selected.add(node.Node)

method onEvent*(editor: NodeEditor, ev: UiEvent) =
  block:
    var ev =
      case ev.kind
      of evMousePress:
        mousePressEvent(ev.mouseButton, editor.transform(editor.mousePos),
                        ev.modKeys)
      of evMouseRelease:
        mouseReleaseEvent(ev.mouseButton, editor.transform(editor.mousePos),
                          ev.modKeys)
      of evMouseMove:
        mouseMoveEvent(editor.transform(ev.mousePos))
      else: ev
    for i in countdown(editor.children.len - 1, 0):
      let node = editor.children[i].Node
      node.event(ev)
      if not ev.consumed:
        editor.nodeDrag(node, ev)
      if ev.consumed: return

  if ev.kind == evMousePress and ev.mouseButton == mb1:
    let mouse = editor.transform(editor.mousePos)
    editor.selecting = true
    editor.selectionBox = newRAABB(mouse.x, mouse.y, 0, 0)
    editor.updateSelection()
  elif ev.kind == evMouseRelease and ev.mouseButton == mb1:
    editor.selecting = false
    editor.dragging = false
  elif ev.kind == evMouseMove:
    if editor.dragging:
      for node in editor.selected:
        let delta = ev.mousePos - editor.lastMousePos
        node.pos += delta / editor.zoom
      ev.consume()
    elif editor.selecting:
      let mouse = editor.transform(editor.mousePos)
      editor.selectionBox.width = mouse.x - editor.selectionBox.x
      editor.selectionBox.height = mouse.y - editor.selectionBox.y
      editor.updateSelection()

  if ev.kind in {evMousePress, evMouseRelease} and ev.mouseButton == mb3:
    editor.scrolling = ev.kind == evMousePress
    ev.consume()
  if editor.scrolling and ev.kind == evMouseMove:
    let delta = ev.mousePos - editor.lastMousePos
    editor.scroll += delta / editor.zoom
  if ev.kind == evMouseScroll:
    editor.zoom += ev.scrollPos.y * 0.25
    editor.zoom = clamp(editor.zoom, 0.25, 4.0)
    editor.scroll = round(editor.scroll)
    for node in editor.children:
      node.pos = round(node.pos)
    ev.consume()

NodeEditor.renderer(Transform, editor):
  ctx.transform:
    ctx.translate(round(editor.width / 2), round(editor.height / 2))
    ctx.scale(editor.zoom, editor.zoom)
    ctx.translate(editor.scroll.x, editor.scroll.y)
    for node in editor.children:
      node.draw(ctx, step)
    if editor.selecting:
      ctx.begin()
      ctx.color = theme.nodeEditorSelection
      ctx.lrect(editor.selectionBox.x, editor.selectionBox.y,
                editor.selectionBox.width, editor.selectionBox.height)
      ctx.color = gray(255)
      ctx.draw(prLineShape)

proc initNodeEditor*(editor: NodeEditor, vw: View) =
  editor.initBox(0, 0, NodeEditorTransform)
  editor.zoom = 1

proc newNodeEditor*(vw: View): NodeEditor =
  new(result)
  result.initNodeEditor(vw)
