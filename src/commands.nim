import options
import tables

import npeg

type
  Command = object
    name: string
    args: seq[string]
  CommandImpl* = proc (args: seq[string]): Option[string] ## \
    ## should return the empty string on success, or an error message

var
  commands*: Table[string, proc (args: seq[string]): string]

let commandParser = peg(command, c: Command):
  ws <- *' '
  ident <- +{'a'..'z', 'A'..'Z', '-'}
  int <- >+Digit:
    c.args.add($1)
  string <- >+(1 - ws) | '"' * >+(1 - '"') * '"':
    c.args.add($1)
  expr <- int | string
  command <- >ident * ws * *(expr * ws):
    c.name = $1

proc parseCommand(cmd: string): Option[Command] =
  var c: Command
  let matchResult = commandParser.match(cmd, c)
  if matchResult.ok:
    result = some(c)

proc runCommand*(cmd: string): string =
  let cmd = parseCommand(cmd)
  if cmd.isNone:
    return "(command) syntax error"
  let impl = commands[cmd.get.name]
  result = impl(cmd.get.args)
