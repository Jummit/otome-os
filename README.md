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
* Commands have no side effects
* Output of commands is sent to system, which has a separate command syntax

## TODO

- [ ] example command to show usage of commands
- [ ] add config to commands where it makes sense
- [ ] type check config
- [ ] parameter expansion
- [ ] virtual execution of scripts (remove confirm)
- [ ] allow documentation of user functions
- [ ] multiple return values / vararg
- [ ] folders and then also paths sigh.
- [ ] multiline (wait until everything is closed)
- [ ] define functions with config and parameters
- [ ] save history to disk
- [ ] pass functions to functions
- [ ] escaping in strings
- [ ] LSP
- [ ] tree sitter grammar
- [ ] categories for commands
- [ ] job control (schedule tasks)
- [ ] refactor this mess. maybe add type hints and comments?
- [ ] difference between number, bool and string streams: type checking
- [ ] port this whole thing to rust | use https://github.com/osch/lua-nocurses
- [ ] autocompletion wow (need a custom text input for that)
- [ ] cache commands
- [ ] write something usefull with this
- [ ] fancy frontend with autocompletion
- [ ] make it a game? Or maybe an actual shell?
- [ ] UTF8 support

## DONE

- [x] Tests
- [x] Strings
- [x] List sugar
- [x] Aliases (removed in favor of functions)
- [x] Error handling
- [x] stream manipulation commands
- [x] execute a file or string
- [x] Parameters (config options for commands)
- [x] define functions
- [x] define functions with parameters
- [x] remove aliases in favor of functions
- [x] callables (commands as parameters)
- [x] confirm in scripts (replaced by immediate execution)
- [x] math operators
- [x] comparison operators
- [x] Flow control: loops (with 'give'), conditions (with 'when')
- [x] commands have no side effects

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
describe 'myjoin "Join strings by separator\n\nA longer example: myjoin{sep=}\n\n\nNOTE: this is pretty useless"
args 'myjoin ["separator"]
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
