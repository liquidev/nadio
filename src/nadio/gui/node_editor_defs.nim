import tables

import glm/vec
import rapid/world/aabb
import rdgui/control

type
  IoKind* = enum
    ioIn = "Input"
    ioOut = "Output"
  IoSignal* = enum
    ioBool = "bool"
    ioFloat = "float"
  IoObj* = object of Control
    editor*: NodeEditor
    node*: Node
    name*: string
    case kind*: IoKind
    of ioIn:
      inConnection*: Io
    of ioOut:
      outConnections*: seq[Io]
    signal*: IoSignal
    polyphonic*: bool
    index*: int
    connecting*: bool
  Io* = ref IoObj
  Node* = ref object of Control
    editor*: NodeEditor
    fWidth*, fHeight*: float
    name*: string
    inputs*, outputs*: OrderedTable[string, Io]
  NodeEditor* = ref object of Box
    scroll*: Vec2[float]
    zoom*: float
    selected*: seq[Node]
    selectionBox*: RAABounds
    scrolling*, selecting*, dragging*: bool
