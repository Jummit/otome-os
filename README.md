# OtomeOS 💮

Other possibility:
replace-text (show-file get-files) apple banana

Command Arg1 Arg2 (SubCommand Arg1 Arg2)
Commands can be called to return a stream of any length
Args can be commands that return streams
The result of the root is printed
Commands are basically maps of on stream to another
square brackets [] can be used to convert a list of arguments into a stream:
"new [a b c d]" will create files a b c and d

OS
has repl
has separate command instruction format to perform tasks:
DEL file
INS smth
MOV file
Only read operations can be executed by commands
Output of Commands can be executed using X
X without commands executes the last output
X with command executes that command as system
All operations can be undone. This adds the REV instruction to the history
--
Edit/Debug/Fix cycle:
!write (edit (read 'somefile)) 'somefile
(Editor is now open, when quit a system command is printed to stdout)
x

TODO:
Flow control: loops, conditions
immediate execution, folders
execute a file
functions with parameters

DONE: Tests, Strings, List sugar, Aliases, Error handling

Project inspired by: Bash, ZSH, Exapunks, Blender Geometry Nodes, Lisp/Functional Programming, TIC80.

Commands should execute instantly. Tasks can be scheduled by the OS:

```
IN 5 write log
```
