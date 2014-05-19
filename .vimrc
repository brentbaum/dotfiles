set nocompatible               " be iMproved
set backspace=indent,eol,start

" Spacing
set autoindent
set autowrite
set smartindent
set smarttab
set tabstop=4        " tab width is 4 spaces
set shiftwidth=4     " indent also with 4 spaces
set expandtab        " expand tabs to spaces

" Display
set cul
set t_Co=256
set number
set showmatch
set comments=sl:/*,mb:\ *,elx:\ */  
set textwidth=0
set visualbell
set wildmenu

" Search 
set incsearch
set ignorecase
set hlsearch
set ignorecase

"Status Line
set ruler
set showcmd

" No swaps :)
set nobackup
set nowb
set noswapfile

" Autosave when switching buffers
"set autowrite

"Leader
let mapleader = ","

"Temptation
"set mouse=a

"Golang config
filetype off
filetype plugin indent off
set runtimepath+=$GOROOT/misc/vim
filetype plugin indent on
syntax on

"execute pathogen#infect()


set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

Bundle 'gmarik/vundle'
Bundle 'wincent/Command-T'
Bundle 'scrooloose/nerdcommenter'
Bundle 'tpope/vim-fugitive'
Bundle 'Lokaltog/vim-easymotion'
Bundle 'rstacruz/sparkup', {'rtp': 'vim/'}
Bundle 'Valloric/YouCompleteMe'
Bundle 'altercation/vim-colors-solarized'
Bundle 'guns/vim-clojure-static'
Bundle 'kien/rainbow_parentheses.vim'
Bundle 'vim-scripts/paredit.vim'
Bundle 'tpope/vim-fireplace'

Bundle 'Townk/vim-autoclose'
let g:syntastic_cpp_checkers=['ycm', 'gcc']
let g:syntastic_c_checkers=['ycm', 'gcc', 'make']
let g:syntastic_cpp_check_header = 1
Bundle 'scrooloose/syntastic'

filetype plugin indent on     " required!

"OmniComplete
set tags+=~/.vim/tags/cpp
set tags+=~/.vim/tags/gl
set tags+=~/.vim/tags/sdl
set tags+=~/.vim/tags/qt4  

" in normal mode F2 will save the file
nmap <F2> :w<CR>
" in insert mode F2 will exit insert, save, enters insert again
imap <F2> <ESC>:w<CR>i
" switch between header/source with F4
map <F4> :e %:p:s,.h$,.X123X,:s,.cpp$,.h,:s,.X123X$,.cpp,<CR>

" Jet pilot navigation map
set langmap=hk,jh,kj

"Clojure eval
nnoremap <C-e> :Eval<CR>
nnoremap E :%Eval <CR>

nnoremap ; :
nnoremap : ;

"Map Command-T plugin to ,t
nnoremap <leader>t :CommandT 

"Preserve indentation when pasting from clipboard.
noremap <leader>p :set paste<CR>:put *<CR>:set nopaste<CR>

" Solarized config
try 
    set background=dark
    colorscheme solarized
catch /E185:/
    colorscheme default
endtry

if exists('g:colors_name') && g:colors_name == 'solarized'
    if has('gui_macvim')
        set transparency=0
    endif

    if !has('gui_running') && $TERM_PROGRAM == 'Apple_Terminal'
        let g:solarized_termcolors = &t_Co
        let g:solarized_termtrans = 1
        colorscheme solarized
        if &background == 'dark'
            hi Visual term=reverse cterm=reverse ctermfg=10 ctermbg=7
        endif
    endif
endif

" Turn off annoying confirmation to use .ycm_extra_conf.py file."
let g:ycm_confirm_extra_conf = 0

let loaded_matchparen = 0
