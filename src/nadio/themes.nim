import rapid/gfx

import gui/node_editor_defs

export node_editor_defs

type
  Theme* = object
    # global
    bg*: RColor

    # universal controls
    ctxMenuBg*: RColor
    menuItemText*, menuItemHover*: RColor

    # bars and bar controls
    barFill*, barLine*: RColor
    viewSwitcherCurrent*, viewSwitcherHover*, viewSwitcherPress*: RColor
    commandBar*: RColor

    # node editor
    nodeEditorSelection*: RColor
    nodeHeader*, nodeBg*, nodeHeaderText*, nodeSelected*: RColor
    nodeIoText*, nodeIoGhost*: RColor
    ioSignals*: array[IoSignal, RColor]

const
  ThemeDefault* = Theme(
    bg: gray(24),

    ctxMenuBg:     gray(0, 160),
    menuItemText:  gray(255),
    menuItemHover: gray(32),

    barFill: gray(32),
    barLine: gray(48),

    viewSwitcherCurrent: gray(255, 16),
    viewSwitcherHover:   gray(255, 32),
    viewSwitcherPress:   gray(0, 32),

    commandBar: gray(255),

    nodeEditorSelection: gray(255),
    nodeHeader:          gray(48),
    nodeBg:              gray(32),
    nodeHeaderText:      gray(255),
    nodeSelected:        gray(255),
    nodeIoText:          gray(255),
    nodeIoGhost:         gray(255, 64),

    ioSignals: [
      ioBool:  hex"E2795B",
      ioFloat: hex"25A6A3",
    ],
  )
