import rapid/gfx

type
  Theme* = object
    bg*: RColor
    barFill*, barLine*: RColor

const
  ThemeDefault* = Theme(
    bg:      gray(16),
    barFill: gray(24),
    barLine: gray(48),
  )
