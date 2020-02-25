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
    submenu*: Option[ContextMenu] # if some, this opens a submenu
    text*: string
    fHeight: float
    onClick*: proc ()
  ContextMenu* = ref object of Window
    currentSubmenu: ContextMenu

#--
# Prototypes
#--

proc openSubmenu(menu, sub: ContextMenu)

#--
# Menu item implementation
#--

method width*(item: MenuItem): float = item.parent.width
method height*(item: MenuItem): float = item.fHeight

proc `height=`*(item: MenuItem, newHeight: float) =
  item.fHeight = newHeight

MenuItem.renderer(Nadio, item):
  ctx.color = theme.menuItemText
  ctx.text(sans, 8, -2, gRes.getString(item.text),
           h = item.height, vAlign = taMiddle)
  ctx.color = gray(255)

proc initMenuItem*(item: MenuItem, text: string,
                   onClick: proc () = nil, submenu = ContextMenu.none,
                   height = 24.0, rend = MenuItemNadio) =
  item.initControl(x = 0, y = 0, rend)
  item.submenu = submenu
  item.text = text
  item.height = height
  item.onClick = onClick

  item.onContain do:
    assert item.parent of ContextMenu,
           "menu items may only be stored in context menus"

proc newMenuItem*(text: string, onClick: proc () = nil,
                  submenu = ContextMenu.none, height = 24.0,
                  rend = MenuItemNadio): MenuItem =
  new(result)
  result.initMenuItem(text, onClick, submenu, height, rend)

#--
# Context menu implementation
#--

method calculateHeight(menu: ContextMenu) =
  menu.height = 0
  for item in menu.children:
    # can't use += here because setters
    menu.height = menu.height + item.height

proc openSubmenu(menu, sub: ContextMenu) =
  if menu.currentSubmenu != nil:
    menu.currentSubmenu.close()
  menu.wm.add(sub)
  menu.currentSubmenu = sub

proc `height=`*(menu: ContextMenu)
  {.error: "a context menu's height is calculated automatically".}

proc add*(menu: ContextMenu, item: MenuItem) =
  menu.Box.add(item)
  menu.calculateHeight()
  menu.listVertical(padding = 0, spacing = 0)

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
  echo BoxChildren.isNil
  BoxChildren(ctx, step, menu)
  ctx.color = gray(255)
  ctx.draw()
  ctx.noStencilTest

proc initContextMenu*(menu: ContextMenu, wm: WindowManager, x, y, width: float,
                      rend = ContextMenuNadio) =
  menu.initWindow(wm, x, y, width, height = 0, rend)
  menu.width = width

proc newContextMenu*(wm: WindowManager, x, y, width: float,
                     rend = ContextMenuNadio): ContextMenu =
  new(result)
  result.initContextMenu(wm, x, y, width, rend)
