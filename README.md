# OtomeOS 💮

An interesting, friendly computation environment for curious and playful users.

A shell / fantasy operating system inspired by functional programming written in Lua where everything is non-destructive.

**This project is a WIP**

Project inspired by: Bash, ZSH, Exapunks, Blender Geometry Nodes, Lisp/Functional Programming, TIC8.

## The Basics

```
Command Arg1 Arg2 (SubCommand Arg1 Arg2)
```

* Commands can be called to return a list
* Arguments are commands that return lists
* The result of the root is shown
* Commands have no side effects
* Output of commands is sent to system, which has a separate command syntax

## TODO

example command to show usage of commands
add config to commands where it makes sense
type check config
parameter expansion
virtual execution of scripts (remove confirm)
allow documentation of user functions
multiple return values / vararg
folders and then also paths sigh.
multiline (wait until everything is closed)
define functions with config and parameters
save history to disk
pass functions to functions
escaping in strings
LSP
tree sitter grammar
categories for commands
job control (schedule tasks)
refactor this mess. maybe add type hints and comments?
difference between number, bool and string streams: type checking
port this whole thing to rust | use https://github.com/osch/lua-nocurses
autocompletion wow (need a custom text input for that)
cache commands
write something usefull with this
fancy frontend with autocompletion
make it a game? Or maybe an actual shell?
UTF8 support

## DONE

Tests
Strings
List sugar
Aliases (removed in favor of functions)
Error handling
stream manipulation commands
execute a file or string
Parameters (config options for commands)
define functions
define functions with parameters
remove aliases in favor of functions
callables (commands as parameters)
confirm in scripts (replaced by immediate execution)
math operators
comparison operators
Flow control: loops (with 'give'), conditions (with 'when')
commands have no side effects

Commands should execute instantly. Tasks can be scheduled by the OS:

```
IN 5s write log
```

## Command Parameters

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
describe 'myjoin "Join strings by separator\n\nA longer example: myjoin{sep=}\n\n\nNOTE: this is pretty useless"
args 'myjoin ["separator"]
```

## Passing Functions to Functions

Functions can take other functions as parameters and call them:

```
function about (combine $1 (resize ": " 100) ($2 $1))
about functions :describe
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
