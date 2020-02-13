import rapid/gfx

type
  Theme* = object
    bg*: RColor
    barFill*, barLine*: RColor
    viewSwitcherCurrent*, viewSwitcherHover*, viewSwitcherPress*: RColor

const
  ThemeDefault* = Theme(
    bg: gray(16),

    barFill: gray(24),
    barLine: gray(48),

    viewSwitcherCurrent: gray(255, 16),
    viewSwitcherHover:   gray(255, 32),
    viewSwitcherPress:   gray(0, 32),
  )
