EIGHTHEADER
===========
Easily create custom (fold)headers, foldtext, toc, etc.

To use EightHeader just move the cursor to the line which you want to modify (hereinafter `line`), then call it:
```
EightHeader( length, align, oneline, pattern, marker, str )

length   Length of the header.
align    Alignment of text.
oneline  line and marker in one line, pattern in another.
pattern  Pattern to fill with.
marker   Extra content after patternRightEnd.
str      Replace the content of line with this.
```

An example with `oneline`:
```
call EightHeader( 78, "center", 1, ["l ", "pat", " r"], " m", "\\=' '.s:str.' '" )

l patpatpatpatpatpatpatpat TEXT IN THE LINE patpatpatpatpatpatpatpat r m
```
... and whitout it:
```
call EightHeader( 78, "center", 0, ["l ", "pat", " r"], " m", "" )

                              TEXT IN THE LINE                         m
l patpatpatpatpatpatpatpatpatpatpatpatpatpatpatpatpatpatpatpatpatpatpa r
```

If you don't like the default 'foldtext' you can customize it by setting to
`EightHeaderFolds()`.

For example the closed folds looks like this by default:
```
+-- 45 lines: Fold level one
+--- 67 lines: Fold level two
```
If you would like to change it to this kind:
```
Fold level one................45 lines
  Fold level two..............67 lines
```
... then you can use this function:
```
let &foldtext = "EightHeaderFolds( '\\=s:fullwidth-2', 'left', [ repeat( '  ', v:foldlevel - 1 ), '.', '' ], '\\= s:foldlines . \" lines\"', '' )"
```
An alternative usage for example formating a vimhelp table of contents:
```
Options;options
Default mappings;maps
  Launch nuclear strike;apocalypse
```
... to this:
```
Options........................................................|options|
Default mappings..................................................|maps|
  Launch nuclear strike.....................................|apocalypse|
```
Visually select the lines, than:
```
call EightHeader( 78, "left", 1, ".", "\\='|'.matchstr(s:str, ';\\@<=.*').'|'", "\\=matchstr(s:str, '.*;\\@=')" )
```
