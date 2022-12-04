# OtomeOS 💮

An interesting, friendly computation environment for curious and playful users.

A shell / fantasy operating system inspired by functional programming written in Lua where everything is non-destructive.

**This project is a WIP**

Project inspired by: Bash, ZSH, Exapunks, Blender Geometry Nodes, Lisp/Functional Programming, TIC80.

## The Basics

```
Command Arg1 Arg2 (SubCommand Arg1 Arg2)
```

* Commands can be called to return a list
* Arguments are commands that return lists
* The result of the root is shown

## TODO

- [ ] example command to show usage of commands
- [ ] add a documentation folder with some tutorials / explainations
- [ ] add config to commands where it makes sense
- [ ] type check config
- [ ] parameter expansion
- [ ] configuration for functions
- [ ] rework file system operations
- [ ] allow documentation of user functions
- [ ] multiple return values / vararg
- [ ] example in readme
- [ ] folders and then also paths sigh.
- [ ] multiline (wait until everything is closed)
- [ ] define functions with config and parameters
- [ ] save history to disk
- [ ] LSP
- [ ] tree sitter grammar
- [ ] categories for commands
- [ ] job control (schedule tasks)
- [ ] difference between number, bool and string streams: type checking
- [ ] port this whole thing to rust | use https://github.com/osch/lua-nocurses
- [ ] autocompletion wow (need a custom text input for that)
- [ ] cache commands
- [ ] fancy frontend with autocompletion
- [ ] make it a game? Or maybe an actual shell?
- [ ] UTF8 support

## DONE

- [x] Tests
- [x] Strings
- [x] List syntactic sugar
- [x] Error handling
- [x] stream manipulation commands
- [x] execute a file or string
- [x] Parameters (config options for commands)
- [x] define functions
- [x] define functions with parameters
- [x] callables (commands as parameters)
- [x] math operators
- [x] comparison operators
- [x] Flow control: loops (with 'give'), conditions (with 'when')
- [x] Wrote something useful with this: [AOC D1](https://www.reddit.com/r/adventofcode/comments/z9ezjb/comment/iyha7bf/?context=3)
- [x] escaping in strings
- [x] closures
- [x] test every command

## Timed Commands

Commands should execute instantly. Tasks can be scheduled by the OS:

```
IN 5s write log
```

## Command Configuration

**Example:**

```
combine{sep="  ", values='all} commands (describe commands)
```

Multiple keys can be assigned to one stream:

```
render{time,color,camera=(read 'config)} (read time=10 'cube)
```

is the same as

```
render{time=10,color='red,camera='normal} (read time=10 'cube)
```

## Functions

Functions are user-defined commands. They take parameters, input streams and
generate an output stream.

**Example:**

```
function 'myjoin{sep = "  "} (join $1 sep) 
```

These should replace aliases. (DONE)

### Documenting Functions

```
function 'myjoin{sep = "  "} (join $1 sep) 
describe 'myjoin "Join strings by separator\nNOTE: this is pretty useless"
args 'myjoin ["separator"]
example 'myjoin "A longer example: myjoin{sep=}"
```

## Passing Functions to Functions

Functions can take other functions as parameters and call them:

```
function about (combine $1 (resize ": " 100) (!2 $1))
about functions !describe
```

## Executing Scripts

Scripts can be run with the `run` command. The are executed in a virtual
environment which is only applied when the script is successfull.
The `undo` command undos the last run command by default.

## Parameter Expansion

```
range {[1 4]}
```

will execute

```
range 1 4
```

## Configurating Custom Functions

Custom functions can also use configurations:

```
function show{color="none"} join $color
```

## Closures

```
give [5 2 3] !($1 give $2 !(join [$1 $1]))
```

## The Name

Otome because I like the Otometsubaki flower. Any other meanings are accidental, but welcome.

## Development

Check the source code:

```bash
luacheck *.lua --exclude-files inspect.lua``
```
