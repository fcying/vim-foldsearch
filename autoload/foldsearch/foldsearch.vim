" Name:    foldsearch.vim
" Version: 1.1.0
" Author:  Markus Braun <markus.braun@krawel.de>
" Summary: Vim plugin to fold away lines that don't match a pattern
" Licence: This program is free software: you can redistribute it and/or modify
"          it under the terms of the GNU General Public License as published by
"          the Free Software Foundation, either version 3 of the License, or
"          (at your option) any later version.
"
"          This program is distributed in the hope that it will be useful,
"          but WITHOUT ANY WARRANTY; without even the implied warranty of
"          MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"          GNU General Public License for more details.
"
"          You should have received a copy of the GNU General Public License
"          along with this program.  If not, see <http://www.gnu.org/licenses/>.
"
" Section: Functions {{{1

" Function: foldsearch#foldsearch#FoldCword(...) {{{2
"
" Search and fold the word under the cursor. Accept a optional context argument.
"
function! foldsearch#foldsearch#FoldCword(...)
  " define the search pattern
  let b:foldsearch_pattern = '\<'.expand("<cword>").'\>'

  " determine the number of context lines
  if (a:0 ==  0)
    call foldsearch#foldsearch#FoldSearchDo()
  elseif (a:0 == 1)
    call foldsearch#foldsearch#FoldSearchContext(a:1)
  elseif (a:0 == 2)
    call foldsearch#foldsearch#FoldSearchContext(a:1, a:2)
  endif

endfunction

" Function: foldsearch#foldsearch#FoldSearch(...) {{{2
"
" Search and fold the last search pattern. Accept a optional context argument.
"
function! foldsearch#foldsearch#FoldSearch(...)
  " define the search pattern
  let b:foldsearch_pattern = @/

  " determine the number of context lines
  if (a:0 == 0)
    call foldsearch#foldsearch#FoldSearchDo()
  elseif (a:0 == 1)
    call foldsearch#foldsearch#FoldSearchContext(a:1)
  elseif (a:0 == 2)
    call foldsearch#foldsearch#FoldSearchContext(a:1, a:2)
  endif

endfunction

" Function: foldsearch#foldsearch#FoldPattern(pattern) {{{2
"
" Search and fold the given regular expression.
"
function! foldsearch#foldsearch#FoldPattern(pattern)
  " define the search pattern
  let b:foldsearch_pattern = a:pattern

  " call the folding function
  call foldsearch#foldsearch#FoldSearchDo()
endfunction

" Function: foldsearch#foldsearch#FoldSpell(...)  {{{2
"
" do the search and folding based on spellchecker
"
function! foldsearch#foldsearch#FoldSpell(...)
  " if foldsearch_pattern is not defined, then exit
  if (!&spell)
    echo "Spell checking not enabled, ending Foldsearch"
    return
  endif

  let b:foldsearch_pattern = ''

  " do the search (only search for the first spelling error in line)
  let lnum = 1
  while lnum <= line("$")
    let bad_word = spellbadword(getline(lnum))[0]
    if bad_word != ''
      if empty(b:foldsearch_pattern)
        let b:foldsearch_pattern = '\<\(' . bad_word
      else
        let b:foldsearch_pattern = b:foldsearch_pattern . '\|' . bad_word
      endif
    endif
    let lnum = lnum + 1
  endwhile

  let b:foldsearch_pattern = b:foldsearch_pattern . '\)\>'

  " report if pattern not found and thus no fold created
  if (empty(b:foldsearch_pattern))
    echo "No spelling errors found!"
  else
    " determine the number of context lines
    if (a:0 == 0)
      call foldsearch#foldsearch#FoldSearchDo()
    elseif (a:0 == 1)
      call foldsearch#foldsearch#FoldSearchContext(a:1)
    elseif (a:0 == 2)
      call foldsearch#foldsearch#FoldSearchContext(a:1, a:2)
    endif
  endif

endfunction

