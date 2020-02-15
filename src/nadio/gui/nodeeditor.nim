## This module implements a node editor.
## Nadio doesn't use nodes for producing audio directly, they're only an
## intermediate representation used in the GUI.

import tables

import rapid/gfx
import rapid/gfx/text
import rdgui/control

import ../i18n
import ../res
import nodeeditor_defs # IoKind, IoSignal

export nodeeditor_defs

type
  Io* = ref object of Control
    editor: NodeEditor
    name*: string
    kind*: IoKind
    signal*: IoSignal
  Node* = ref object of Control
    fWidth, fHeight: float
    name*: string
    inputs*, outputs*: OrderedTable[string, Io]
  NodeEditor* = ref object of Box

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

proc initIo*(io: Io, x, y: float, name: string,
             kind: IoKind, signal: IoSignal) =
  io.initControl(x, y, IoStandard)
  io.name = name
  io.kind = kind
  io.signal = signal

proc newIo*(x, y: float, name: string, kind: IoKind, signal: IoSignal): Io =
  new(result)
  result.initIo(x, y, name, kind, signal)

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
  let io = newIo(0, 0, name, ioIn, signal)
  node.inputs.add(name, io)
  node.layOut()

proc addOutput*(node: Node, name: string, signal: IoSignal) =
  let io = newIo(0, 0, name, ioOut, signal)
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

proc initNode*(node: Node, x, y: float, name: string) =
  node.initControl(x, y, NodeStandard)
  node.name = name

proc newNode*(x, y: float, name: string): Node =
  new(result)
  result.initNode(x, y, name)
