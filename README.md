# YSON - Data Format
YSON = YvesScriptObjectNotation (until a better name comes into mind)

This is an old data exchange format I wrote for games based on Flash ActionScript 3.
The idea was to provide an easy and forgivable way to define simple or nestedconfiguration data within text files.
With the possibility to comment out data easily. And to add comments if needed anywhere.
Perfectly fit for a development phase. Later on, I added table parsing support.
XML and JSON were neither nice, convenient nor capable enough.
So, I came up with this.

## Core features
- Implicit delimiters
- Comments are allowed - line comments ("//") or block comments ("/* ... */")
- Table parsing support
- Comes with parser and writer