" Function: foldsearch#foldsearch#FoldLast(...) {{{2
"
" Search and fold the last pattern
"
function! foldsearch#foldsearch#FoldLast()
  if (!exists("b:foldsearch_context_pre") || !exists("b:foldsearch_context_post") || !exists("b:foldsearch_pattern"))
    return
  endif

  " call the folding function
  call foldsearch#foldsearch#FoldSearchDo()
endfunction

" Function: foldsearch#foldsearch#FoldSearchContext(context) {{{2
"
" Set the context of the folds to the given value
"
function! foldsearch#foldsearch#FoldSearchContext(...)
  " force context to be defined
  if (!exists("b:foldsearch_context_pre"))
    let b:foldsearch_context_pre = 0
  endif
  if (!exists("b:foldsearch_context_post"))
    let b:foldsearch_context_post = 0
  endif

  if (a:0 == 0)
    " if no new context is given display current and exit
    echo "Foldsearch context: pre=".b:foldsearch_context_pre." post=".b:foldsearch_context_post
    return
  else
    let number=1
    let b:foldsearch_context_pre = 0
    let b:foldsearch_context_post = 0
    while number <= a:0
      execute "let argument = a:" . number . ""
      if (strpart(argument, 0, 1) == "-")
	let b:foldsearch_context_pre = strpart(argument, 1)
      elseif (strpart(argument, 0, 1) == "+")
	let b:foldsearch_context_post = strpart(argument, 1)
      else
	let b:foldsearch_context_pre = argument
	let b:foldsearch_context_post = argument
      endif
      let number = number + 1
    endwhile
  endif

  if (b:foldsearch_context_pre < 0)
    let b:foldsearch_context_pre = 0
  endif
  if (b:foldsearch_context_post < 0)
    let b:foldsearch_context_post = 0
  endif

  " call the folding function
  call foldsearch#foldsearch#FoldSearchDo()
endfunction

" Function: foldsearch#foldsearch#FoldContextAdd(change) {{{2
"
" Change the context of the folds by the given value.
"
function! foldsearch#foldsearch#FoldContextAdd(change)
  " force context to be defined
  if (!exists("b:foldsearch_context_pre"))
    let b:foldsearch_context_pre = 0
  endif
  if (!exists("b:foldsearch_context_post"))
    let b:foldsearch_context_post = 0
  endif

  let b:foldsearch_context_pre = b:foldsearch_context_pre + a:change
  let b:foldsearch_context_post = b:foldsearch_context_post + a:change

  if (b:foldsearch_context_pre < 0)
    let b:foldsearch_context_pre = 0
  endif
  if (b:foldsearch_context_post < 0)
    let b:foldsearch_context_post = 0
  endif

  " call the folding function
  call foldsearch#foldsearch#FoldSearchDo()
endfunction

" Function: foldsearch#foldsearch#FoldSearchInit() {{{2
"
" initialize fold searching for current buffer
"
function! foldsearch#foldsearch#FoldSearchInit()
  " force context to be defined
  if (!exists("b:foldsearch_context_pre"))
    let b:foldsearch_context_pre = 0
  endif
  if (!exists("b:foldsearch_context_post"))
    let b:foldsearch_context_post = 0
  endif
  if (!exists("b:foldsearch_foldsave"))
    let b:foldsearch_foldsave = 0
  endif

  " save state if needed
  if (b:foldsearch_foldsave == 0)
    let b:foldsearch_foldsave = 1

    " make a view of the current file for later restore of manual folds
    let b:foldsearch_viewoptions = &viewoptions
    let &viewoptions = "folds,options"
    let b:foldsearch_viewfile = tempname()
    execute "mkview " . b:foldsearch_viewfile
    " For unnamed buffers, an 'enew' command gets added to the view which we
    " need to filter out.
    let l:lines = readfile(b:foldsearch_viewfile)
    call filter(l:lines, 'v:val != "enew"')
    call writefile(l:lines, b:foldsearch_viewfile)
  endif

  let &foldtext = ""
  let &foldmethod = "manual"
  let &foldenable = 1
  let &foldminlines = 0

  " erase all folds to begin with
  normal zE
endfunction

