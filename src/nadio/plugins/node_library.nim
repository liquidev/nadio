import tables

import ../gui/nodeeditor

type
  NodeCategory* = enum
    ncGen = "NodeCategory.gen"
    ncEffect = "NodeCategory.effect"
    ncLadspa = "NodeCategory.ladspa"
    ncMisc = "NodeCategory.misc"
  NodeConstructor* = proc (node: Node)
  NodeSpec* = object
    name*: string
    categories*: set[NodeCategory]
    createNode*: NodeConstructor

  NodeLibrary* = Table[string, NodeSpec]

proc defineNode*(name: string, categories: set[NodeCategory],
                 createProc: NodeConstructor): NodeSpec =
  result = NodeSpec(name: name, categories: categories,
                    createNode: createProc)
