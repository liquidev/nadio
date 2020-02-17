import rapid/gfx

import gui/nodeeditor_defs

export nodeeditor_defs

type
  Theme* = object
    bg*: RColor
    barFill*, barLine*: RColor
    viewSwitcherCurrent*, viewSwitcherHover*, viewSwitcherPress*: RColor
    commandBar*: RColor
    nodeEditorSelection*: RColor
    nodeHeader*, nodeBackground*, nodeHeaderText*, nodeSelected*: RColor
    nodeIoText*, nodeIoGhost*: RColor
    ioSignals*: array[IoSignal, RColor]

const
  ThemeDefault* = Theme(
    bg: gray(24),

    barFill: gray(32),
    barLine: gray(48),

    viewSwitcherCurrent: gray(255, 16),
    viewSwitcherHover:   gray(255, 32),
    viewSwitcherPress:   gray(0, 32),

    commandBar: gray(255),

    nodeEditorSelection: gray(255),
    nodeHeader:          gray(48),
    nodeBackground:      gray(32),
    nodeHeaderText:      gray(255),
    nodeSelected:        gray(255),
    nodeIoText:          gray(255),
    nodeIoGhost:         gray(255, 64),

    ioSignals: [
      ioBool:  hex"E2795B",
      ioFloat: hex"25A6A3",
    ],
  )
