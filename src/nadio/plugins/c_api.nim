import ../i18n
import ../res

#--
# Memory management
#--

proc nadAlloc*(size: culong): pointer {.exportc.} =
  result = alloc(size.Natural)

proc nadRealloc*(mem: pointer, size: culong): pointer {.exportc.} =
  result = realloc(mem, size.Natural)

proc nadDealloc*(mem: pointer) {.exportc.} =
  dealloc(mem)

#--
# i18n
#--

proc nadLoadStrings*(app: ptr State, name, lang: cstring) {.exportc.} =
  cast[var State](app).loadStrings($name, $lang)

proc nadGetString*(app: ptr State, key: cstring,
                   dest: ptr cstring) {.exportc.} =
  let str = cast[var State](app).getString($key)
  dest[] = cast[cstring](alloc0(str.len + 1))
  copyMem(dest[], str[0].unsafeAddr, str.len)
