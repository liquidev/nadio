import rapid/gfx
import rapid/gfx/text
import rdgui/control
import rdgui/textbox

import ../res

TextBox.renderer(Command, tb):
  let oldFontHeight = tb.font.height
  tb.font.height = tb.fontSize

  ctx.color = theme.commandBar
  ctx.text(tb.font, -tb.font.widthOf(":"), tb.height / 2 - 2, ":",
           vAlign = taMiddle)
  tb.drawEditor(ctx)
  ctx.color = gray(255)

  tb.font.height = oldFontHeight
