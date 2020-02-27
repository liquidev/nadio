import options

import rapid/gfx
import rapid/gfx/text
import rdgui/control
import rdgui/event
import rdgui/layout
import rdgui/windows

import ../res

type
  MenuItem* = ref object of Control
    menu*: ContextMenu
    submenu*: ContextMenu # if not nil, the item opens a submenu
    text*: string
    fHeight: float
    onClick*: proc ()
  ContextMenu* = ref object of Window
    parentMenu, currentSubmenu: ContextMenu

#--
# Prototypes
#--

proc close(menu: ContextMenu)
proc closeAll(menu: ContextMenu)
proc setSubmenu(menu, sub: ContextMenu)

#--
# Menu item implementation
#--

method width*(item: MenuItem): float = item.menu.width
method height*(item: MenuItem): float = item.fHeight

proc `height=`*(item: MenuItem, newHeight: float) =
  item.fHeight = newHeight

proc textWidth(item: MenuItem): float =
  8 + sans.widthOf(gRes.getString(item.text)) + 8

proc hasMouse(item: MenuItem): bool =
  item.mouseInRect(0, 0, item.menu.width, item.height)

method onEvent*(item: MenuItem, ev: UiEvent) =
  if ev.kind == evMouseRelease and ev.mouseButton == mb1 and item.hasMouse:
    if item.onClick != nil:
      item.onClick()
      ev.consume()
      item.menu.closeAll()
  elif ev.kind == evMouseEnter:
    if item.submenu != nil:
      let pos = item.screenPos
      item.submenu.pos = pos + vec2(item.menu.width, 0)
    item.menu.setSubmenu(item.submenu)

MenuItem.renderer(Nadio, item):
  if item.hasMouse:
    ctx.color = theme.menuItemHover
    ctx.begin()
    ctx.rect(0, 0, item.menu.width, item.height)
    ctx.draw()
  ctx.color = theme.menuItemText
  ctx.text(sans, 8, -2, gRes.getString(item.text),
           h = item.height, vAlign = taMiddle)
  if item.submenu != nil:
    ctx.transform:
      ctx.translate(item.menu.width - 8, item.height / 2)
      ctx.begin()
      ctx.tri((0.0, 0.0), (-4.0, -4.0), (-4.0, 4.0))
      ctx.draw()
  ctx.color = gray(255)

proc initMenuItem*(item: MenuItem, menu: ContextMenu, text: string,
                   onClick: proc () = nil, submenu: ContextMenu = nil,
                   height = 24.0, rend = MenuItemNadio) =
  item.initControl(x = 0, y = 0, rend)
  item.menu = menu
  item.submenu = submenu
  item.text = text
  item.height = height
  item.onClick = onClick

proc newMenuItem*(menu: ContextMenu, text: string, onClick: proc () = nil,
                  submenu: ContextMenu = nil, height = 24.0,
                  rend = MenuItemNadio): MenuItem =
  new(result)
  result.initMenuItem(menu, text, onClick, submenu, height, rend)

#--
# Context menu implementation
#--

proc calculateDimensions(menu: ContextMenu) =
  menu.width = 0
  for item in menu.children:
    menu.width = max(menu.width,
                     if item of MenuItem: item.MenuItem.textWidth
                     else: item.width)
  menu.width = menu.width + 32
  menu.height = 0
  for item in menu.children:
    # can't use += here because setters
    menu.height = menu.height + item.height

proc `width=`*(menu: ContextMenu)
  {.error: "a context menu's width is calculated automatically".}

proc `height=`*(menu: ContextMenu)
  {.error: "a context menu's height is calculated automatically".}

proc setSubmenu(menu, sub: ContextMenu) =
  if menu.currentSubmenu != nil:
    menu.currentSubmenu.close()
  menu.currentSubmenu = sub
  if sub != nil:
    sub.parentMenu = menu
    menu.wm.add(sub)

proc close(menu: ContextMenu) =
  if menu.currentSubmenu != nil:
    menu.currentSubmenu.close()
  menu.Window.close()

proc closeAll(menu: ContextMenu) =
  if menu.parentMenu != nil:
    menu.parentMenu.closeAll()
  else:
    menu.close()

proc hasMouse(menu: ContextMenu): bool =
  result = menu.mouseInRect(0, 0, menu.width, menu.height)
  if not result and menu.currentSubmenu != nil:
    result = result or menu.currentSubmenu.hasMouse

method onEvent*(menu: ContextMenu, ev: UiEvent) =
  procCall menu.Window.onEvent(ev)
  if ev.consumed: return

  if ev.kind == evMousePress:
    if menu.hasMouse:
      ev.consume()
    else:
      menu.close()

ContextMenu.renderer(Nadio, menu):
  ctx.clearStencil(0)
  ctx.stencil(saReplace, 255):
    ctx.begin()
    ctx.rrect(0, 0, menu.width, menu.height, 4)
    ctx.draw()
  ctx.stencilTest = (scEq, 255)
  ctx.begin()
  ctx.color = theme.ctxMenuBg
  ctx.rect(0, 0, menu.width, menu.height)
  ctx.color = gray(255)
  ctx.draw()
  BoxChildren(ctx, step, menu)
  ctx.noStencilTest

proc add*(menu: ContextMenu, item: MenuItem) =
  menu.children.add(item)
  menu.contain(item)
  menu.listVertical(padding = 0, spacing = 0)
  menu.calculateDimensions()

proc initContextMenu*(menu: ContextMenu, wm: WindowManager, x, y = 0.0,
                      rend = ContextMenuNadio) =
  menu.initWindow(wm, x, y, 0, height = 0, rend)

proc newContextMenu*(wm: WindowManager, x, y = 0.0,
                     rend = ContextMenuNadio): ContextMenu =
  new(result)
  result.initContextMenu(wm, x, y, rend)
