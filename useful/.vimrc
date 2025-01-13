set nocompatible              " required
filetype off                  " required
filetype indent on


" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
 Plugin 'VundleVim/Vundle.vim'

" add all your plugins here (note older versions of Vundle
" used Bundle instead of Plugin)

Plugin 'vim-scripts/indentpython.vim'
" dont really need this Bundle 'Valloric/YouCompleteMe'
Plugin 'morhetz/gruvbox'
Plugin 'vim-python/python-syntax'
Plugin 'vim-syntastic/syntastic'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

" Custom rules"
set tabstop=2
set shiftwidth=2


" Enable folding
set foldmethod=indent
set foldlevel=99
" Make space be the key for folding code
nnoremap <space> za

" Add line numbers
set nu
" Enable vim clipboad (like using <"*yy>)
set clipboard=unnamed
" python identation
au BufNewFile,BufRead *.py
    \ set tabstop=4 |
    \ set softtabstop=4 |
    \ set shiftwidth=4 |
    \ set expandtab |
    \ set autoindent |
    \ set fileformat=unix
" auto_complete close after completion
let g:ycm_autoclose_preview_window_after_completion=1
" goto definition by pressing '\g'
 map <leader>g :YcmCompleter GoToDefinitionElseDeclaration<CR>
let python_highlight_all=1

" setting this causes it to fail, maybe since the actual is just libpython3.11.so.1.0
"set pythonthreedll="/usr/lib/libpython3.11.so"
set pythonthreehome="/usr/lib/python3.11"
"
let g:ycm_python_binary_path="$(which python3)"
let g:pymode_python = 'python3'  
" probably works better with ['pyflakes', 'pycodestyle'] since flake8 removed
" global config in 4.0.0. Also the config file is ~/.config/pycodestyle
let g:syntastic_python_checkers=["pyflakes", "pycodestyle", "python3"]

syntax on
set background=dark
colorscheme gruvbox
hi Normal ctermbg=none
let g:zenburn_alternate_Visual=1

let &t_SI .= "\<Esc>[?2004h"
let &t_EI .= "\<Esc>[?2004l"

inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()

nnoremap o o<Esc>k
nnoremap O O<Esc>
set backspace=indent,eol,start
" avoid entering ex mode when in dvorak keyboard
nnoremap Q <nop>

function! XTermPasteBegin()
  set pastetoggle=<Esc>[201~
  set paste
  return ""
endfunction
