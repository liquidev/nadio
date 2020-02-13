import rapid/gfx
import rapid/gfx/text
import rdgui/control
import rdgui/textbox

TextBox.renderer(Command, tb):
  let oldFontHeight = tb.font.height
  tb.font.height = tb.fontSize

  ctx.color = gray(255)
  ctx.text(tb.font, -tb.font.widthOf(":"), tb.height / 2 - 2, ":",
           vAlign = taMiddle)
  tb.drawEditor(ctx)

  tb.font.height = oldFontHeight
