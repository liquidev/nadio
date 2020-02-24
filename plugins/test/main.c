#include <stdlib.h>
#include <stdio.h>

#include <nadio.h>

NadioPluginMetadata("test plugin", "iLiquid", "0.1.0")

void nadPluginInit(Nadio *n) {
  char *lang_name = NULL;

  nadGetString(n, "Language.name", &lang_name);
  printf("[test plugin] Selected language: %s\n", lang_name);
  free(lang_name);
}