" Function: foldsearch#foldsearch#FoldSearchDo()  {{{2
"
" do the search and folding based on b:foldsearch_pattern and
" b:foldsearch_context
"
function! foldsearch#foldsearch#FoldSearchDo()
  " if foldsearch_pattern is not defined, then exit
  if (!exists("b:foldsearch_pattern"))
    echo "No search pattern defined, ending fold search"
    return
  endif

  " initialize fold search for this buffer
  call foldsearch#foldsearch#FoldSearchInit()

  " highlight search pattern if requested
  if (g:foldsearch_highlight == 1)
    if (exists("b:foldsearch_highlight_id"))
      matchdelete(b:foldsearch_highlight_id)
    endif
    let b:foldsearch_highlight_id = matchadd("Search", b:foldsearch_pattern)
  endif

  " save cursor position
  let cursor_position = line(".") . "normal!" . virtcol(".") . "|"

  " move to the end of the file
  normal $G$
  let pattern_found = 0      " flag to set when search pattern found
  let fold_created = 0       " flag to set when a fold is found
  let flags = "w"            " allow wrapping in the search
  let line_fold_start =  0   " set marker for beginning of fold

  " do the search
  while search(b:foldsearch_pattern, flags) > 0
    " patern had been found
    let pattern_found = 1

    " determine end of fold
    let line_fold_end = line(".") - 1 - b:foldsearch_context_pre

    " validate line of fold end and set fold
    if (line_fold_end >= line_fold_start && line_fold_end != 0)
      " create fold
      execute ":" . line_fold_start . "," . line_fold_end . " fold"

      " at least one fold has been found
      let fold_created = 1
    endif

    " jump to the end of this match. needed for multiline searches
    call search(b:foldsearch_pattern, flags . "ce")

    " update marker
    let line_fold_start = line(".") + 1 + b:foldsearch_context_post

    " turn off wrapping
    let flags = "W"
  endwhile

  " now create the last fold which goes to the end of the file.
  normal $G
  let  line_fold_end = line(".")
  if (line_fold_end  >= line_fold_start && pattern_found == 1)
    execute ":". line_fold_start . "," . line_fold_end . "fold"
  endif

  " report if pattern not found and thus no fold created
  if (pattern_found == 0)
    echo "Pattern not found!"
  elseif (fold_created == 0)
    echo "No folds created"
  else
    echo "Foldsearch done"
  endif

  " restore position before folding
  execute cursor_position

  " make this position the vertical center
  normal zz

endfunction

" Function: foldsearch#foldsearch#FoldSearchEnd() {{{2
"
" End the fold search and restore the saved settings
"
function! foldsearch#foldsearch#FoldSearchEnd()
  " save cursor position
  let cursor_position = line(".") . "normal!" . virtcol(".") . "|"

  if (!exists('b:foldsearch_foldsave'))
    let b:foldsearch_foldsave = 0
  endif
  if (b:foldsearch_foldsave == 1)
    let b:foldsearch_foldsave = 0

    " restore the folds before foldsearch
    execute "silent! source " . b:foldsearch_viewfile
    call delete(b:foldsearch_viewfile)
    let &viewoptions = b:foldsearch_viewoptions

  endif

  " delete highlighting
  if (exists("b:foldsearch_highlight_id"))
    call matchdelete(b:foldsearch_highlight_id)
    unlet b:foldsearch_highlight_id
  endif

  " give a message to the user
  echo "Foldsearch ended"

  " open all folds for the current cursor position
  silent! execute "normal " . foldlevel(line(".")) . "zo"

  " restore position before folding
  execute cursor_position

  " make this position the vertical center
  normal zz

endfunction

" Function: foldsearch#foldsearch#FoldSearchDebug(level, text) {{{2
"
" output debug message, if this message has high enough importance
"
function! foldsearch#foldsearch#FoldSearchDebug(level, text)
  if (g:foldsearch_debug >= a:level)
    echom "foldsearch: " . a:text
  endif
endfunction

" vim600: foldmethod=marker foldlevel=1 :