import rapid/gfx
import rapid/gfx/text
import rdgui/event
import rdgui/textbox

import renderers

type
  CommandBox* = ref object of TextBox

method onEvent*(cb: CommandBox, ev: UiEvent) =
  procCall cb.TextBox.onEvent(ev)
  if not ev.consumed:
    if ev.kind == evKeyPress and ev.key == keyEscape:
      cb.focused = false
      cb.visible = false
      cb.text = ""
      ev.consume()

proc initCommandBox*(cb: CommandBox, x, y, width, height: float, font: RFont,
                     placeholder, text = "", fontSize = 14, prev: TextBox = nil,
                     rend = TextBoxCommand) =
  cb.initTextBox(x, y, width, height, font, placeholder, text, fontSize, prev,
                 rend)

proc newCommandBox*(x, y, width, height: float, font: RFont,
                    placeholder, text = "", fontSize = 14, prev: TextBox = nil,
                    rend = TextBoxCommand): CommandBox =
  new(result)
  result.initCommandBox(x, y, width, height, font, placeholder, text, fontSize,
                        prev, rend)
