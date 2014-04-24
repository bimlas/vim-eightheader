" eightheader.vim

"                             SCRIPT FUNCTIONS                            {{{1
" ============================================================================

"                                 ISTYPE                                  {{{2
" ____________________________________________________________________________
"
" Returns true if the {var} is type of something.

function! s:IsNumber( var )
  return type( a:var ) == 0
endfunction

function! s:IsString( var )
  return type( a:var ) == 1
endfunction

function! s:IsList( var )
  return type( a:var ) == 3
endfunction

"                                  ERROR                                  {{{2
" ____________________________________________________________________________
"
" Echoing the error message.

function! s:Error( msg )
  echohl ErrorMsg | echomsg a:msg | echohl None
endfunction

"                                  VALUE                                  {{{2
" ____________________________________________________________________________
"
" Returns the (evaulated) value of {var}.

function! s:Value( var )
  if s:IsString( a:var ) && (a:var =~ '^\\=')
    return eval( matchstr( a:var, '\(\\=\)\@<=.*' ) )
  else
    return a:var
  endif
endfunction

"                                 PATTERN                                 {{{2
" ____________________________________________________________________________
"
" Repeating a pattern, then returns with it.
"
" __ ARGUMENTS __________________________
"
"   start     Number  Index of first character in pattern.
"   len       Number  Length of generated pattern.
"   pattern   String  Pattern that we want to repeat.
"
" FIXME:
"   strpart() not works with multibyte characters.

function! s:Pattern( start, len, pattern )

  if ! a:len
    return ''
  endif

  let retstr     = ''
  let len        = a:len
  let patternLen = strdisplaywidth( a:pattern )

  let index  = a:start % patternLen

  if patternLen >= (len + index)
    return strpart( a:pattern, index, len )
  else
    let retstr .= strpart( a:pattern, index, patternLen - index )
    let len    -= patternLen - index
  endif

  let retstr .= repeat( a:pattern, len / patternLen )

  if len % patternLen
    let retstr .= strpart( a:pattern, 0, len % patternLen )
  endif

  return retstr

endfunction

"                                READARGS                                 {{{2
" ____________________________________________________________________________
"
" Checking for invalid arguments, evaulating values and returns with the
" Dictionary of them or '' on error.
"
" __ ARGUMENTS __________________________
"
"   line          String    The line that have to be formated.
"
"   The others are the same as for EightHeader().
"
" __ RETURN _____________________________
"
"   s:str         String    Blank-striped string that you want to decorate.
"   s:indent      String    Indent before s:str.
"   s:strLen      Number    Displaywidth of s:str.
"   s:indentLen   Number    Displaywidth of s:indent.
"

function! s:ReadArgs( line, length, align, pattern, marker, str )

  let args = {}

  " Evaulating values.

  let s:indent       = matchstr( a:line, '^[[:blank:]]*' )
  let s:indentLen    = strdisplaywidth( s:indent )
  let s:str          = substitute( a:line, '^[[:blank:]]\+\|[[:blank]]\+$', '', 'g' )
  let s:strLen       = strdisplaywidth( s:str )

  let args['length'] = s:Value( a:length )
  let args['align']  = s:Value( a:align )
  let args['marker'] = s:Value( a:marker )

  " Checking for errors.

  if ! s:IsNumber( args['length'] )
    call s:Error( '{length} have to be number: ' . string( a:length ) )
    return ''
  endif

  if a:align !~ '^\(left\|center\|right\)$'
    call s:Error( '{align} have to be "left", "right" or "center": ' . string( a:align ) )
    return ''
  endif

  if ! ((s:IsList( a:pattern ) && (len( a:pattern ) == 3)) || s:IsString( a:pattern ))
    call s:Error( '{pattern} have to be string or list with 3 items: ' . string( a:pattern ) )
    return ''
  endif

  " Evaulating pattern and str.

  if s:IsList( a:pattern )
    let args['patternLeftEnd']  = s:Value( a:pattern[0] )
    let args['pattern']         = s:Value( a:pattern[1] )
    let args['patternRightEnd'] = s:Value( a:pattern[2] )
  else
    let args['patternLeftEnd']  = ''
    let args['pattern']         = s:Value( a:pattern )
    let args['patternRightEnd'] = ''
  endif

  if len( a:str )
    let s:str    = s:Value( a:str )
    let s:strLen = strdisplaywidth( s:str )
  endif

  return args

endfunction

"                                 HEADER                                  {{{2
" ____________________________________________________________________________
"
" The main function: formats the uncommented s:str and returns with it.
" The {args} is a ditionary returned by s:ReadArgs().

