set encoding=utf-8


" ================ Vundle Plugins ====================

set nocompatible " Be IMproved

filetype off " Required by Vundle
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

" Themes
Plugin 'morhetz/gruvbox'
Plugin 'chriskempson/base16-vim'

" Airline
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'

" Markdown
"Plugin 'JamshedVesuna/vim-markdown-preview' 

call vundle#end()


" ================ General Config ====================

syntax on                       " Enable syntax highlighting
filetype plugin indent on       " Sets indent mode based on filetype
syntax enable
set background=dark
"colorscheme base16-materia
highlight LineNr ctermfg=darkgrey ctermbg=black

set clipboard=unnamed           " Share OS clipboard
set encoding=utf-8              " default character encoding
set hidden                      " do not unload buffers that get hidden

set wrap                        " Wrap lines visually
set number                      " Show line numbers
set relativenumber              " Show relative line numbers
set scrolloff=3                 " Start scrolling when we're 3 lines away from margins

set showcmd                     " Show the (partial) command as it’s being typed
set wildmenu                    " Enhance command-line completion

set autoindent                  " Indent automatically
set cindent                     " Syntax aware auto-indent
set backspace=indent,eol,start  " Set backspace to work for all characters

set expandtab                   " Turn tabs into spaces
set smarttab                    " <BS> deletes a shiftwidth worth of space
set tabstop=4                   " 2 spaces for each tab in file
set softtabstop=4               " 2 spaces for pressing tab key
set shiftwidth=4                " 2 spaces for indentation

set mouse=a                     " Allow mouse usage in terminal

set hlsearch                    " Highlight searches
set incsearch                   " Highlight matches while typing search
set showmatch                   " Move the cursor to the matching pair of (){}[]

" set the search scan so that it ignores case when the search is all lower
" case but recognizes uppercase if it's specified
set ignorecase
set smartcase

" Do not create swap files
set nobackup
set nowritebackup
set noswapfile

" When 'Search next' reaches the end of the file, it wraps around the beginning
set wrapscan

" Ignore certain things
set wildignore+=output,dist,bower_components,build,.git,node_modules,_book

" Get off my lawn
nnoremap <Left> :echoe "Use h"<CR>
nnoremap <Right> :echoe "Use l"<CR>
nnoremap <Up> :echoe "Use k"<CR>
nnoremap <Down> :echoe "Use j"<CR>

" Don't care about accidental capitalisation
cnoreabbrev W w
cnoreabbrev Q q
cnoreabbrev Wq wq
cnoreabbrev WQ wq

" ================ Plugin Config ====================

"vim-markdown-preview
"let vim_markdown_preview_github=1
