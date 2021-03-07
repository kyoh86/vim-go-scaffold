" Prepare Golang scaffolding file
function! goscaffold#init()
  let l:bytes = get(wordcount(), 'bytes', 0)
  if l:bytes != 0
    return
  endif

  let l:pkg_name = goscaffold#get_package_name()
  if l:pkg_name ==# ''
    return
  endif

  let l:scaffold = ['package ' .. l:pkg_name]

  if l:pkg_name =~# '_test$'
    try
      let l:pkglist = systemlist('go list ./' .. expand('%:h'))
      if v:shell_error == 0
        if len(l:pkglist) > 0
          call extend(l:scaffold, [
                \ '',
                \ 'import (',
                \ "\t" .. '"testing"',
                \ '',
                \ "\t" .. 'testtarget "' .. l:pkglist[0] .. '"',
                \ ')'])
        endif
      endif
    catch
      " noop
    endtry
    call extend(l:scaffold, ['', 'func Test(t *testing.T) {', "\t" .. 'testtarget.', '}'])
    call setline(1, l:scaffold)
    call cursor(len(l:scaffold) - 2, 9)
  else
    call extend(l:scaffold, ['', ''])
    call setline(1, l:scaffold)
    call cursor(3, 1)
  endif
endfunction

" Get package name for the current file path
function! goscaffold#get_package_name()
  let l:filename = expand('%:p')
  if l:filename ==# ''
    return ''
  endif

  let l:basename = fnamemodify(l:filename, ':t')
  if l:basename !~ '\.go$'
    return ''
  endif

  let l:dir = fnamemodify(l:filename, ':h')

  let l:suffix = ''

  " For test file: search simbling *_test.go files and get package name from them
  if l:basename =~ '_test\.go$'
    " TODO: use execute('lvimgrep /^package [a-zA-Z0-9]\+$/j ' .. l:dir .. '/**.go') instead
    let  l:known_pkg = s:match_package_name(glob(l:dir .. '/*_test.go', v:true, v:true))
    if l:known_pkg !=# ''
      return l:known_pkg
    endif
    let l:suffix = '_test'
  endif

  " Search simbling *.go files (not *_test.go) and get package name from them
  let l:wildignore = &wildignore
  set wildignore=*_test.go
  let l:known_pkg = s:match_package_name(glob(l:dir .. '/*.go', v:false, v:true))
  let &wildignore = l:wildignore
  if l:known_pkg !=# ''
    return l:known_pkg .. l:suffix
  endif

  let l:dirname = fnamemodify(l:dir, ':t')

  " If the file is in the l:dir like "main" packagee
  if s:isin_cmd(l:dir) || s:is_invalid_pkg_name(l:dirname)
    return 'main' .. l:suffix
  endif

  return l:dirname .. l:suffix
endfunction

" Search package line from files
function! s:match_package_name(files)
  for l:file in a:files
    for l:line in readfile(l:file, v:null, get(g:, 'go_init_read_package_line_max_length', 10))
      let l:matches = matchlist(l:line, 'package \(.*\)')
      if len(l:matches) > 1
        return l:matches[1]
      endif
    endfor
  endfor
  return ''
endfunction

function! s:is_invalid_pkg_name(pkg_name)
  return match(a:pkg_name, '[^0-9a-zA-Z_]') >= 0
endfunction

" Check if the dir is in the cmd/**
function! s:isin_cmd(dir)
  let l:anc = a:dir
  let l:i = 0
  let l:prev = ''
  while l:i < 5 && l:anc != l:prev
    if fnamemodify(l:anc, ':t') ==# 'cmd'
      return v:true
    endif

    let l:prev = l:anc
    let l:anc = fnamemodify(l:anc, ':h')
    let l:i = l:i + 1
  endwhile
  return v:false
endfunction
