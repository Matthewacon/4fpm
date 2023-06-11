set tabstop=1
set shiftwidth=1
set softtabstop=1
set expandtab
set nosmarttab

set textwidth=80

"Default make command
set makeprg=rm\ -r\ build;\ mkdir\ -p\ build;\ cd\ build;\ env\ CC=clang\ CXX=clang++\ cmake\ ..\ -GNinja;\ ninja\ -j\$((`nproc`\ *\ 2))

function Build()
 redir @">
 make
 redir END
 enew
 execute 'file '. "Build ". strftime('%c')
 put
 setlocal buftype=nofile
 setlocal bufhidden=hide
 setlocal noswapfile
 setlocal readonly
 redraw
endfunction
nnoremap <C-j> :call Build() <CR>
