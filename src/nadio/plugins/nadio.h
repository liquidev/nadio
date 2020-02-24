/* Nadio C API
 *
 * This file contains declarations for the Nadio C API. It's usually preferrable
 * to use the Nim API, but a C API exists for people that like to play with
 * fire (or prefer using a simpler language).
 *
 * Use with care.
 */

/**
 * Nadio state. You get this in Nadio's plugin callbacks.
 */
typedef struct Nadio Nadio;

/**
 * Shortcut macro that defines the plugin's metadata.
 */
#define NadioPluginMetadata(name, author, version) \
  char *nadPluginGetName(void) { return name; } \
  char *nadPluginGetAuthor(void) { return author; } \
  char *nadPluginGetVersion(void) { return version; }

/**
 * Memory management functions. You should use them when passing memory to, and
 * receiving memory from Nadio, eg. any strings you retrieve must be freed with
 * `nadDealloc`.
 */

void *nadAlloc(unsigned long size);

void *nadRealloc(void *mem, unsigned long size);

void nadDealloc(void *mem);

/**
 * Load language strings from the string `lang`, with `name` as the filename for
 * error reporting. `lang` has to be a Nim config file
 * (see nim-lang.org/docs/parsecfg.html for syntax reference).
 */
void nadLoadStrings(Nadio *app, char *name, char *lang);

/**
 * Retrieve a string from the global language table into `dest`. A new string is
 * allocated and stored in `dest`, and it must later be freed with `nadDealloc`.
 */
char *nadGetString(Nadio *app, char *key, char **dest);
