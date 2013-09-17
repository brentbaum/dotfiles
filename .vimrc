 set nocompatible               " be iMproved
 set hlsearch
 filetype off                  " required!

" Some Linux distributions set filetype in /etc/vimrc.
" Clear filetype flags before changing runtimepath to force Vim to reload them.
filetype plugin indent off
set runtimepath+=$GOROOT/misc/vim
filetype plugin indent on

 so ~/.vim/plugins/autoclose.vim

 set rtp+=~/.vim/bundle/vundle/
 call vundle#rc()

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
 " git repos on your local machine (ie. when working on your own plugin)
 Bundle 'Valloric/YouCompleteMe'
 Bundle 'altercation/vim-colors-solarized'

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
 syntax on
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

 imap jj <Esc>
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
