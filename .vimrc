 set nocompatible               " be iMproved
 set hlsearch

" Some Linux distributions set filetype in /etc/vimrc.
" Clear filetype flags before changing runtimepath to force Vim to reload them.
filetype off
filetype plugin indent off
set runtimepath+=$GOROOT/misc/vim
filetype plugin indent on
syntax on

 set rtp+=~/.vim/bundle/vundle/
 call vundle#rc()

 execute pathogen#infect()

 " let Vundle manage Vundle
 " required! 
 Bundle 'gmarik/vundle'

 " My Bundles here:
 "
 " original repos on github
 Bundle 'tpope/vim-fugitive'
 Bundle 'Lokaltog/vim-easymotion'
 Bundle 'rstacruz/sparkup', {'rtp': 'vim/'}
 Bundle 'tpope/vim-rails.git'
 " vim-scripts repos
 Bundle 'L9'
 " non github repos
 Bundle 'git://git.wincent.com/command-t.git'
 "
 Bundle 'Valloric/YouCompleteMe'
 Bundle 'altercation/vim-colors-solarized'
 let g:syntastic_cpp_checkers=['ycm', 'gcc']
 let g:syntastic_c_checkers=['ycm', 'gcc', 'make']
 let g:syntastic_cpp_check_header = 1
 Bundle 'scrooloose/syntastic'

 Bundle 'guns/vim-clojure-static'
 Bundle 'kien/rainbow_parentheses.vim'
 Bundle 'vim-scripts/paredit.vim'
 Bundle 'tpope/vim-fireplace'

 so ~/.vim/plugins/autoclose.vim


 filetype plugin indent on     " required!
 "
 " Brief help
 " :BundleList          - list configured bundles
 " :BundleInstall(!)    - install(update) bundles
 " :BundleSearch(!) foo - search(or refresh cache first) for foo
 " :BundleClean(!)      - confirm(or auto-approve) removal of unused bundles
 "
 " see :h vundle for more details or wiki for FAQ
 " NOTE: comments after Bundle command are not allowed..

 " set UTF-8 encoding
 set enc=utf-8
 set fenc=utf-8
 set termencoding=utf-8
 " disable vi compatibility (emulation of old bugs)
 set nocompatible
 " use indentation of previous line
 set autoindent
 " use intelligent indentation for C
 set smartindent
 " configure tabwidth and insert spaces instead of tabs
 set tabstop=4        " tab width is 4 spaces
 set shiftwidth=4     " indent also with 4 spaces
 set expandtab        " expand tabs to spaces
 " turn syntax highlighting on
 set t_Co=256
 " turn line numbers on
 set number
 " highlight matching braces
 set showmatch
 " intelligent comments
 set comments=sl:/*,mb:\ *,elx:\ */  

 " Install OmniCppComplete like described on http://vim.wikia.com/wiki/C++_code_completion
 " This offers intelligent C++ completion when typing ‘.’ ‘->’ or <C-o>
 " Load standard tag files
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
 " recreate tags file with F5
 map <F5> :!ctags -R –c++-kinds=+p –fields=+iaS –extra=+q .<CR>

 map <F6> :Compilec<CR>:!./a.out<CR>

 map <F7> :Compilec<CR>:!gdb a.out<CR>

 set langmap=hk,jh,kj

 imap jj <Esc>
 
 nnoremap <C-e> :Eval<CR>
 nnoremap E :%Eval <CR>

 "Yank text to the OSX clipboard
 noremap <leader>y "*y
 noremap <leader>yy "*Y
 "Preserve indentation when pasting from clipboard.
 noremap <leader>p :set paste<CR>:put *<CR>:set nopaste<CR>


 command! Compilec !clang++ -g *.cpp

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
