import nadio/plugins/api

proc nadioPluginGetName*: string {.noconv, exportc, dynlib.} = "test plugin"
proc nadioPluginGetAuthor*: string {.noconv, exportc, dynlib.} = "iLiquid"
proc nadioPluginGetVersion*: string {.noconv, exportc, dynlib.} = "0.1.0"

proc nadioPluginInit*(app: var State) {.noconv, exportc, dynlib.} =
  echo "hello from plugin"
  echo "current language: ", app.getString("Language.name")
  echo "loading own strings"
  app.loadStrings("test.nim/en_US", """
    [test_plugin/Node/Passthrough]
    name = "Audio Passthrough"
    input = "Input"
    output = "Output"
  """)
  let spec = defineNode("test_plugin/Node/Passthrough.name",
                        categories = {ncMisc}) do (node: Node):
      node.addInput("test_plugin/Node/Passthrough.input", ioFloat)
      node.addOutput("test_plugin/Node/Passthrough.output", ioFloat)
