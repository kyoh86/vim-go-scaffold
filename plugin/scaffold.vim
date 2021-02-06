augroup go-scaffold
  autocmd!
  autocmd BufNewFile *.go call go#scaffold#init()
augroup END
