import nadio/plugins/api

proc nadioPluginGetName*: string {.cdecl, exportc, dynlib.} = "test plugin"
proc nadioPluginGetAuthor*: string {.cdecl, exportc, dynlib.} = "iLiquid"
proc nadioPluginGetVersion*: string {.cdecl, exportc, dynlib.} = "0.1.0"

proc nadioPluginInit*(res: Resources) {.cdecl, exportc, dynlib.} =
  echo "hello from plugin"
  echo "current language: ", res.getString("Language.name")
  echo "loading own strings"
  res.loadStrings("test.nim/en_US", """
    [test_plugin/Node/Passthrough]
    name = "Audio Passthrough"
    input = "Input"
    output = "Output"
  """)
  # let spec = defineNode("test_plugin/Node/Passthrough.name",
  #                       categories = {ncMisc}) do (node: Node):
  #     node.addInput("test_plugin/Node/Passthrough.input", ioFloat)
  #     node.addOutput("test_plugin/Node/Passthrough.output", ioFloat)