function! s:Header( args )

  " Preparing.

  let length = a:args['length']
  if length >= 0
    let length -= s:indentLen
  else
    let length = abs( length )
  endif

  let length -= s:strLen

  let length -= strdisplaywidth( a:args['patternLeftEnd'] . a:args['patternRightEnd'] )

  if len( a:args['marker'] )
    let length -= strdisplaywidth( a:args['marker'] )
  endif

  if     a:args['align'] == 'left'
    let patternLeftLen  = 0
    let patternRightLen = length
  elseif a:args['align'] == 'right'
    let patternLeftLen  = length
    let patternRightLen = 0
  elseif a:args['align'] == 'center'
    let patternLeftLen  = length / 2
    let patternRightLen = length / 2 + length % 2
  endif

  " Main work.

  let retstr  = s:indent
  let retstr .= a:args['patternLeftEnd']

  let retstr .= s:Pattern( 0, patternLeftLen, a:args['pattern'] )

  if len( s:str )
    let retstr .= s:str
  endif

  let retstr .= s:Pattern( patternLeftLen + s:strLen , patternRightLen, a:args['pattern'] )

  let retstr .= a:args['patternRightEnd']
  let retstr .= a:args['marker']

  " Remove the trailing spaces. (for example if the pattern is ' ' and no
  " marker set)
  "
  " FIXME:
  "   Sometimes it's a bad idea, for example if you want to align to center:
  "   /* stg */ -> /*               stg */

  return substitute( retstr, '[[:blank:]]\+$', '', '' )

endfunction

"                               EIGHTHEADER                               {{{1
" ============================================================================
"
" Creates a (commented) header.
"
" __ ARGUMENTS __________________________
"
"   length    Value   Length of the header.
"   align     Value   Alignment of text.
"   oneline   Number  {line} and {marker} in one line, {pattern} in another.
"   pattern   Value   Pattern to fill with.
"   marker    Value   Extra content after patternRightEnd.
"   str       Value   Replace the content of {line} with this.
"
" FIXME:
"   Check errors before uncommenting.

function! EightHeader( length, align, oneline, pattern, marker, str )

  " Preparing.

  let firstLine   = line( '.' )
  let lastLine    = firstLine
  let line        = getline( '.' )

  " Uncommenting.

  let commentLen = 0
  if exists( 'g:EightHeader_uncomment' ) && exists( 'g:EightHeader_comment' )
    execute g:EightHeader_uncomment
    let lineUncommented = getline( '.' )
    let commentLen = strdisplaywidth( line ) - strdisplaywidth( lineUncommented )
    if commentLen
      let line = lineUncommented
    endif
  endif

  " Evaulating arguments.

  let args = s:ReadArgs( line, a:length, a:align, a:pattern, a:marker, a:str )
  if ! len( args )
    return -1
  endif

  let args['length'] -= (args['length'] < 0) ? 0 : commentLen

  " Doing main stuff.

  if a:oneline
    call setline( '.', s:Header( args ) )
  else
    call setline( '.', s:Header( s:ReadArgs( line,     args['length'], a:align, ' ',       a:marker, a:str ) ) )
    call append(  '.', s:Header( s:ReadArgs( s:indent, args['length'], a:align, a:pattern, '',       ''    ) ) )
    let lastLine += 1
  endif

  " Commenting again if necessary. Puting an 'X' after the indenting to align
  " the comment operators to the left.

  silent! foldopen!

  if commentLen
    silent execute firstLine . ',' . lastLine . ' call setline( ".", substitute( getline( "." ), "^' . s:indent . '", "&X", "" ) )'
    execute        firstLine . ',' . lastLine . ' ' . g:EightHeader_comment
    silent execute firstLine . ',' . lastLine . ' call setline( ".", substitute( getline( "." ), "^\\([^X]\\+\\)X", "\\=submatch( 1 )", "" ) )'
  endif

endfunction

"                             EIGHTHEADERFOLDS                            {{{1
" ============================================================================
"
" Returning whith the modified foldheader.

function! EightHeaderFolds( length, align, pattern, marker, str )

  let s:fullwidth = winwidth( 0 ) - (&number ? &numberwidth : 0) - &foldcolumn
  let s:foldlines = v:foldend - v:foldstart + 1

  " Geting the text of foldheader from the original foldtext().

  let args = s:ReadArgs( substitute( foldtext(), '^.\{-}: \|[[:blank:]]\+$', '', 'g' ), a:length, a:align, a:pattern, a:marker, a:str )
  if ! len( args )
    return -1
  endif

  return s:Header( args )

endfunction
"                             EIGHTHEADERCALL                             {{{1
" ============================================================================
"
" Returning whith the modified {line} or -1 if there was an error. Does not
" commenting! See EightHeader() for arguments.

function! EightHeaderCall( line, length, align, pattern, marker, str )

  let args = s:ReadArgs( a:line, a:length, a:align, a:pattern, a:marker, a:str )
  if ! len( args )
    return -1
  endif

  return s:Header( args )

endfunction
