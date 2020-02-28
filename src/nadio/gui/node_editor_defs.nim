import tables

import glm/vec
import rapid/world/aabb
import rdgui/control

type
  # nodes
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

  # editor
  NodeEditor* = ref object of Box
    scroll*: Vec2[float]
    zoom*: float
    selected*: seq[Node]
    selectionBox*: RAABounds
    scrolling*, selecting*, dragging*: bool
    library*: NodeLibrary

  # library
  NodeCategory* = enum
    ncGen = "NodeCategory.gen"
    ncEffect = "NodeCategory.effect"
    ncLadspa = "NodeCategory.ladspa"
    ncMisc = "NodeCategory.misc"
  NodeInitializer* = proc (node: Node)
  NodeSpec* = object
    name*: string
    categories*: set[NodeCategory]
    init*: NodeInitializer
  NodeLibrary* = ref object
    byName*: Table[string, NodeSpec]
    byCategory*: array[NodeCategory, seq[NodeSpec]]

proc defineNode*(name: string, categories: set[NodeCategory],
                 initImpl: NodeInitializer): NodeSpec =
  result = NodeSpec(name: name, categories: categories,
                    init: initImpl)

proc newNodeLibrary*(): NodeLibrary =
  new(result)

proc add*(lib: NodeLibrary, spec: NodeSpec) =
  lib.byName.add(spec.name, spec)
  for cat in spec.categories:
    lib.byCategory[cat].add(spec)
