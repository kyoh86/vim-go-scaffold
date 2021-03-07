augroup goscaffold
  autocmd!
  autocmd BufNewFile *.go call goscaffold#init()
augroup END
