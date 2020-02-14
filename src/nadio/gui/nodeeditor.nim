## This module implements a node editor.
## Nadio doesn't use nodes for producing audio directly, they're only an
## intermediate representation used in the GUI.

import rapid/gfx
import rapid/gfx/text
import rdgui/control

import ../res
import nodeeditor_defs # IoKind, IoSignal

type
  Io* = ref object of Control
    editor: NodeEditor
    name*: string
    kind*: IoKind
    signal*: IoSignal
  Node* = ref object of Control
    fWidth, fHeight: float
    name*: string
    inputs*, outputs*: seq[Io]
  NodeEditor* = ref object of Box

#--
# I/O implementation
#--

method width*(io: Io): float = 12 + sans.widthOf(io.name)
method height*(io: Io): float = 16

Io.renderer(Standard, io):
  ctx.begin()
  ctx.color = theme.ioSignals[io.signal]
  ctx.circle(x = 2, io.height / 2 + 2, r = 2)
  ctx.draw()

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
  let nameWidth = sans.widthOf(node.name)
  var inputsWidth, outputsWidth = 0.0
  for inp in node.inputs:
    inputsWidth = max(inputsWidth, inp.width)
  for outp in node.outputs:
    outputsWidth = max(outputsWidth, outp.width)
  let ioWidth = inputsWidth + outputsWidth + 16
  result = max(nameWidth, ioWidth) + 32
method height*(node: Node): float =
  24 + 16 * max(node.inputs.len, node.outputs.len).float

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
  ctx.text(sans, 0, -2, node.name,
           node.width, 24, hAlign = taCenter, vAlign = taMiddle)

  ctx.color = gray(255)
  ctx.noStencilTest()

proc initNode*(node: Node, x, y: float, name: string) =
  node.initControl(x, y, NodeStandard)
  node.name = name

proc newNode*(x, y: float, name: string): Node =
  new(result)
  result.initNode(x, y, name)
